# Runbook Opérationnel — ERBOR (Phase 3)

## 1. Objet du document

Ce runbook décrit les **procédures opérationnelles** permettant :

- le déploiement,
- la vérification,
- la supervision,
- le diagnostic,
- et la gestion des incidents

de l’infrastructure réseau **ERBOR – Phase 3 (Advanced Networking & Automatisation)**.

Il s’adresse à un **ingénieur réseau**, **opérateur NOC**, ou **auditeur technique**.

---

## 2. Périmètre couvert

Ce runbook couvre exclusivement :

- Containerlab
- FRRouting (FRR)
- OSPF multi-area
- BFD
- Automatisation Ansible
- Tests de convergence et de résilience

❌ Ne couvre pas :
- Zero Trust
- Sécurité applicative
- SOC / SOAR (Phase 2)

---

## 3. Pré-requis

### 3.1 Environnement hôte

- Linux (Ubuntu / Debian recommandé)
- Docker installé et fonctionnel
- Containerlab installé
- Ansible installé
- Accès réseau Internet (pour images Docker)

### 3.2 Vérification rapide

```bash
docker version
containerlab version
ansible --version
```
4. Déploiement de l’infrastructure
```bash
ansible-playbook -i inventory.yml playbooks/deploy-frr.yml
```

