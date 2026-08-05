#!/bin/bash

echo "$(date) SCRIPT EXECUTED" >> /tmp/restart_test.log

sudo systemctl restart httpd

if sudo systemctl is-active --quiet httpd; then
    echo "Zabbix: Apache service restarted succesfully." >> /tmp/restart_test.log
    exit 0
else
    echo "Zabbix: Failed to restart Apache service." >> /tmp/restart_test.log
    exit 1
fi
