# Zabbix Auto-Remediation

## Présentation

Ce dépôt regroupe les scripts d'automatisation développés lors de mon stage technique à la Société Nationale des Autoroutes du Maroc (ADM). Ils permettent d'étendre les fonctionnalités de Zabbix grâce à des mécanismes de remédiation automatique, d'administration système et de supervision sous Linux et Windows.


## Fonctionnalités

Le projet comprend les mécanismes suivants :

- Création d'utilisateurs Linux via une action manuelle Zabbix.
- Extension automatique du volume logique `/var`.
- Nettoyage automatique des journaux d'audit.
- Supervision de l'espace utilisé par `/var/log/audit`.
- Redémarrage automatique du service Apache.
- Génération automatique d'un rapport de diagnostic Apache.
- Déploiement et supervision du serveur Web IIS.
- Remédiation automatique des services Windows.
- Déploiement d'un proxy Zabbix.
- Mise en place d'une architecture NTP centralisée.

---

## Structure du dépôt

```text
zabbix-auto-remediation/
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
│   └── apache_diagnosis.sh
│
├── windows/
│   └── restart_service.bat
