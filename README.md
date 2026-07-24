# Zabbix Automation Toolkit

## Présentation

Ce dépôt regroupe les scripts d'automatisation développés durant mon stage technique à la Société Nationale des Autoroutes du Maroc (ADM). L'objectif est d'étendre les fonctionnalités de Zabbix en automatisant des tâches d'administration système, de remédiation, de supervision et de gestion d'infrastructure sous Linux et Windows.

---

## Fonctionnalités

Le projet comprend les mécanismes suivants :

- Actions manuelles exécutées depuis Zabbix.
- Remédiation automatique (Self-Healing).
- Supervision des services Linux et Windows.
- Génération automatique de rapports de diagnostic.
- Synchronisation centralisée des scripts d'administration.
- Déploiement d'un proxy Zabbix.
- Synchronisation temporelle de l'infrastructure (NTP).

---

## Tickets réalisés

### Administration Linux

- Création d'utilisateurs Linux depuis une action manuelle Zabbix.
- Extension automatique du volume logique `/var`.
- Nettoyage automatique des journaux d'audit.
- Supervision de l'espace utilisé par `/var/log/audit`.
- Synchronisation automatique des scripts Linux avec `rsync`, `SSH` et `cron`.

### Supervision et remédiation

- Redémarrage automatique du service Apache.
- Génération automatique d'un rapport de diagnostic Apache.
- Déploiement du serveur Web IIS.
- Supervision automatique du service IIS.
- Redémarrage automatique des services Windows.

### Infrastructure

- Déploiement d'un proxy Zabbix.
- Mise en place d'une architecture NTP centralisée.

---

## Structure du dépôt

```text
zabbix-automation-toolkit/
│
├── README.md
├── LICENSE
│
├── linux/
│   ├── create_user.sh
│   ├── increase_var.sh
│   ├── clean_audit.sh
│   ├── audit_size.sh
│   ├── apache_restart.sh
│   ├── apache_diagnosis.sh
│   └── sync_scripts.sh
│
├── windows/
│   └── restart_service.bat
│
└── screenshots/
```

---

## Technologies utilisées

- Zabbix Server 7.0 LTS
- Rocky Linux 8.10
- Windows Server 2016
- Apache HTTP Server
- IIS
- PostgreSQL
- SQLite
- VirtualBox
- Bash
- PowerShell
- rsync
- SSH
- cron
- Chrony (NTP)

---

## Description des scripts

## Scripts &  Descriptions
-create_user.sh : Création d'un utilisateur Linux via une action manuelle Zabbix.

-increase_var.sh : Extension automatique du volume logique `/var`. 

-clean_audit.sh : Nettoyage automatique des fichiers de test présents dans `/var/log/audit`.

-audit_size.sh : Retourne la taille du répertoire d'audit pour la supervision Zabbix.

-apache_restart.sh : Redémarrage automatique du service Apache. 

-apache_diagnosis.sh : Génération d'un rapport de diagnostic lors d'une panne Apache. 

-sync_scripts.sh : Synchronisation des scripts Linux entre le serveur Zabbix et les autres machines via rsync. 

-restart_service.bat : Redémarrage automatique d'un service Windows supervisé par Zabbix. 


## Déploiement

Pour chaque script :

1. Copier le script sur la machine cible.
2. Accorder les permissions d'exécution.
3. Configurer les privilèges nécessaires (`sudo`, `SSH`, etc.).
4. Créer le script dans Zabbix.
5. Associer le script à une action manuelle ou automatique.
6. Tester le bon fonctionnement.

Les configurations spécifiques à chaque script sont détaillées directement dans les commentaires du script concerné.

---

## Auteur
MAALIM MOHAMED ZAKARIA
Projet réalisé durant un stage technique à la Société Nationale des Autoroutes du Maroc (ADM).
