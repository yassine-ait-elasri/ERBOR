#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# OSPF Convergence Test (Clean Output + Ping Logging)
# - Starts continuous ping from Client A to TARGET
# - Fails a specific link (container:iface)
# - Restores the link
# - Reports packet loss + estimated convergence window
# ============================================================

# ----------------------------
# Config (edit if needed)
# ----------------------------
CLIENT_CONT="clab-nexsus-lab-client-a"
TARGET_IP="10.0.3.2"

FAIL_CONT="clab-nexsus-lab-dist01"
FAIL_IF="eth5"

# How long to keep the link down (seconds)
DOWN_SLEEP=5

# Ping interval inside the client container (seconds)
PING_INTERVAL="0.2"

# Log location on the host
PING_LOG="/tmp/ospf_convergence_ping_${TARGET_IP//./_}.log"

# ----------------------------
# Helpers
# ----------------------------
ts() { date +"%H:%M:%S.%N"; }

die() {
  echo "[X] $*" >&2
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

docker_container_exists() {
  docker inspect "$1" >/dev/null 2>&1
}

iface_exists_in_container() {
  docker exec "$1" sh -c "ip link show '$2' >/dev/null 2>&1"
}

cleanup() {
  # stop ping if still running
  if [[ -n "${PING_PID:-}" ]] && kill -0 "$PING_PID" >/dev/null 2>&1; then
    kill "$PING_PID" >/dev/null 2>&1 || true
    wait "$PING_PID" >/dev/null 2>&1 || true
  fi

  # try to restore link (best-effort)
  docker exec "$FAIL_CONT" sh -c "ip link set '$FAIL_IF' up" >/dev/null 2>&1 || true
}
trap cleanup EXIT

# ----------------------------
# Pre-flight checks
# ----------------------------
need_cmd docker
need_cmd awk
need_cmd grep
need_cmd tail
need_cmd sed
need_cmd date

docker_container_exists "$CLIENT_CONT" || die "Container not found: $CLIENT_CONT"
docker_container_exists "$FAIL_CONT"   || die "Container not found: $FAIL_CONT"

iface_exists_in_container "$FAIL_CONT" "$FAIL_IF" || die "Interface $FAIL_IF not found in $FAIL_CONT"

# ----------------------------
# Header
# ----------------------------
echo "============================================================"
echo "Starting OSPF convergence test"
echo "Target IP        : $TARGET_IP"
echo "Failing interface: ${FAIL_CONT}:${FAIL_IF}"
echo "Ping interval    : ${PING_INTERVAL}s"
echo "Downtime         : ${DOWN_SLEEP}s"
echo "Ping log         : $PING_LOG"
echo "============================================================"
echo

# ----------------------------
# Start ping (logged, no TTY)
# ----------------------------
echo "[*] Starting continuous ping from $CLIENT_CONT to $TARGET_IP (logging to $PING_LOG)"
: > "$PING_LOG"

# Run ping inside container, log on host, in background
# NOTE: no -it here -> avoids "input device is not a TTY"
docker exec "$CLIENT_CONT" sh -c "ping -i '$PING_INTERVAL' '$TARGET_IP'" >"$PING_LOG" 2>&1 &
PING_PID=$!

# Give ping a moment to start
sleep 1

# Quick sanity: ensure ping is producing output
if ! kill -0 "$PING_PID" >/dev/null 2>&1; then
  echo "[X] Ping process died. First lines of log:"
  head -n 20 "$PING_LOG" || true
  exit 1
fi

echo "[+] Ping running (pid=$PING_PID)"
echo

# ----------------------------
# Fail the link
# ----------------------------
FAIL_TIME="$(ts)"
echo "[!] Failing link at $FAIL_TIME"
docker exec "$FAIL_CONT" sh -c "ip link set '$FAIL_IF' down"
sleep "$DOWN_SLEEP"

# ----------------------------
# Restore the link
# ----------------------------
RESTORE_TIME="$(ts)"
echo "[+] Restoring link at $RESTORE_TIME"
docker exec "$FAIL_CONT" sh -c "ip link set '$FAIL_IF' up"

# Let things settle a bit
sleep 2

# ----------------------------
# Stop ping
# ----------------------------
echo
echo "[*] Stopping ping"
kill "$PING_PID" >/dev/null 2>&1 || true
wait "$PING_PID" >/dev/null 2>&1 || true

echo
echo "============================================================"
echo "OSPF convergence test completed"
echo "============================================================"
echo

# ----------------------------
# Report (packet loss + hints)
# ----------------------------
# Extract the ping summary lines from the log
# Typical summary block:
# --- 10.0.3.2 ping statistics ---
# X packets transmitted, Y packets received, Z% packet loss
# round-trip min/avg/max = ...
SUMMARY_LINE="$(grep -E "packets transmitted" "$PING_LOG" | tail -n 1 || true)"
STATS_HDR="$(grep -E "^--- .* ping statistics ---" "$PING_LOG" | tail -n 1 || true)"
RTT_LINE="$(grep -E "round-trip|min/avg/max" "$PING_LOG" | tail -n 1 || true)"

echo "[*] Ping summary (from $PING_LOG):"
if [[ -n "$STATS_HDR" ]]; then
  echo "    $STATS_HDR"
fi
if [[ -n "$SUMMARY_LINE" ]]; then
  echo "    $SUMMARY_LINE"
else
  echo "    (No ping statistics found. Log may be incomplete or ping didn't run long enough.)"
fi
if [[ -n "$RTT_LINE" ]]; then
  echo "    $RTT_LINE"
fi
echo

# Show any obvious failure indicators
echo "[*] Failure indicators (if any):"
FAIL_IND="$(grep -nE "Destination Host Unreachable|100% packet loss|packet loss" "$PING_LOG" || true)"
if [[ -n "$FAIL_IND" ]]; then
  echo "$FAIL_IND" | sed 's/^/    /'
else
  echo "    None found (failover may have been seamless)."
fi
echo

# Optional: show last few ping lines around the fail/restore window (coarse)
echo "[*] Last 15 ping lines (quick view):"
tail -n 15 "$PING_LOG" | sed 's/^/    /'
echo

# Estimate outage window (very rough: look for gaps / unreachable lines)
# If there are "Destination Host Unreachable" lines, count them:
UNREACH_COUNT="$(grep -c "Destination Host Unreachable" "$PING_LOG" 2>/dev/null || true)"
if [[ "$UNREACH_COUNT" -gt 0 ]]; then
  echo "[*] Unreachable events: $UNREACH_COUNT (packet loss occurred during convergence)."
else
  echo "[*] Unreachable events: 0 (either no loss, or loss was too brief to show as 'unreachable')."
fi

echo
echo " goodbye :-) "
