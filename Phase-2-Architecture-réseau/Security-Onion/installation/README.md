# 📘 README — Configuration de Security Onion (Phase 2)

## 🔎 Introduction

Ce document décrit **de manière exhaustive** la configuration de Security Onion dans le cadre du **Phase 2 – Pipeline SOAR léger**.
L’objectif est d’obtenir un environnement capable de :

* générer des alertes Suricata,
* exporter ces alertes depuis les fichiers d’événements,
* transférer les alertes vers Redis,
* alimenter les workflows n8n via un worker Python,
* permettre la réponse automatique (blocage / déblocage).

Le tout est réalisé en **mode Évaluation (EVAL)**, utilisé pour les environnements de laboratoire ou de démonstration.

Cette documentation sert de référence centrale et décrit **le pourquoi**, **le comment** et **les structures de répertoires** nécessaires à l’intégration complète avec notre pipeline SOAR.

---

# 1️⃣ Choix du Mode de Déploiement : ÉVALUATION (EVAL)

Security Onion propose plusieurs modes de déploiement :

* **IMPORT**
* **EVAL (Évaluation)**
* **STANDALONE**
* **DISTRIBUTED**

Dans notre architecture Phase 2, **EVAL** est le choix optimal car :

* il permet une installation simple et rapide,
* il inclut tous les composants essentiels (Suricata, Elasticsearch réduit, interface et dashboards),
* il est parfaitement adapté à un laboratoire,
* il consomme peu de ressources comparé à Standalone/Distributed,
* il permet l’analyse en temps réel des alertes.

### 🔧 Comment le sélectionner ?

Lors de l’exécution de l’assistant `so-setup`, sélectionner :

```
EVAL – Évaluation
```

Puis suivre les instructions à l’écran.

⚠️ **Attention :**
Le mode Évaluation *n’est pas* destiné à un usage en production.
Il n’inclut pas toutes les optimisations ni la haute disponibilité.

---

# 2️⃣ Configuration Réseau : Règles et Pièges

Security Onion repose fortement sur sa configuration réseau.
Voici les bonnes pratiques **impératives** :

### ✔ Interface de gestion

* Doit être la **seule interface possédant une adresse IP**.
* Sera utilisée pour accéder à :

  * l’interface web Security Onion,
  * SSH,
  * les opérations d’administration.

### ✔ Interfaces de capture (sniffing)

* **Ne doivent JAMAIS avoir d’adresse IP.**
* Doivent être connectées à un port **TAP** ou **SPAN/Mirror**.
* Éviter de les brancher sur un port standard d’un switch (risque d’obtenir une IP via DHCP par erreur).

### ⚠ Message d’erreur critique

Si vous voyez :

> *The IP being routed by Linux is not the IP address assigned to the management interface*

Alors :

* une interface de capture a reçu une IP,
* ou la configuration réseau est incorrecte,
* ou le câblage n’est pas conforme.

Corriger avant de continuer l’installation.

---

# 3️⃣ Architecture Fichiers (Phase 2)

Afin d’intégrer Security Onion dans notre pipeline SOAR, nous utilisons les répertoires suivants :

```
/nsm/suricata/               # Répertoire contenant les évènements Suricata
/opt/soar/                   # Scripts principaux Phase 2 (script.sh, call.sh)
▾ /var/lib/soar/             # Données persistantes
    last_ts.txt              # Timestamp global le plus récent
    processed_files.txt      # Inode & offset pour chaque fichier analysé
/var/log/soar/               # Logs détaillés des scripts SOAR
```

### 📝 Détails des fichiers utilisés

#### `/nsm/suricata/eve-*.json`

Contient les alertes Suricata, en rotation automatique :
`eve.json`, `eve.1.json`, `eve.2.json.gz`, etc.

#### `/var/lib/soar/last_ts.txt`

Stocke le **dernier timestamp global**.
Permet de ne lire que les alertes plus récentes que la dernière exécution.

#### `/var/lib/soar/processed_files.txt`

Stocke :

* le nom du fichier,
* son inode,
* la dernière position lue (offset),
* son statut.

Permet d’éviter de relire les fichiers déjà analysés, même s’ils sont compressés/rotés.

#### `/var/log/soar/`

Ce répertoire contient notamment :

* `script_debug_verbose.log` — log détaillé du parseur Security Onion → Redis
* `call.log` — log du superviseur `call.sh`

---

# 4️⃣ Étapes Après Installation

Après installation de Security Onion en mode ÉVAL :

## 4.1 Vérifier l’état du système

Exécuter :

```bash
sudo so-status
```

<img width="882" height="757" alt="image" src="https://github.com/user-attachments/assets/62625449-feda-4657-9a27-6354f0546100" />

Pour valider que tous les services critiques fonctionnent. (Vérifier Suricata) 

## 4.2 Vérifier la présence des fichiers d’événements

```bash
ls -1tr /nsm/suricata
```

Vous devriez voir :

<img width="815" height="767" alt="image" src="https://github.com/user-attachments/assets/dae24406-2383-48e8-bf13-5906194d4726" />


## 4.3 Préparer les répertoires SOAR

```bash
sudo mkdir -p /opt/soar /var/lib/soar /var/log/soar
sudo chmod -R 755 /opt/soar /var/lib/soar /var/log/soar
```

## 4.4 Déployer les scripts Phase 2

Copier vos scripts :

```bash
sudo cp script.sh /opt/soar/
sudo cp call.sh /opt/soar/
sudo chmod +x /opt/soar/*.sh
```

---

# 5️⃣ Intégration Redis

Redis joue un rôle central : c’est un **tampon** entre Security Onion et n8n.

Avantages :

* extrêmement rapide,
* stocke les alertes sous forme de liste,
* entièrement scalable (plusieurs workers peuvent consommer simultanément),
* décorelle Security Onion du worker.

### Vérifier la connexion Redis :

```bash
redis-cli -h 10.0.254.6 -a 123 PING
```

Réponse attendue :

```
PONG
```

### Liste utilisée par notre pipeline :

```
so:alerts
```

---

# 6️⃣ Test du Pipeline

## 6.1 Lancer une analyse simple

```bash
sudo /opt/soar/script.sh --once 10
```

Ce test vérifie :

* lecture correcte des fichiers eve-*.json,
* détection des nouveaux événements,
* insertion dans Redis.

## 6.2 Vérifier dans Redis (10.0.254.6/24)

```bash
redis-cli -a 123 LLEN so:alerts
```

Doit retourner un nombre **strictement positif**.

## 6.3 Suivre les logs

```bash
tail -f /var/log/soar/script_debug_verbose.log
```

```bash
tail -f /var/log/soar/call.log
```
<img width="1912" height="273" alt="image" src="https://github.com/user-attachments/assets/18dacdbe-b476-41ae-96d9-6cbab8d4056f" />

---

# 7️⃣ Fonctionnement Interne du Parseur Phase 2

Le script Phase 2 inclut :

### ✔ Suivi par timestamp global

Le fichier `last_ts.txt` permet d’assurer :

* aucune relecture,
* aucune perte d’alertes,
* indépendance totale par rapport aux rotations.
  
<img width="1183" height="77" alt="image" src="https://github.com/user-attachments/assets/a90c9cdc-ad5d-4ccc-b7fb-e545c0ae43ca" />

### ✔ Suivi par inode + offset

`processed_files.txt` évite les doublons en suivant :

* le fichier,
* sa nouvelle taille,
* sa position courante,
* son inode.

Cela permet de gérer :

* les fichiers compressés/décompressés,
* les rotations fréquentes de Security Onion,
* les changements brutaux de taille,
* les suppressions/recréations.

<img width="467" height="760" alt="image" src="https://github.com/user-attachments/assets/64f14097-0c3e-479e-a865-8a39ffbf4fa2" />

### ✔ Lecture incrémentale réelle

Le script lit **uniquement** les lignes dont le timestamp > `last_ts.txt`.

---

# 8️⃣ Automatisation via systemd (optionnel mais recommandé)

Créer le service :

```
/etc/systemd/system/soar-caller.service
```

Exemple minimal :

```ini
[Unit]
Description=SOAR Caller - Superviseur script.sh

[Service]
ExecStart=/opt/soar/call.sh
Restart=always

[Install]
WantedBy=multi-user.target
```

Installation :

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now soar-caller
sudo systemctl status soar-caller
```

---

# 9️⃣ Liste de Validation Final

| Élément                                         | OK ? |
| ----------------------------------------------- | ---- |
| Suricata génère bien des eve.json               | ☐    |
| Le script lit les événements récents uniquement | ☐    |
| Les logs sont créés sans erreur                 | ☐    |
| Redis reçoit les alertes                        | ☐    |
| n8n reçoit les webhooks depuis le worker        | ☐    |
| Le pipeline block/unblock fonctionne            | ☐    |

---

# 🔚 Conclusion

Cette configuration permet d'intégrer **Security Onion → Redis → Worker → n8n → pfSense**, sans dépendre des connecteurs payants de Kibana/Elastic.
Le mode Évaluation, associé à un pipeline externe léger, donne un SOAR fonctionnel, extensible, scalable et totalement open source.

---
