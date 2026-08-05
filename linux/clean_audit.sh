#!/bin/bash
LOGDIR="/var/log/audit" 
find "$LOGDIR" -type f ! -name "audit.log" -exec rm -f {} \;
logger -t audit_cleanup "Zabbix cleaned audit logs autmatically"
