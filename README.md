# Supervision intelligente avec Zabbix : détection proactive et remédiation automatisée


## Présentation

Ce dépôt regroupe l'ensemble des scripts, configurations et procédures d'implémentation développés dans le cadre d'un projet de supervision, d'automatisation et de remédiation automatique basé sur **Zabbix 7.0 LTS**.

L'objectif est de fournir une documentation technique permettant à un administrateur système de reproduire les différentes automatisations mises en œuvre sur une nouvelle infrastructure. Chaque ticket décrit les étapes d'implémentation, les commandes utilisées, les configurations Zabbix nécessaires ainsi que les scripts associés.

Les solutions implémentées couvrent notamment :

- Création manuelle d'utilisateurs Linux depuis l'interface Zabbix ;
- Extension automatique du volume logique `/var` ;
- Nettoyage automatique du répertoire `/var/log/audit` ;
- Surveillance du répertoire d'audit ;
- Diagnostic automatique du serveur Apache ;
- Redémarrage automatique du serveur Apache ;
- Déploiement et supervision du serveur IIS sous Windows ;
- Remédiation automatique des services Windows ;
- Synchronisation centralisée des scripts Linux.

---

# Environnement de test

Les automatisations ont été développées et validées sur l'environnement suivant :

| Composant | Version |
|------------|---------|
| Zabbix Server | 7.0 LTS |
| Zabbix Proxy | 7.0 LTS |
| Zabbix Agent | 7.0 LTS |
| Rocky Linux | 8.10 |
| Rocky Linux CIS | 8.10 (CIS Level 2) |
| Windows Server | 2016 |
| PostgreSQL | 16 |
| Apache HTTP Server | 2.4 |
| IIS | Internet Information Services |
| Chrony | NTP |
| rsync | Synchronisation des scripts |

---

# Architecture

Le projet est composé des machines suivantes :

| Machine | Rôle |
|----------|------|
| Zabbix Server | Supervision, automatisation, serveur NTP et référentiel central des scripts |
| Rocky Linux CIS | Hôte Linux supervisé |
| Rocky Linux Proxy | Proxy Zabbix pour la supervision distante |
| Windows Server 2016 | Hôte Windows supervisé |

Les scripts Linux sont centralisés sur le serveur Zabbix dans le répertoire :

```bash
/opt/zabbix/scripts
```
---

# Prérequis

Avant de mettre en œuvre les automatisations décrites dans ce dépôt, les éléments suivants doivent être opérationnels :

- Zabbix Server installé et configuré ;
- Zabbix Agent installé sur les machines supervisées ;
- Zabbix Proxy installé (si utilisé) ;
- Les hôtes doivent être enregistrés dans Zabbix ;
- Les Templates Zabbix appropriés doivent être associés aux hôtes ;
- Les scripts Linux doivent être présents dans le répertoire :

```bash
/opt/zabbix/scripts
```

- Les scripts doivent disposer des droits d'exécution :

```bash
sudo chown root:zabbix /opt/zabbix/scripts/script.sh
sudo chmod 750 /opt/zabbix/scripts/script.sh
```

- Les permissions `sudo` nécessaires doivent être configurées pour l'utilisateur `zabbix`.
- Les Actions Zabbix doivent être autorisées à exécuter des scripts sur les hôtes concernés.
- Pour les scripts Windows, le paramètre suivant doit être activé dans le fichier `zabbix_agentd.conf` :

```text
AllowKey=system.run[*]
```

Puis redémarrer l'agent :

```powershell
sudo systemctl start Zabbix Agent
```

---

# Principe de fonctionnement

Toutes les automatisations présentées dans ce dépôt reposent sur le même principe de fonctionnement :

```
Détection (Item)
        │
        ▼
Trigger Zabbix
        │
        ▼
Action Zabbix
        │
        ▼
Exécution d'un script ou d'une commande
        │
        ▼
Remédiation automatique
        │
        ▼
Résolution du Trigger
```

Les sections suivantes décrivent en détail la procédure d'implémentation de chaque ticket, les commandes à exécuter, les configurations Zabbix à réaliser ainsi que les scripts utilisés.

# Automatisations réalisées

# A-Manual Action - Create Linux User

## Objectif

Créer un utilisateur Linux directement depuis l'interface Zabbix grâce à une **Manual Host Action**, sans ouvrir de session SSH sur la machine cible.

---

## Procédure d'implémentation

### 1. Configurer les permissions sudo

Éditer le fichier `sudoers` :

```bash
sudo visudo
```

Ajouter la règle suivante :

```text
zabbix ALL=(ALL) NOPASSWD: /usr/sbin/useradd
```

Vérifier que l'utilisateur `zabbix` peut exécuter la commande :

```bash
sudo -u zabbix sudo /usr/sbin/useradd testuser
```

Supprimer ensuite l'utilisateur de test :

```bash
sudo userdel testuser
```

---

### 2. Créer le Global Script

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

Configurer une expression régulière pour valider le nom de l'utilisateur :

```text
^[a-z_][a-z0-9_-]{2,31}$
```

Ajouter le message de confirmation :

```text
Create Linux user "{MANUALINPUT}" ?
```

---

### 3. Tester la fonctionnalité

Depuis l'interface Zabbix :

```
Monitoring
→ Hosts
→ <Nom de l'hôte Linux>
→ Scripts
→ Create Linux User
```

Saisir un nom d'utilisateur valide puis confirmer l'exécution.

---

### 4. Vérifier la création de l'utilisateur

Sur la machine Linux :

```bash
id <nom_utilisateur>
```

ou

```bash
grep <nom_utilisateur> /etc/passwd
```

L'utilisateur doit apparaître dans la liste des comptes du système.

---

## Ressources

**Fonctionnalité Zabbix**

- Global Script
- Manual Host Action
- Zabbix Agent

**Commande utilisée**

```bash
/usr/sbin/useradd
```

---

## Résultat

L'administrateur peut créer un utilisateur Linux directement depuis l'interface Zabbix. Le nom de l'utilisateur est saisi au moment de l'exécution de l'action, puis transmis à la commande `useradd` via le Zabbix Agent, ce qui permet une création rapide sans connexion SSH.


# B-Automatic Increase of /var

## Objectif

Étendre automatiquement le volume logique `/var` de **2 Mo** lorsqu'un espace disque insuffisant est détecté par Zabbix.

---

## Procédure d'implémentation

### 1. Déployer le script

Copier le script sur la machine Linux :

```bash
sudo cp increase_var.sh /opt/zabbix/scripts/
```

---

### 2. Configurer les permissions sudo

Modifier le fichier `sudoers` :

```bash
sudo visudo
```

Ajouter les autorisations nécessaires à l'utilisateur `zabbix` :

```text
zabbix ALL=(ALL) NOPASSWD: /usr/sbin/lvextend
zabbix ALL=(ALL) NOPASSWD: /usr/sbin/xfs_growfs
```

> Si le système de fichiers est **ext4**, remplacer `xfs_growfs` par `resize2fs`.

---

### 3. Tester le script manuellement

Exécuter le script :

```bash
sudo /opt/zabbix/scripts/increase_var.sh
```

Vérifier que le volume logique a été étendu :

```bash
sudo lvs
```

Vérifier la nouvelle taille du système de fichiers :

```bash
df -h /var
```

---

### 4. Configurer le Trigger

Depuis l'interface Zabbix, créer un Trigger surveillant l'espace disponible sur `/var`.

Exemple d'expression :

```text
last(/Rocky-cis2/vfs.fs.size[/var,pfree])<15
```

Le Trigger passe à l'état **PROBLEM** lorsque l'espace libre devient inférieur à **15 %**.

---

### 5. Configurer l'Action

Depuis l'interface Zabbix :

```
Alerts
→ Actions
→ Trigger actions
→ Create action
```

Configurer une opération de type **Run script** exécutant :

```bash
sudo /opt/zabbix/scripts/increase_var.sh
```

Associer cette Action au Trigger créé précédemment.

---

### 6. Validation

Remplir temporairement la partition `/var` ou diminuer le seuil du Trigger afin de provoquer son déclenchement.

Lorsque le Trigger passe à l'état **PROBLEM** :

- le script est exécuté automatiquement ;
- le volume logique `/var` est étendu de 2 Mo ;
- le système de fichiers est redimensionné ;
- le Trigger revient automatiquement à l'état **RESOLVED**.

---

## Ressources

**Script**

```
linux/increase_var.sh
```

**Commandes utilisées**

- `lvextend`
- `xfs_growfs` (ou `resize2fs`)
- `df`
- `lvs`

**Fonctionnalités Zabbix**

- Trigger
- Action
- Zabbix Agent

---

## Résultat

Lorsque l'espace disponible sur la partition `/var` devient inférieur au seuil défini, Zabbix exécute automatiquement le script `increase_var.sh`. Celui-ci étend le volume logique de **2 Mo**, redimensionne le système de fichiers, puis le Trigger revient automatiquement à l'état **RESOLVED** sans intervention de l'administrateur.

## C-Automatic Audit Cleanup

## Objectif

Supprimer automatiquement tous les fichiers présents dans le répertoire `/var/log/audit`, à l'exception du fichier `audit.log`, lorsqu'un Trigger Zabbix est déclenché afin de libérer de l'espace disque.

---

## Procédure d'implémentation

### 1. Déployer le script

Copier le script sur la machine Linux :

```bash
sudo cp clean_audit.sh /opt/zabbix/scripts/
```

---

### 2. Configurer les permissions sudo

Modifier le fichier `sudoers` :

```bash
sudo visudo
```

Ajouter les autorisations suivantes :

```text
zabbix ALL=(ALL) NOPASSWD: /usr/bin/find
zabbix ALL=(ALL) NOPASSWD: /usr/bin/rm
zabbix ALL=(ALL) NOPASSWD: /usr/bin/logger
```

Vérifier les chemins des commandes :

```bash
which find
which rm
which logger
```

---

### 3. Tester le script manuellement

Créer quelques fichiers de test :

```bash
sudo touch /var/log/audit/test.log
sudo touch /var/log/audit/debug.log
sudo touch /var/log/audit/old.log
```

Vérifier le contenu du répertoire :

```bash
ls -l /var/log/audit
```

Exécuter le script :

```bash
sudo /opt/zabbix/scripts/clean_audit.sh
```

Vérifier le résultat :

```bash
ls -l /var/log/audit
```

Seul le fichier **audit.log** doit être conservé.

---

### 4. Configurer le Trigger

Créer un Trigger surveillant l'espace disponible sur la partition contenant le répertoire `/var/log/audit`.

Lorsque le seuil défini est atteint, le Trigger passe à l'état **PROBLEM**.

---

### 5. Configurer l'Action

Depuis l'interface Zabbix :

```
Alerts
→ Actions
→ Trigger actions
→ Create action
```

Créer une opération de type **Run script** exécutant :

```bash
sudo /opt/zabbix/scripts/clean_audit.sh
```

Associer cette Action au Trigger créé précédemment.

---

### 6. Validation

Déclencher le Trigger en simulant un manque d'espace disque ou en abaissant temporairement son seuil.

Lorsque le Trigger passe à l'état **PROBLEM** :

- le script est exécuté automatiquement ;
- tous les fichiers du répertoire `/var/log/audit`, à l'exception de `audit.log`, sont supprimés ;
- un message est enregistré dans les journaux système.

Vérifier le journal :

```bash
journalctl | grep "Zabbix cleaned audit logs automatically"
```

---

## Ressources

**Script**

```
linux/clean_audit.sh
```

**Commandes utilisées**

- `find`
- `rm`
- `logger`
- `journalctl`

**Fonctionnalités Zabbix**

- Trigger
- Action
- Zabbix Agent

---

## D-Apache Auto Restart

## Objectif

Redémarrer automatiquement le serveur Apache lorsqu'un arrêt du service `httpd` est détecté par Zabbix.

---

## Procédure d'implémentation

### 1. Déployer le script

Copier le script sur la machine Linux :

```bash
sudo cp apache_restart.sh /opt/zabbix/scripts/
```

---

### 2. Configurer les permissions sudo

Modifier le fichier `sudoers` :

```bash
sudo visudo
```

Ajouter la règle suivante :

```text
zabbix ALL=(ALL) NOPASSWD: /bin/systemctl restart httpd
```

Vérifier le chemin de la commande :

```bash
which systemctl
```

---

### 3. Tester le script manuellement

Arrêter le service Apache :

```bash
sudo systemctl stop httpd
```

Exécuter le script :

```bash
sudo /opt/zabbix/scripts/apache_restart.sh
```

Vérifier que le service est redémarré :

```bash
systemctl status httpd
```

Le service doit être dans l'état :

```text
active (running)
```

---

### 4. Configurer le Trigger

Créer un Trigger détectant l'arrêt du service Apache.

Exemple :

```
Apache service is not running
```

Lorsque le service est arrêté, le Trigger passe à l'état **PROBLEM**.

---

### 5. Configurer l'Action

Depuis l'interface Zabbix :

```
Alerts
→ Actions
→ Trigger actions
→ Create action
```

Créer une opération de type **Run script** exécutant :

```bash
sudo /opt/zabbix/scripts/apache_restart.sh
```

Associer cette Action au Trigger correspondant.

---

### 6. Validation

Arrêter le service Apache :

```bash
sudo systemctl stop httpd
```

Vérifier dans Zabbix que le Trigger passe à l'état **PROBLEM**.

Après quelques secondes, confirmer que :

```bash
systemctl status httpd
```

retourne :

```text
active (running)
```

Vérifier également que le Trigger est revenu à l'état **RESOLVED**.

---

## Ressources

**Script**

```
linux/apache_restart.sh
```

**Commandes utilisées**

- `systemctl stop httpd`
- `systemctl restart httpd`
- `systemctl status httpd`

**Fonctionnalités Zabbix**

- Trigger
- Action
- Zabbix Agent

---

## Résultat

Lorsqu'un arrêt du service Apache est détecté, Zabbix exécute automatiquement le script `apache_restart.sh`, qui redémarre le service `httpd`. Une fois le service rétabli, le Trigger revient automatiquement à l'état **RESOLVED**, assurant ainsi la continuité du service sans intervention de l'administrateur.

## E-Apache Automatic Diagnosis

## Objectif

Collecter automatiquement les principales informations de diagnostic lorsqu'un dysfonctionnement du serveur Apache est détecté par Zabbix, afin de faciliter l'analyse de la panne avant toute intervention.

---

## Procédure d'implémentation

### 1. Déployer le script

Copier le script sur la machine Linux :

```bash
sudo cp apache_diagnosis.sh /opt/zabbix/scripts/
```


---

### 2. Configurer les permissions sudo

Modifier le fichier sudoers :

```bash
sudo visudo
```

Ajouter les autorisations nécessaires :

```text
zabbix ALL=(ALL) NOPASSWD: /bin/systemctl
zabbix ALL=(ALL) NOPASSWD: /usr/bin/journalctl
zabbix ALL=(ALL) NOPASSWD: /usr/sbin/httpd
```

Vérifier les chemins des commandes :

```bash
which systemctl
which journalctl
which httpd
```

---

### 3. Tester le script manuellement

Arrêter le service Apache :

```bash
sudo systemctl stop httpd
```

Exécuter le script :

```bash
sudo /opt/zabbix/scripts/apache_diagnosis.sh
```

Consulter le rapport généré :

```bash
cat /tmp/apache_diagnosis.log
```

---

### 4. Configurer le Trigger

Créer un Trigger détectant l'indisponibilité du serveur Apache (par exemple via le scénario Web ou le contrôle du service).

Lorsque le Trigger passe à l'état **PROBLEM**, le diagnostic est lancé automatiquement.

---

### 5. Configurer l'Action

Depuis l'interface Zabbix :

```
Alerts
→ Actions
→ Trigger actions
→ Create action
```

Créer une opération de type **Run script** exécutant :

```bash
sudo /opt/zabbix/scripts/apache_diagnosis.sh
```

Associer cette Action au Trigger correspondant.

---

### 6. Validation

Arrêter le service Apache :

```bash
sudo systemctl stop httpd
```

Déclencher le Trigger puis vérifier que le fichier de diagnostic a été créé :

```bash
ls -l /tmp/apache_diagnosis.log
```

Afficher son contenu :

```bash
cat /tmp/apache_diagnosis.log
```

Le rapport doit contenir les informations collectées sur l'état du serveur Apache.

---

## Ressources

**Script**

```
linux/apache_diagnosis.sh
```

**Commandes utilisées**

- `systemctl`
- `journalctl`
- `httpd -t`
- `cat`

**Fonctionnalités Zabbix**

- Trigger
- Action
- Zabbix Agent

---

## Résultat

Lorsqu'une panne du serveur Apache est détectée, Zabbix exécute automatiquement le script `apache_diagnosis.sh`, qui génère un rapport de diagnostic contenant les principales informations nécessaires à l'analyse de l'incident. Ce rapport peut ensuite être consulté par l'administrateur afin d'identifier rapidement l'origine du dysfonctionnement.






## F-Windows Service Monitoring

## Objectif

Superviser automatiquement les services Windows à l'aide de Zabbix et redémarrer automatiquement un service lorsqu'il est arrêté. Dans ce projet, cette fonctionnalité est appliquée au service **W3SVC (World Wide Web Publishing Service)** du serveur IIS.

---

## Procédure d'implémentation

### 1. Associer le Template Windows

Depuis l'interface Zabbix :

```
Data collection
→ Hosts
→ Windows Server
→ Templates
```

Associer le template :

```
Windows by Zabbix agent
```

Enregistrer les modifications.

---

### 2. Vérifier la découverte automatique des services

Depuis l'interface Zabbix :

```
Data collection
→ Hosts
→ Windows Server
→ Discovery
```

Vérifier que la règle de découverte suivante est activée :

```
Windows services discovery
```

Après quelques minutes, le service **W3SVC** est découvert automatiquement.

L'item suivant est créé automatiquement :

```
service.info["W3SVC",state]
```

Le Trigger suivant est également créé automatiquement :

```
Windows: "{#SERVICE.NAME}" is not running
```

---

### 3. Autoriser l'exécution des commandes distantes

Modifier le fichier :

```text
C:\Program Files\Zabbix Agent\zabbix_agentd.conf
```

Ajouter ou décommenter la ligne suivante :

```text
AllowKey=system.run[*]
```

Redémarrer ensuite le service Zabbix Agent :

```powershell
Restart-Service "Zabbix Agent"
```

---

### 4. Configurer l'Action Zabbix

Depuis l'interface Zabbix :

```
Alerts
→ Actions
→ Trigger actions
→ Create action
```

Créer une nouvelle Action associée aux Triggers des services Windows.

Ajouter une opération de type **Run script** exécutant la commande suivante :

```cmd
sc start "{EVENT.TAGS.service}"
```

Configurer la condition de l'Action afin d'utiliser le tag :

```
service
```

Cette configuration permet de rendre la solution générique et de redémarrer automatiquement tout service Windows supervisé possédant ce tag.

---

### 5. Validation

Arrêter le service IIS :

```cmd
sc stop W3SVC
```

Vérifier dans Zabbix que le Trigger passe à l'état **PROBLEM**.

Quelques secondes plus tard, vérifier que le service a été redémarré :

```cmd
sc query W3SVC
```

Le résultat attendu est :

```text
STATE : 4 RUNNING
```

Le Trigger doit ensuite revenir automatiquement à l'état **RESOLVED**.

---

## Ressources

**Template**

```
Windows by Zabbix agent
```

**Règle de découverte**

```
Windows services discovery
```

**Item découvert**

```
service.info["W3SVC",state]
```

**Trigger découvert**

```
Windows: "{#SERVICE.NAME}" is not running
```

**Commande utilisée**

```cmd
sc start
```

**Fonctionnalités Zabbix**

- Low-Level Discovery (LLD)
- Trigger
- Trigger Action
- Event Tags

---

## Résultat

Grâce au mécanisme de **Low-Level Discovery**, Zabbix découvre automatiquement les services Windows et crée les éléments de supervision associés. Lorsqu'un service supervisé est arrêté, le Trigger passe à l'état **PROBLEM** et l'Action exécute automatiquement la commande de redémarrage. L'utilisation du tag **service** permet de réutiliser la même Action pour tous les services Windows supervisés, sans configuration spécifique pour chacun.

## G-Windows Automatic Service Restart

## Objectif

Redémarrer automatiquement un service Windows lorsqu'un arrêt est détecté par Zabbix. Cette implémentation repose sur les Trigger générés par la découverte automatique des services Windows et permet de rétablir le service sans intervention de l'administrateur.

---

## Procédure d'implémentation

### 1. Autoriser l'exécution des commandes distantes

Modifier le fichier de configuration du Zabbix Agent :

```text
C:\Program Files\Zabbix Agent\zabbix_agentd.conf
```

Ajouter ou décommenter la ligne suivante :

```text
AllowKey=system.run[*]
```

Redémarrer ensuite le service Zabbix Agent :

```powershell
Restart-Service "Zabbix Agent"
```

---

### 2. Créer une Trigger Action

Depuis l'interface Zabbix :

```
Alerts
→ Actions
→ Trigger actions
→ Create action
```

Créer une nouvelle Action associée aux Triggers de supervision des services Windows.

---

### 3. Configurer les conditions

Configurer l'Action pour qu'elle s'exécute uniquement lorsque le Trigger détecte l'arrêt d'un service Windows.

Utiliser le tag :

```text
service
```

afin de récupérer automatiquement le nom du service concerné.

---

### 4. Configurer l'opération

Ajouter une opération de type **Run script**.

Commande exécutée :

```cmd
sc start "{EVENT.TAGS.service}"
```

Cette commande démarre automatiquement le service dont le nom est transmis par le tag de l'événement.

---

### 5. Validation

Arrêter le service IIS ( ou un autre service pour le test):

```cmd
sc stop W3SVC
```

Vérifier dans Zabbix que le Trigger passe à l'état **PROBLEM**.

Quelques secondes plus tard, contrôler que le service est de nouveau actif :

```cmd
sc query W3SVC
```

Le résultat attendu est :

```text
STATE : 4 RUNNING
```

Le Trigger doit ensuite revenir automatiquement à l'état **RESOLVED**.

---

## Ressources

**Commande utilisée**

```cmd
sc start
```

**Fonctionnalités Zabbix**

- Trigger Actions
- Event Tags
- Remote Commands
- Zabbix Agent

---

## Résultat

Lorsqu'un service Windows supervisé est arrêté, Zabbix exécute automatiquement la commande `sc start` afin de redémarrer le service concerné. Grâce à l'utilisation du tag **service**, la même Action peut être réutilisée pour tout service Windows découvert par Zabbix, sans créer d'Action spécifique pour chaque service.

## H. # Centralized Script Synchronization

## Objectif

Centraliser les scripts d'administration Linux sur le serveur Zabbix et faciliter leur déploiement sur les autres machines Linux de l'infrastructure. Le script `rsync_expect.sh` automatise la synchronisation en demandant les informations de connexion des hôtes distants, puis exécute directement le transfert des scripts à l'aide de `rsync`.

---

## Procédure d'implémentation
## Prérequis
 le rsync doit être installé sur toutes les machines concérnées par la synchronisation

### 1. Déployer le script

Le fichier du script est créé sur le serveur Zabbix dans le répertoire puis y copier le contenu de linux/rsync_expect:

```bash
/opt/zabbix/scripts/rsync_expect.sh
```


---

### 2. Exécuter le script

Lancer le script :

```bash
sudo /opt/zabbix/scripts/rsync_expect.sh
```

Le script demande successivement les informations suivantes :

- Adresse IP de la machine distante ;
- Nom d'utilisateur ;
- Mot de passe d'utilisateur.

Après validation, le script lance automatiquement la synchronisation des scripts présents dans le répertoire :

```bash
/opt/scripts/
```

vers la machine distante.

---

### 3. Vérifier la synchronisation

Après l'exécution du script, vérifier que les fichiers ont bien été copiés.

Sur la machine distante :

```bash
ls -l /opt/scripts
```

Comparer ensuite le contenu avec celui du serveur :

```bash
ls -l /opt/scripts
```

Les deux répertoires doivent contenir les mêmes scripts.

---

### 4. Validation

Modifier un script sur le serveur Zabbix.

Par exemple :

```bash
echo "# Test synchronization" >> /opt/zabbix/scripts/test.sh
```

Relancer le script :

```bash
sudo /opt/zabbix/scripts/rsync_expect.sh
```

Puis vérifier sur la machine distante :

```bash
cat /opt/zabbix/scripts/test.sh
```

La modification doit être présente, confirmant le bon fonctionnement de la synchronisation.

---

## Ressources

**Script**

```
linux/rsync_expect.sh
```

**Commandes utilisées**

- `rsync`
- `ssh`
- `expect`

---

## Résultat

Le script `rsync_expect.sh` automatise la synchronisation des scripts d'administration entre le serveur Zabbix et une machine Linux distante. Après avoir renseigné les paramètres de connexion, les scripts présents dans `/opt/zabbix/scripts` sont transférés automatiquement vers la machine cible, garantissant ainsi que les deux systèmes disposent de la même version des scripts.


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
- rsync
- Chrony
- VirtualBox

# Auteur
MAALIM MOHAMED ZAKARIA

Projet réalisé dans le cadre d'un stage technique à la Société Nationale des Autoroutes du Maroc (ADM).

