# Installation de VyOS

Cette section décrit le déploiement et la configuration initiale de VyOS pour le laboratoire d’infrastructure réseau (Phase 1).

---

## a) Démarrage de l’ISO VyOS

1. Créer une nouvelle VM (Linux 64-bit, 2 CPU, 1–2 GB RAM).  
2. Monter l’ISO VyOS dans la VM.  
3. Démarrer la VM pour accéder au système VyOS en mode live.

---

## b) Installation du système

1. Lancer la commande d’installation :
```bash
install image
```
Suivre les instructions à l’écran.
Choisir les options par défaut (recommandé pour ce laboratoire).
Redémarrer la VM sans l’ISO.

## c) Configuration des interfaces réseau

Exemple de configuration selon le plan d’adressage fourni :
```bash
configure
```
```bash
set interfaces ethernet eth0 address 10.0.1.1/30
```
```bash
set interfaces ethernet eth1 address 10.0.254.1/24
```
```bash
set interfaces ethernet eth2 address 10.0.10.1/24
```
```bash
commit
```
```bash
save
```
```bash
exit
```
| Zone            | Sous-réseau          |
|----------------|-----------------------|
| **eth0**  | `Core link vers pfSense`         |
| **eth1** | `ssh`       |
| **eth2**        | `Distribution/Access `         |


## d) Preuve de bon fonctionnement (PoC)
