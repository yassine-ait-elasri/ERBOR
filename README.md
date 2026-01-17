ERBOR — Laboratoire d’Infrastructure Réseau et Sécurité

ERBOR est un laboratoire complet de simulation d’une infrastructure réseau de type agence nationale / gouvernementale, conçu pour démontrer :

la conception réseau avancée (3-tier Core / Distribution / Access),

la résilience du routage dynamique,

l’intégration SOC (détection → décision → réponse),

et l’automatisation complète du déploiement et des changements.

Le projet est structuré par phases successives, chacune apportant un niveau supplémentaire de maturité opérationnelle.

🎯 Objectif général

Simuler une infrastructure réaliste de grade production, mettant en œuvre :

une architecture réseau hiérarchisée,

des mécanismes de routage dynamiques et résilients,

une chaîne de détection et de réponse aux incidents,

et des outils d’automatisation permettant la reproductibilité, la traçabilité et l’évolution incrémentale de l’architecture.

Ce laboratoire a une vocation pédagogique, technique et démonstrative, notamment dans un contexte d’audit, d’ingénierie réseau ou de cybersécurité opérationnelle.

🏔️ Origine du nom ERBOR

Le nom ERBOR est inspiré d’Erebor, la Montagne Solitaire dans Le Hobbit, où un trésor immense repose au cœur d’une forteresse réputée imprenable.
Mais cette référence est aussi un rappel volontairement critique : malgré des défenses extérieures solides, le trésor fut compromis de l’intérieur lorsque Bilbo s’empara de l’Arkenstone.

Cette analogie illustre un principe fondamental de la sécurité moderne : le danger le plus critique vient souvent de l’intérieur.
Une architecture réellement résiliente ne peut reposer sur la confiance implicite — elle doit vérifier, segmenter et surveiller en permanence, y compris les composants internes.
ERBOR assume donc cette contradiction : une forteresse puissante, mais jamais totalement sûre tant que le modèle Zero Trust n’est pas pleinement appliqué.


🧱 Architecture globale

Architecture 3-Tier :

Core : routage backbone, sortie vers l’extérieur

Distribution : agrégation, ABR OSPF, segmentation

Access : accès utilisateurs / LAN

Environ 17 routeurs FRR interconnectés

Segmentation logique par zones et sous-réseaux dédiés

Diagrammes générés automatiquement via Containerlab + Draw.io

(Schéma ci-dessous)

<img width="9879" height="5452" alt="ERBOR – Architecture réseau" src="https://github.com/user-attachments/assets/5249bc4e-147b-4390-b568-baf0dc4b9d62" />
📌 Phases du projet
🔹 Phase 1 — Architecture réseau & fondations

Objectif : poser une base réseau propre, lisible et extensible.

Architecture 3-tier (Core / Distribution / Access)

Plan d’adressage IP structuré

Routage statique initial

Pare-feu pfSense

Routeur edge VyOS

Environnement VirtualBox organisé

Documentation et schémas d’architecture

📂 Dossier : Phase-1-Architecture-réseau/

🔹 Phase 2 — SOC & automatisation de la réponse

Objectif : introduire la détection et la réponse automatisée.

Security Onion comme plateforme SOC

Suricata IDS avec règles personnalisées

Port mirroring réseau

Chaîne automatisée :

Suricata → Redis → Worker Python → n8n → pfSense (API)


Blocage et déblocage automatiques via aliases pfSense

SOAR léger, orienté réaction rapide

📂 Dossier : Phase-2-Architecture-réseau/

🔹 Phase 3 — Advanced Networking & automatisation (implémentée)

Objectif : rendre le réseau résilient, dynamique et automatisé.

Containerlab pour l’émulation réseau

FRRouting (FRR) sur tous les routeurs

OSPF multi-area (Area 0 / Area 1)

ABR Distribution

OSPF MD5 Authentication

BFD pour détection de panne rapide

Convergence et failover démontrés

Ansible :

inventaire structuré

host_vars

templates Jinja2

déploiement reproductible

Preuve de fonctionnement via :

tests manuels

script de convergence

vidéo PoC

📂 Dossier : Phase-3-Architecture-réseau/

🔹 Phase 4 — Zero Trust (prévue / non implémentée)

Objectif futur : couvrir les menaces internes et les mouvements latéraux.

Approche Zero Trust

Contrôle d’accès basé sur l’identité

Micro-segmentation

Observabilité east-west

Détection comportementale

⚠️ Cette phase est volontairement hors scope du projet actuel
et fera l’objet d’une future étude et d’une implémentation .

⚙️ Automatisation & philosophie d’ingénierie

Aucune configuration critique n’est faite manuellement

Tout changement réseau est :

versionné

traçable

reproductible

L’architecture est pensée pour :

des mises à jour incrémentales

des tests de résilience

une évolution continue

📂 Organisation du dépôt
Phase-1-Architecture-réseau/
Phase-2-Architecture-réseau/
Phase-3-Architecture-réseau/
images/
docs/


Chaque phase est autonome, documentée et vérifiable.

📌 État du projet

✔ Phase 1 : terminée
✔ Phase 2 : terminée
✔ Phase 3 : terminée 
⏳ Phase 4 : à l’étude

🏁 Conclusion

ERBOR n’est pas un simple lab académique, mais une plateforme d’expérimentation réaliste, orientée :

ingénierie réseau,

cybersécurité opérationnelle,

automatisation,

et résilience des infrastructures critiques.

<img width="9879" height="5452" alt="_con nexsus clab drawio (1)" src="https://github.com/user-attachments/assets/5249bc4e-147b-4390-b568-baf0dc4b9d62" />
