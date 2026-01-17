# Phase 3 — Advanced Networking & Automatisation

## 1. Contexte et objectifs

La **Phase 3** du projet **ERBOR** vise à transformer une architecture réseau fonctionnelle en une **infrastructure dynamique, résiliente et automatisée**, proche des contraintes rencontrées en environnement de production (agence nationale / infrastructure critique).

L’objectif principal est de démontrer :

- la **résilience du routage** face aux pannes,
- la **convergence rapide** sans intervention humaine,
- la **reproductibilité totale** du déploiement,
- et la capacité à **faire évoluer l’architecture** sans reconfiguration manuelle.

Cette phase se concentre exclusivement sur l’ingénierie réseau avancée et l’automatisation, indépendamment des couches SOC déjà introduites en Phase 2.

---

## 2. Architecture implémentée

### 2.1 Modèle architectural

L’architecture repose sur un **modèle 3-Tier classique** :

- **Core**
  - Backbone OSPF
  - Point de sortie vers l’extérieur (pfSense / VyOS)
  - Concentration du routage inter-zones

- **Distribution**
  - Rôle d’ABR (Area Border Router)
  - Agrégation des accès
  - Séparation logique des zones OSPF

- **Access**
  - Connexion des LAN utilisateurs
  - Dernier saut de routage
  - Exposition contrôlée vers la distribution

Au total, l’infrastructure comprend **17 routeurs FRRouting (FRR)** interconnectés.

---

### 2.2 Émulation et outillage

- **Containerlab**
  - Émulation réseau déterministe
  - Gestion des liens, interfaces et topologies complexes
  - Génération automatique de diagrammes (Draw.io)

- **FRRouting (FRR)**
  - Implémentation complète du protocole OSPF
  - Support BFD
  - Authentification OSPF
  - Comportement proche d’équipements réseau réels

Ce choix permet de tester des comportements réseau réalistes sans dépendre d’équipements physiques.

---

## 3. Routage dynamique

### 3.1 OSPF multi-area

Le protocole **OSPF** est utilisé comme protocole de routage dynamique principal.

- **Area 0 (Backbone)**  
  - Core ↔ Distribution

- **Area 1 (Accès)**  
  - Distribution ↔ Access

Ce découpage permet :

- de limiter la propagation des LSAs,
- de réduire la charge de calcul SPF,
- d’éviter les tempêtes de messages OSPF,
- et de rendre l’architecture **scalable**.

Les routeurs de distribution jouent explicitement le rôle d’**ABR**.

---

### 3.2 Adressage point-à-point

Tous les liens inter-routeurs utilisent des **/31** :

- optimisation de l’espace d’adressage,
- absence de broadcast inutile,
- conformité aux bonnes pratiques opérateur.

Les LAN d’accès utilisent des **/24 dédiés**, isolés par zone.

---

### 3.3 Sécurité du routage

Même dans un environnement de laboratoire, les mécanismes de sécurité sont activés :

- **OSPF MD5 Authentication**
  - Protection contre l’injection de routes
  - Prévention des adjacences non autorisées

- **Authentification par zone**
  - Clés distinctes par aire OSPF
  - Cloisonnement logique du routage

---

## 4. Détection rapide de panne (BFD)

### 4.1 Pourquoi BFD

Les timers OSPF classiques (Hello/Dead) ne sont pas adaptés aux exigences modernes de résilience.

Le protocole **BFD (Bidirectional Forwarding Detection)** est activé sur tous les liens point-à-point afin de :

- détecter les pannes en quelques centaines de millisecondes,
- accélérer la convergence OSPF,
- éviter les blackholes temporaires.

---

### 4.2 Résultat observé

Lors des tests :

- la panne d’un lien est détectée quasi instantanément,
- les routes sont recalculées sans intervention manuelle,
- le trafic est réacheminé via les chemins alternatifs disponibles.

---

## 5. Automatisation du déploiement

### 5.1 Choix d’Ansible

Aucune configuration critique n’est appliquée manuellement.

**Ansible** est utilisé pour :

- garantir l’**idempotence**,
- centraliser la logique de déploiement,
- permettre des reconstructions complètes en un seul lancement,
- versionner chaque changement d’architecture.

---

### 5.2 Organisation

- `inventory.yml`  
  Définition des nœuds et groupes logiques

- `host_vars/`  
  Paramètres spécifiques par routeur

- `templates/`  
  Modèles Jinja2 pour les configurations FRR

- `playbooks/`  
  Déploiement du routage, des interfaces et des services

Cette approche permet :

- des **mises à jour incrémentales**,
- des tests reproductibles,
- une traçabilité complète des changements.

---

## 6. Résilience et démonstration de convergence

### 6.1 Scénario testé

Un scénario de panne contrôlée est exécuté :

1. État stable initial
2. Coupure d’un lien Distribution ↔ Access
3. Détection via BFD
4. Recalcul SPF OSPF
5. Réacheminement du trafic
6. Restauration du lien
7. Retour à l’état initial

---

### 6.2 Preuve de fonctionnement

La démonstration repose sur :

- des tests de connectivité end-to-end,
- des commandes OSPF (`show ip ospf neighbor`, `show ip route ospf`),
- un script de convergence automatisé,
- une **vidéo PoC** montrant :
  - la panne,
  - la continuité du service,
  - la reconvergence automatique.

---

## 7. Limites connues et périmètre

Cette phase **n’implémente pas** :

- le Zero Trust,
- la micro-segmentation east-west,
- le contrôle d’accès basé sur l’identité,
- la détection des menaces internes.

Ces limitations sont **assumées et documentées**.

La Phase 3 démontre la **résilience réseau**, pas la sécurité complète contre les menaces internes.

---

## 8. Positionnement dans le projet ERBOR

La Phase 3 constitue le **socle technique** nécessaire avant toute approche Zero Trust :

- un réseau non résilient ne peut pas être sécurisé efficacement,
- l’automatisation est un prérequis à toute politique de contrôle fin,
- la visibilité réseau précède la détection comportementale.

La Phase 4 viendra traiter explicitement ces enjeux.

---

## 9. État d’avancement

- Phase 1 : ✔ terminée
- Phase 2 : ✔ terminée
- **Phase 3 : ✔ implémentée et validée**
- Phase 4 : ⏳ à l’étude

---

## 10. Conclusion

La Phase 3 d’ERBOR démontre qu’une infrastructure réseau :

- peut être **résiliente par conception**,
- **automatisée de bout en bout**,
- testable, reconstruisible et évolutive,
- et prête à accueillir des mécanismes de sécurité avancés.

Elle constitue une base réaliste pour des scénarios d’ingénierie réseau, d’audit, ou de cybersécurité opérationnelle en environnement critique.

