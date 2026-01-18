# Topology — ERBOR (Phase 3)

## 1) Vue d’ensemble

ERBOR (Phase 3) implémente une topologie **3-tier** (Core / Distribution / Access) émulée avec **Containerlab** et des routeurs **FRRouting (FRR)**.

- **Core** : 1 routeur (core-router) + 1 bridge externe (br-core) vers l’edge (VyOS/pfSense)
- **Distribution** : 4 routeurs (dist01..dist04) en **full-mesh**
- **Access** : 12 routeurs (access01..access12), connectés aux distributions
- **Clients** : 2 hôtes (client-a, client-b) pour valider la connectivité end-to-end

Total : **17 routeurs FRR** (1 core + 4 dist + 12 access) + 2 clients + 1 bridge.

---

## 2) Nœuds

### Core
- `core-router` (FRR)  
  - Interfaces backbone vers Distribution (Area 0)
  - Interface vers bridge externe `br-core`
  - Route par défaut vers l’edge (`10.0.1.6` via `eth4`)

- `br-core` (bridge)
  - Pont L2 utilisé pour raccorder le core à l’environnement externe (VyOS/pfSense)

### Distribution
- `dist01`, `dist02`, `dist03`, `dist04` (FRR)
  - Rôle : agrégation, **ABR** entre Area 0 et Area 1
  - Connexions :
    - 1 lien vers Core (Area 0)
    - 3 liens vers autres Distribution (Area 1) — full mesh
    - 3 liens vers Access (Area 1)

### Access
- `access01` … `access12` (FRR)
  - 1 lien uplink vers un Distribution (Area 1)
  - 1 lien LAN vers un sous-réseau /24 (utilisateurs/clients)

### Clients
- `client-a` : connecté au LAN de `access01`
- `client-b` : connecté au LAN de `access10`

---

## 3) Liaisons physiques (Containerlab)

### 3.1 Core ↔ Distribution
- `core-router:eth1` ↔ `dist01:eth5`
- `core-router:eth2` ↔ `dist02:eth5`
- `core-router:eth3` ↔ `dist03:eth5`
- `core-router:eth5` ↔ `dist04:eth5`

### 3.2 Distribution ↔ Distribution (Full-mesh)
- `dist01:eth1` ↔ `dist02:eth1`
- `dist01:eth2` ↔ `dist03:eth1`
- `dist01:eth3` ↔ `dist04:eth1`
- `dist02:eth2` ↔ `dist03:eth2`
- `dist02:eth3` ↔ `dist04:eth2`
- `dist03:eth3` ↔ `dist04:eth3`

### 3.3 Distribution ↔ Access
#### dist01
- `dist01:eth4` ↔ `access01:eth5`
- `dist01:eth6` ↔ `access02:eth5`
- `dist01:eth7` ↔ `access03:eth5`

#### dist02
- `dist02:eth4` ↔ `access04:eth5`
- `dist02:eth6` ↔ `access05:eth5`
- `dist02:eth7` ↔ `access06:eth5`

#### dist03
- `dist03:eth4` ↔ `access07:eth5`
- `dist03:eth6` ↔ `access08:eth5`
- `dist03:eth7` ↔ `access09:eth5`

#### dist04
- `dist04:eth4` ↔ `access10:eth5`
- `dist04:eth6` ↔ `access11:eth5`
- `dist04:eth7` ↔ `access12:eth5`

### 3.4 Clients ↔ LAN Access
- `client-a:eth5` ↔ `access01:eth6`
- `client-b:eth5` ↔ `access10:eth6`

### 3.5 Core ↔ Bridge externe
- `core-router:eth4` ↔ `br-core:eth4`

---

## 4) Plan d’adressage (résumé opérationnel)

### 4.1 Loopbacks (Router-ID)
- Core : `10.0.255.1/32`
- Distribution : `10.0.255.11/32` … `10.0.255.14/32`
- Access : `10.0.255.101/32` … `10.0.255.112/32`

### 4.2 P2P Core ↔ Distribution (Area 0) — /31
- Core ↔ dist01 : `10.0.1.8/31` ↔ `10.0.1.9/31`
- Core ↔ dist02 : `10.0.1.10/31` ↔ `10.0.1.11/31`
- Core ↔ dist03 : `10.0.1.12/31` ↔ `10.0.1.13/31`
- Core ↔ dist04 : `10.0.1.14/31` ↔ `10.0.1.15/31`

### 4.3 P2P Distribution ↔ Distribution (Area 1) — /31
- dist01 ↔ dist02 : `10.0.2.0/31` ↔ `10.0.2.1/31`
- dist01 ↔ dist03 : `10.0.2.2/31` ↔ `10.0.2.3/31`
- dist01 ↔ dist04 : `10.0.2.4/31` ↔ `10.0.2.5/31`
- dist02 ↔ dist03 : `10.0.2.6/31` ↔ `10.0.2.7/31`
- dist02 ↔ dist04 : `10.0.2.8/31` ↔ `10.0.2.9/31`
- dist03 ↔ dist04 : `10.0.2.10/31` ↔ `10.0.2.11/31`

### 4.4 P2P Distribution ↔ Access (Area 1) — /31
- dist01 ↔ access01 : `10.0.2.12/31` ↔ `10.0.2.13/31`
- dist01 ↔ access02 : `10.0.2.14/31` ↔ `10.0.2.15/31`
- dist01 ↔ access03 : `10.0.2.16/31` ↔ `10.0.2.17/31`

- dist02 ↔ access04 : `10.0.2.18/31` ↔ `10.0.2.19/31`
- dist02 ↔ access05 : `10.0.2.20/31` ↔ `10.0.2.21/31`
- dist02 ↔ access06 : `10.0.2.22/31` ↔ `10.0.2.23/31`

- dist03 ↔ access07 : `10.0.2.24/31` ↔ `10.0.2.25/31`
- dist03 ↔ access08 : `10.0.2.26/31` ↔ `10.0.2.27/31`
- dist03 ↔ access09 : `10.0.2.28/31` ↔ `10.0.2.29/31`

- dist04 ↔ access10 : `10.0.2.30/31` ↔ `10.0.2.31/31`
- dist04 ↔ access11 : `10.0.2.32/31` ↔ `10.0.2.33/31`
- dist04 ↔ access12 : `10.0.2.34/31` ↔ `10.0.2.35/31`

### 4.5 LAN Access — /24
- access01 LAN : `10.0.3.0/24` (GW `10.0.3.1`)
- access02 LAN : `10.0.4.0/24` (GW `10.0.4.1`)
- access03 LAN : `10.0.5.0/24` (GW `10.0.5.1`)
- access04 LAN : `10.0.6.0/24` (GW `10.0.6.1`)
- access05 LAN : `10.0.7.0/24` (GW `10.0.7.1`)
- access06 LAN : `10.0.8.0/24` (GW `10.0.8.1`)
- access07 LAN : `10.0.9.0/24` (GW `10.0.9.1`)
- access08 LAN : `10.0.10.0/24` (GW `10.0.10.1`)
- access09 LAN : `10.0.11.0/24` (GW `10.0.11.1`)
- access10 LAN : `10.0.12.0/24` (GW `10.0.12.1`)
- access11 LAN : `10.0.13.0/24` (GW `10.0.13.1`)
- access12 LAN : `10.0.14.0/24` (GW `10.0.14.1`)

### 4.6 Clients (test end-to-end)
- client-a : `10.0.3.2/26`, GW `10.0.3.1` (via access01)
- client-b : `10.0.12.2/24`, GW `10.0.12.1` (via access10)

### 4.7 Sortie externe (Core ↔ Edge via br-core)
- core-router `eth4` : `10.0.1.5/30`
- next-hop edge : `10.0.1.6` (default route du core)

---

## 5) Rôle OSPF & segmentation logique

- **Area 0 (Backbone)** : liens Core ↔ Distribution
- **Area 1** : full-mesh Distribution + uplinks Access + LAN redistribués (connected)

Les routeurs Distribution sont des **ABR (Area 0 ↔ Area 1)**.

---

## 6) Artefacts du dépôt

- Fichier de topologie Containerlab : `nexsus.yml`
- Diagramme généré : `nexsus.clab.drawio` / exports images
- Configurations FRR : `configs/*.conf`
- Automatisation : `ansible/` (inventory, host_vars, templates, playbooks)

---
```0
