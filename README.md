# Supervision intelligente avec Zabbix : détection proactive et remédiation automatisée

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

# Manual Action – Create Linux User

## Objectif

Créer un utilisateur Linux directement depuis l'interface Zabbix à l'aide d'une **Manual Host Action**, sans ouvrir de session SSH sur la machine cible.

---

## Procédure d'implémentation

### 1. Autoriser la création d'utilisateurs via sudo

Modifier le fichier sudoers :

```bash
sudo visudo
```

Ajouter la règle suivante :

```text
zabbix ALL=(ALL) NOPASSWD:/usr/sbin/useradd
```

Vérifier que la commande peut être exécutée par l'utilisateur `zabbix` :

```bash
sudo -u zabbix sudo /usr/sbin/useradd testuser
```

Supprimer ensuite l'utilisateur de test :

```bash
sudo userdel testuser
```

---

### 2. Créer le Global Script dans Zabbix

Depuis l'interface Zabbix :

```
Alerts
→ Scripts
→ Create script
```

Configurer les paramètres suivants :

| Paramètre | Valeur |
|-----------|--------|
| Name | Create Linux User |
| Scope | Manual host action |
| Type | Script |
| Execute on | Zabbix agent |
| Enable user input | Yes |
| Input type | String |

Commande à exécuter :

```bash
sudo /usr/sbin/useradd "{MANUALINPUT}"
```

Configurer une expression régulière afin de valider le nom de l'utilisateur :

```text
^[a-z_][a-z0-9_-]{2,31}$
```

Ajouter un message de confirmation avant l'exécution :

```text
Create Linux user "{MANUALINPUT}" ?
```

---

### 3. Tester le fonctionnement

Depuis l'interface Zabbix :

```
Monitoring
→ Hosts
→ <Linux Host>
→ Scripts
→ Create Linux User
```

Saisir un nom d'utilisateur valide puis confirmer l'exécution.

---

### 4. Vérifier la création de l'utilisateur

Sur la machine Linux :

```bash
id <username>
```

ou

```bash
cat /etc/passwd | grep <username>
```

L'utilisateur doit apparaître dans la liste des comptes du système.

---

## Ressources

Cette fonctionnalité ne nécessite **aucun script externe**.

Elle repose sur les éléments suivants :

- Global Script Zabbix
- Zabbix Agent
- Commande `useradd`
- Configuration `sudo`

---

## Résultat

L'administrateur peut créer un utilisateur Linux directement depuis l'interface Zabbix. La commande est exécutée par le Zabbix Agent sur l'hôte sélectionné, sans nécessiter de connexion SSH.


# Automatic Increase of /var

## Objectif

Étendre automatiquement le volume logique `/var` de 2 Mo lorsqu'un faible espace disque est détecté.

---

## Étapes de mise en œuvre

### 1. Déployer le script

Copier le script :

```bash
cp increase_var.sh /opt/scripts/
```

Attribuer les permissions :

```bash
chmod +x /opt/scripts/increase_var.sh
```

---

### 2. Configurer les permissions sudo

Modifier le fichier sudoers :

```bash
visudo
```

jouter les permissions nécessaires :

```text
zabbix ALL=(ALL) NOPASSWD:/usr/sbin/lvextend
zabbix ALL=(ALL) NOPASSWD:/usr/sbin/resize2fs
zabbix ALL=(ALL) NOPASSWD:/usr/sbin/xfs_growfs
```

> Adapter la commande de redimensionnement (`resize2fs` ou `xfs_growfs`) selon le système de fichiers utilisé.

---
### 3. Tester le script

```bash
sudo /opt/scripts/increase_var.sh
```

---

### 4. Configurer Zabbix

Créer un Trigger surveillant l'espace libre de `/var`.

Créer ensuite une Action exécutant automatiquement :

```bash
sudo /opt/scripts/increase_var.sh
```

lorsque le Trigger passe à l'état **PROBLEM**.

---

### 5. Validation

Vérifier la nouvelle taille :

```bash
df -h /var
```

Consulter l'historique des Actions dans Zabbix afin de confirmer la bonne exécution du script.

---

## Ressources

**Script**

```
linux/increase_var.sh
```

---

## Résultat

Le volume logique `/var` est automatiquement agrandi lorsque le seuil critique est atteint.


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

