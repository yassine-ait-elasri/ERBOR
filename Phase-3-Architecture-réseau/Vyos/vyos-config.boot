firewall {
    ipv4 {
        name ALLOW_ALL_TO_PROD {
            default-action "accept"
        }
        name ALLOW_SSH_FROM_KRAKEN {
            default-action "drop"
            description "Allow SSH from Kraken to Nexsus"
            rule 10 {
                action "accept"
                description "SSH TCP 22"
                destination {
                    address "10.0.1.5"
                    port "22"
                }
                protocol "tcp"
                source {
                    address "10.0.0.0/16"
                }
            }
            rule 20 {
                action "accept"
                description "Allow SSH from Kraken host"
                destination {
                    address "10.0.1.5"
                    port "22"
                }
                protocol "tcp"
                source {
                    address "10.0.254.11"
                }
            }
            rule 30 {
                action "accept"
                destination {
                    port "22"
                }
                protocol "tcp"
                source {
                    address "10.0.254.11"
                }
            }
        }
        name MGMT_TO_PROD {
            default-action "drop"
            rule 10 {
                action "accept"
                protocol "icmp"
            }
            rule 20 {
                action "accept"
                destination {
                    port "22"
                }
                protocol "tcp"
            }
            rule 30 {
                action "accept"
                state "established"
                state "related"
            }
        }
        name MGMT_TO_PROD_ICMP {
            default-action "drop"
            rule 10 {
                action "accept"
                description "Allow ICMP MGMT to PROD"
                protocol "icmp"
            }
        }
        name PROD_TO_MGMT {
            default-action "drop"
            rule 10 {
                action "accept"
            }
            rule 30 {
                action "accept"
                state "established"
            }
        }
        name PROD_TO_MGMT_STATE {
            default-action "drop"
            rule 10 {
                action "accept"
                description "Allow established/related traffic back to MGMT"
                state "established"
                state "related"
            }
        }
    }
    zone MGMT {
        description "Management zone"
        from PROD {
            firewall {
                name "PROD_TO_MGMT"
            }
        }
        member {
            interface "eth0"
        }
    }
    zone PROD {
        description "Production zone"
        from MGMT {
            firewall {
                name "MGMT_TO_PROD"
            }
        }
        member {
            interface "eth2"
        }
    }
}
interfaces {
    ethernet eth0 {
        address "10.0.1.1/30"
        description "VYOS-TO-PFSENSE"
        hw-id "08:00:27:42:c2:f5"
    }
    ethernet eth1 {
        address "10.0.10.11/24"
        description "ssh here"
        hw-id "08:00:27:5e:d5:99"
    }
    ethernet eth2 {
        address "10.0.1.6/30"
        description "Uplink to core-router eth4"
        hw-id "08:00:27:8c:1b:0a"
    }
    loopback lo {
    }
}
policy {
    access-list 100 {
        description "Allow SSH from Kraken to Nexsus"
        rule 10 {
            action "permit"
            destination {
                host "10.0.1.5"
            }
            source {
                host "10.0.254.11"
            }
        }
    }
}
protocols {
    bgp {
        neighbor 10.0.1.5 {
            description "core-router"
            remote-as "65001"
        }
        system-as "65000"
    }
    ospf {
        interface eth2 {
            area "0"
            network "point-to-point"
        }
        parameters {
            router-id "10.0.1.6"
        }
    }
    static {
        route 0.0.0.0/0 {
            next-hop 10.0.1.2 {
            }
        }
        route 10.0.3.0/26 {
            next-hop 10.0.1.5 {
            }
        }
        route 10.0.12.0/24 {
            next-hop 10.0.1.5 {
            }
        }
    }
}
service {
    ntp {
        allow-client {
            address "127.0.0.0/8"
            address "169.254.0.0/16"
            address "10.0.0.0/8"
            address "172.16.0.0/12"
            address "192.168.0.0/16"
            address "::1/128"
            address "fe80::/10"
            address "fc00::/7"
        }
        server time1.vyos.net {
        }
        server time2.vyos.net {
        }
        server time3.vyos.net {
        }
    }
    ssh {
        listen-address "10.0.254.1"
        listen-address "10.0.10.11"
        port "22"
    }
}
system {
    config-management {
        commit-revisions "100"
    }
    console {
        device ttyS0 {
            speed "115200"
        }
    }
    host-name "vyos-router"
    login {
        operator-group default {
            command-policy {
                allow "*"
            }
        }
        user vyos {
            authentication {
                encrypted-password "$6$rounds=656000$MyJGo40sovGJdaho$WFKYhCSD1KBoTwM3W4Tn9jUamX7pUhrQ/yIjRJwcrokdGZ6bupdhrQBAohgb7fcrdSFr4ZO4Bzn4PVitP8NBY0"
                plaintext-password ""
            }
        }
    }
    name-server "10.0.1.2"
    option {
        reboot-on-upgrade-failure "5"
    }
    sysctl {
        parameter net.ipv4.ip_forward {
            value "1"
        }
    }
    syslog {
        local {
            facility all {
                level "info"
            }
            facility local7 {
                level "debug"
            }
        }
    }
}


// Warning: Do not remove the following line.
// vyos-config-version: "bgp@6:broadcast-relay@1:cluster@2:config-management@1:conntrack@6:conntrack-sync@2:container@3:dhcp-relay@2:dhcp-server@11:dhcpv6-server@6:dns-dynamic@4:dns-forwarding@4:firewall@20:flow-accounting@3:https@7:ids@2:interfaces@34:ipoe-server@4:ipsec@13:isis@3:l2tp@9:lldp@3:mdns@1:monitoring@2:nat@8:nat66@3:nhrp@1:ntp@3:openconnect@3:openvpn@4:ospf@2:pim@1:policy@9:pppoe-server@11:pptp@5:qos@3:quagga@12:reverse-proxy@3:rip@1:rpki@2:salt@1:snmp@3:ssh@2:sstp@6:system@29:vpp@3:vrf@3:vrrp@4:vyos-accel-ppp@2:wanloadbalance@4:webproxy@2"
// Release version: 2025.11.03-0021-rolling
