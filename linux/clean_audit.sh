#!/bin/bash
LOGDIR="/var/log/audit" 
find "SLOGDIR" -type f ! -name "audit. log" -exec rm -f ov:
logger -t audit_cleanup "Zabbix cleaned audit logs autmatically"
