# Topology — Phase 3  
**Containerlab + Bridge vers le “monde réel”**

Ce lab simule une architecture réseau **3-tier (Core / Distribution / Access)** avec **FRRouting (FRR)**, **OSPF multi-area**, **BFD**, et des **clients LAN** connectés aux routeurs d’accès.

L’émulation tourne sur la VM **Nexsus** (Containerlab + Docker).  
La VM Nexsus elle-même est hébergée dans un environnement virtualisé (ex: VirtualBox).  
Pour sortir du lab (Internet / pfSense / VyOS / réseau réel), on utilise un **bridge Linux : `br-core`**.

---

## 1) Vue d’ensemble des couches

### 🔹 Core
- **Rôle** : backbone, agrégation des routes, point de sortie vers l’extérieur  
- **Exemple** : `core-router`  
- **Lien “Outside”** : interface `eth4` (uplink vers VyOS/pfSense)

### 🔹 Distribution
- **Rôle** : agrégation, **ABR OSPF**, distribution vers les Access  
- **Exemples** : `dist01` → `dist04`

### 🔹 Access
- **Rôle** : terminaison des LAN utilisateurs  
- **Exemples** : `access01` → `access12`  
- **LAN clients** : interface `eth6` de chaque access

---

## 2) Plan d’adressage — synthèse

### 📍 Core ↔ Distribution (OSPF Area 0)

| Core iface | IP Core        | Dist | Dist iface | IP Dist        |
|-----------|----------------|------|------------|----------------|
| eth1 | 10.0.1.8/31  | dist01 | eth5 | 10.0.1.9/31 |
| eth2 | 10.0.1.10/31 | dist02 | eth5 | 10.0.1.11/31 |
| eth3 | 10.0.1.12/31 | dist03 | eth5 | 10.0.1.13/31 |
| eth5 | 10.0.1.14/31 | dist04 | eth5 | 10.0.1.15/31 |

---

### 📍 Distribution ↔ Access (OSPF Area 1 — exemple)

| Distribution | Access | Dist iface | IP Dist     | Access iface | IP Access   |
|--------------|--------|------------|-------------|--------------|-------------|
| dist01 | access01 | eth4 | 10.0.2.12/31 | eth5 | 10.0.2.13/31 |
| dist01 | access02 | eth6 | 10.0.2.14/31 | eth5 | 10.0.2.15/31 |
| dist01 | access03 | eth7 | 10.0.2.16/31 | eth5 | 10.0.2.17/31 |
| dist02 | access04 | eth4 | 10.0.2.18/31 | eth5 | 10.0.2.19/31 |
| dist02 | access05 | eth6 | 10.0.2.20/31 | eth5 | 10.0.2.21/31 |
| dist02 | access06 | eth7 | 10.0.2.22/31 | eth5 | 10.0.2.23/31 |
| dist03 | access07 | eth4 | 10.0.2.24/31 | eth5 | 10.0.2.25/31 |
| dist03 | access08 | eth6 | 10.0.2.26/31 | eth5 | 10.0.2.27/31 |
| dist03 | access09 | eth7 | 10.0.2.28/31 | eth5 | 10.0.2.29/31 |
| dist04 | access10 | eth4 | 10.0.2.30/31 | eth5 | 10.0.2.31/31 |
| dist04 | access11 | eth6 | 10.0.2.32/31 | eth5 | 10.0.2.33/31 |
| dist04 | access12 | eth7 | 10.0.2.34/31 | eth5 | 10.0.2.35/31 |

---

### 📍 LAN utilisateurs (Access → Clients)

| Access | LAN iface | LAN subnet     | Client IP |
|-------|-----------|----------------|-----------|
| access01 | eth6 | 10.0.3.0/24  | 10.0.3.2 |
| access02 | eth6 | 10.0.4.0/24  | — |
| access03 | eth6 | 10.0.5.0/24  | — |
| access04 | eth6 | 10.0.6.0/24  | — |
| access05 | eth6 | 10.0.7.0/24  | — |
| access06 | eth6 | 10.0.8.0/24  | — |
| access07 | eth6 | 10.0.9.0/24  | — |
| access08 | eth6 | 10.0.10.0/24 | — |
| access09 | eth6 | 10.0.11.0/24 | — |
| access10 | eth6 | 10.0.12.0/24 | 10.0.12.2 |
| access11 | eth6 | 10.0.13.0/24 | — |
| access12 | eth6 | 10.0.14.0/24 | — |

---

## 3) Bridge `br-core` — sortie vers le “monde réel” (double virtualisation)

### 🎯 Objectif
Le lab tourne :
- dans des **conteneurs Docker**,  
- eux-mêmes dans une **VM Nexsus**,  
- elle-même dans **VirtualBox / hyperviseur**.

Pour connecter ce lab au réseau externe (VyOS/pfSense/Internet), on “perce” **deux couches de virtualisation** via un bridge Linux.

### ⚙️ Fonctionnement
- L’interface VM **`enp0s3`** est reliée au réseau externe.
- Un bridge Linux **`br-core`** est créé sur Nexsus.
- `enp0s3` est **enslaved** dans `br-core` :
  - `enp0s3` devient un port **L2 pur**,
  - `br-core` porte la connectivité logique.
- L’interface **`eth4` du core-router** est connectée à `br-core`.

➡️ Le **core-router** devient la **frontière entre le lab et le monde réel**.

---

## 4) Pourquoi `enp0s3` ne doit pas avoir d’IP

- Une interface enslaved dans un bridge doit rester **L2**.
- Garder une IP sur `enp0s3` introduit :
  - ambiguïtés L2/L3,
  - ARP incohérents,
  - routes fantômes.

✅ **Bonne pratique** :  
- `enp0s3` → **pas d’IP**  

### Mode promiscuous
Indispensable pour :
- le transit multi-segments,
- le mirroring,
- éviter des drops au niveau de la virtualisation (driver / hyperviseur).

---

## 5) Adressage et sortie Internet

- **Uplink externe** : `core-router eth4`
- **Default route externe** :
  ```bash
  default via <ip_vyos_pfsense> dev eth4
Le core-router est ASBR OSPF :

il injecte 0.0.0.0/0 dans OSPF,

Distribution et Access apprennent la route par défaut dynamiquement.

## 6) Suppression de la default route Docker (eth0)
Containerlab/Docker injecte souvent :

  ```bash
default via 172.20.20.1 dev eth0
  ```
❌ Cette route détourne le trafic vers le réseau Docker.
✅ Fix appliqué : suppression automatique de cette route sur tous les routeurs après déploiement.

## 7) Chemin de trafic attendu (client → Internet)
Exemple : client-a (LAN access01)
Client → `10.0.3.1` (access01 eth6)

Access01 → Distribution (OSPF Area 1)

Distribution → Core (Area 0)

Core-router → VyOS/pfSense (eth4)

VyOS/pfSense → Internet

✔ Architecture cohérente
✔ Routage dynamique maîtrisé
✔ Sortie Internet contrôlée
✔ Prête pour démonstration et audit
