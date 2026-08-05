#!/bin/bash

if lvextend -L +2M /dev/rl/var -y; then
    xfs_growfs /var
    logger -t increase_var "Zabbix automatically extended /var by 2MB"
else
    logger -t increase_var "Zabbix failed to extend /var //espace insuffisant// "
fi
