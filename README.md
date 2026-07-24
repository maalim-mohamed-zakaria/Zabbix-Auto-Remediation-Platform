# Zabbix Auto-Remediation

## Présentation

Ce dépôt regroupe l'ensemble des scripts, actions et mécanismes d'automatisation développés durant mon stage technique à la Société Nationale des Autoroutes du Maroc (ADM).

L'objectif du projet est d'améliorer l'administration des systèmes supervisés par Zabbix en développant des solutions de remédiation automatique (Self-Healing), des actions d'administration manuelles, des scripts de diagnostic, ainsi que des mécanismes de synchronisation et de supervision.

L'ensemble des développements a été réalisé sur une infrastructure virtuelle composée d'un serveur Zabbix, d'un serveur Windows, d'une machine Rocky Linux CIS Level 2 et d'un proxy Zabbix.

---

# Architecture

L'infrastructure est composée des éléments suivants :

- Zabbix Server 7.0 LTS (Rocky Linux 8.10)
- Rocky Linux 8.10 CIS Level 2
- Windows Server 2016
- Zabbix Proxy
- PostgreSQL
- Apache HTTP Server
- IIS
- Chrony
- rsync
- SSH
- cron

Le serveur Zabbix assure plusieurs rôles :

- Serveur de supervision
- Serveur Web Apache
- Base de données PostgreSQL
- Serveur NTP
- Référentiel central des scripts Linux

---

# Organisation du dépôt

```
zabbix-auto-remediation/
│
├── linux/
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
├── README.md
└── LICENSE
```

Tous les scripts Linux sont regroupés dans le dossier **linux/** tandis que les scripts Windows sont placés dans **windows/**.

---

# Tickets réalisés

## 1. Manual Action – Create Linux User
Objectif

Créer un utilisateur Linux directement depuis l'interface Zabbix sans ouvrir de session SSH sur la machine cible.

Prérequis
Zabbix Server et Zabbix Agent installés.
L'utilisateur zabbix doit être autorisé à exécuter la commande useradd via sudo.
Communication fonctionnelle entre le serveur et l'agent.
Implémentation
Configurer les permissions sudo permettant l'exécution de la commande useradd.
Créer un Global Script dans Zabbix.
Définir son type sur Manual Host Action.
Activer la saisie utilisateur afin de renseigner le nom du nouvel utilisateur.
Configurer une expression régulière afin de valider le format du nom d'utilisateur.
Associer l'action aux hôtes Linux concernés puis tester son fonctionnement.

Fichier concerné
Cette fonctionnalité est entièrement implémentée dans Zabbix et ne nécessite aucun script externe.

Résultat
L'administrateur peut créer un utilisateur Linux directement depuis l'interface Zabbix.


## 2. Automatic Increase of /var

Objectif

Étendre automatiquement le volume logique /var lorsqu'un manque d'espace est détecté.

Prérequis
Partition /var gérée par LVM.
Zabbix Agent installé.
Permissions sudo autorisant les commandes LVM.
Trigger détectant un faible espace disque.
Implémentation
Déployer le script increase_var.sh sur le serveur Linux.
Lui attribuer les permissions d'exécution.
Configurer les autorisations sudo nécessaires.
Créer un Trigger détectant un faible espace disponible.
Créer une Action Zabbix exécutant automatiquement le script.
Vérifier le fonctionnement en simulant un manque d'espace.

Fichier concerné
linux/increase_var.sh

Résultat
Lorsque le seuil critique est atteint, le volume logique est automatiquement agrandi sans intervention humaine.


## 3. Automatic Audit Cleanup

Objectif

Nettoyer automatiquement les fichiers de test présents dans /var/log/audit afin de libérer de l'espace disque.

Prérequis
Zabbix Agent installé.
Permissions sudo permettant la suppression des fichiers.
Trigger détectant un dépassement du seuil défini.
Implémentation
Copier le script clean_audit.sh sur la machine Linux.
Lui attribuer les droits d'exécution.
Configurer les permissions sudo.
Créer un Trigger surveillant la taille du répertoire d'audit.
Créer une Action Zabbix exécutant automatiquement le script.

Fichier concerné
linux/clean_audit.sh

Résultat
Les fichiers de test sont supprimés automatiquement et un journal d'exécution est généré.


## 4. Audit Directory Monitoring
Objectif

Surveiller la taille du répertoire /var/log/audit à l'aide d'un UserParameter personnalisé.

Prérequis
Zabbix Agent installé.
Autorisation sudo si nécessaire.
Configuration des UserParameters.
Implémentation
Déployer le script audit_size.sh.
Ajouter un UserParameter dans la configuration du Zabbix Agent.
Redémarrer le service Zabbix Agent.
Créer un Item utilisant la clé personnalisée.
Vérifier que la valeur remonte correctement dans Zabbix.
Fichier concerné
linux/audit_size.sh
Résultat

La taille du répertoire d'audit est disponible dans Zabbix et peut être utilisée par des Triggers.

## 5. Apache Auto Restart
Objectif

Redémarrer automatiquement Apache lorsqu'il est détecté comme arrêté.

Prérequis
Apache installé.
Zabbix Agent installé.
Permissions sudo permettant le redémarrage du service.
Trigger surveillant l'état du service.
Implémentation
Déployer le script apache_restart.sh.
Lui attribuer les droits d'exécution.
Configurer les permissions sudo.
Créer un Trigger détectant l'arrêt du service.
Configurer une Action Zabbix exécutant automatiquement le script.
Tester le mécanisme en arrêtant Apache.
Fichier concerné
linux/apache_restart.sh
Résultat

Le service Apache est automatiquement redémarré et le Trigger revient à l'état RESOLVED.


## 6. Apache Automatic Diagnosis

6. Apache Automatic Diagnosis
Objectif

Générer automatiquement un rapport de diagnostic lorsqu'un incident Apache est détecté.

Prérequis
Apache installé.
Accès aux journaux système.
Permissions permettant la lecture des fichiers de logs.
Implémentation
Déployer le script apache_diagnosis.sh.
Configurer les permissions d'exécution.
Définir un emplacement pour le fichier de diagnostic.
Associer le script à une Action Zabbix si nécessaire.
Vérifier que le rapport est correctement généré.

Fichier concerné
linux/apache_diagnosis.sh

Résultat
Un rapport contenant les principales informations de diagnostic est automatiquement généré afin de faciliter l'analyse de l'incident.


## 7. IIS Deployment

Objectif

Déployer le serveur Web IIS sur Windows Server afin de disposer d'un service supervisable.

Prérequis
Windows Server 2016.
Accès administrateur.
Pare-feu Windows configuré.
Implémentation
Installer le rôle Internet Information Services (IIS).
Autoriser le trafic HTTP dans le pare-feu Windows.
Vérifier le fonctionnement via un navigateur.
Tester l'accès depuis les autres machines du réseau.

Fichier concerné
Aucun script n'est nécessaire.

Résultat
Le serveur IIS est accessible et prêt à être supervisé.



## 8. Windows Service Monitoring

Objectif

Superviser automatiquement les services Windows grâce aux mécanismes de découverte de Zabbix.

Prérequis
Zabbix Agent installé sur Windows.
Template Windows associé à l'hôte.
Implémentation
Associer le template Windows à l'hôte.
Activer la règle Windows Services Discovery.
Attendre la découverte automatique des services.
Vérifier la création automatique des Items et des Triggers.

Fichier concerné
Aucun script n'est nécessaire.

Résultat
Les services Windows sont découverts et supervisés automatiquement.


## 9. Windows Automatic Service Restart

Objectif

Redémarrer automatiquement un service Windows lorsqu'il est arrêté.

Prérequis
Zabbix Agent installé.
Autorisation system.run.
Action automatique configurée.
Implémentation
Déployer le script restart_service.bat.
Autoriser l'exécution de commandes via system.run.
Créer un Trigger détectant l'arrêt du service.
Configurer une Action Zabbix exécutant le script.
Vérifier le fonctionnement en arrêtant le service.

Fichier concerné
windows/restart_service.bat

Résultat
Le service Windows est automatiquement redémarré dès qu'il est détecté comme arrêté.

---

## 10. Zabbix Proxy Deployment

Objectif

Déployer un proxy Zabbix afin de superviser un segment réseau distant.

Prérequis
Rocky Linux.
Zabbix Proxy.
SQLite.
Connectivité avec le serveur Zabbix.
Implémentation
Installer Zabbix Proxy.
Initialiser la base SQLite.
Configurer le fichier zabbix_proxy.conf.
Démarrer le service.
Déclarer le proxy dans Zabbix.
Associer les hôtes au proxy.

Fichier concerné
Aucun script n'est nécessaire.

Résultat
Les hôtes associés sont supervisés via le proxy.

## 11. Centralized Script Synchronization

Objectif

Distribuer automatiquement les scripts Linux depuis un référentiel central vers les autres serveurs.

Prérequis
SSH par clés.
rsync.
cron.
Répertoire partagé des scripts.
Implémentation
Déployer le script sync_scripts.sh.
Configurer l'authentification SSH par clés.
Installer rsync.
Définir les machines destinataires.
Planifier l'exécution automatique avec cron.
Vérifier que toute modification est propagée automatiquement.

Fichier concerné
linux/sync_scripts.sh

Résultat
Tous les serveurs Linux disposent automatiquement de la même version des scripts.



## 12. NTP Infrastructure

Objectif

Synchroniser l'horloge de l'ensemble des machines de l'infrastructure.

Prérequis
Chrony installé.
Connectivité réseau.
Implémentation
Configurer le serveur Zabbix comme serveur NTP.
Configurer les autres machines comme clients NTP.
Redémarrer le service Chrony.
Vérifier la synchronisation avec chronyc sources ou timedatectl.

Fichier concerné
Aucun script n'est nécessaire.

Résultat
Toutes les machines utilisent la même référence de temps, garantissant la cohérence des journaux et des événements de supervision.



# Technologies utilisées

- Zabbix Server 7.0 LTS
- Zabbix Agent
- Zabbix Proxy
- Rocky Linux 8.10
- Rocky Linux 8.10 CIS Level 2
- Windows Server 2016
- Apache HTTP Server
- IIS
- PostgreSQL
- SQLite
- Bash
- Batch
- PowerShell
- SSH
- rsync
- cron
- Chrony
- VirtualBox

# Auteur
MAALIM MOHAMED ZAKARIA

Projet réalisé dans le cadre d'un stage technique à la Société Nationale des Autoroutes du Maroc (ADM).

