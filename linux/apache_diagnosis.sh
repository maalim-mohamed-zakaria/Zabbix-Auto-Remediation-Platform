#!/bin/bash
LOGFILE="/opt/zabbix/reports/apache_diagnosis.log"

echo "===============================================================" >> "$LOGFILE"
echo "                APACHE AUTO DIAGNOSIS REPORT" >> "$LOGFILE"
echo "===============================================================" >> "$LOGFILE"

echo "DATE      : $(date)" >> "$LOGFILE"
echo "HOSTNAME  : $(hostname)" >> "$LOGFILE"
echo "IP ADDRESS: $(hostname -I | awk '{print $1}')" >> "$LOGFILE"

echo "" >> "$LOGFILE"

###############################################################
#                        SUMMARY
###############################################################

STATUS=$(systemctl is-active httpd)
CONFIG=$(httpd -t 2>&1)

if echo "$CONFIG" | grep -q "Syntax OK"; then
CONFIG_STATUS="OK"
else
CONFIG_STATUS="ERROR"
fi

if ss -tulpn | grep -q ":80"; then
PORT80="LISTENING"
else
PORT80="CLOSED"
fi

echo "=============================SUMMARY=============================" >> "$LOGFILE"
echo "APACHE STATUS : $STATUS" >> "$LOGFILE"
echo "CONFIGURATION : $CONFIG_STATUS" >> "$LOGFILE"
echo "PORT 80       : $PORT80" >> "$LOGFILE"

###############################################################
# HTTPD SERVICE STATUS
###############################################################

echo "========================HTTPD SERVICE STATUS=====================" >> "$LOGFILE"
sudo systemctl status httpd --no-pager >> "$LOGFILE" 2>&1
echo "" >> "$LOGFILE"

###############################################################
# HTTPD JOURNAL
###############################################################
echo "===========================HTTPD JOURNAL=========================" >> "$LOGFILE"
sudo journalctl -u httpd -n 50 --no-pager >> "$LOGFILE" 2>&1
echo "" >> "$LOGFILE"

###############################################################
# HTTPD ERROR LOG
###############################################################

echo "==========================HTTPD ERROR LOG========================" >> "$LOGFILE"
if [ -f /var/log/httpd/error_log ]; then
sudo tail -50 /var/log/httpd/error_log >> "$LOGFILE"
else
echo "Apache error log not found."
fi
echo "" >> "$LOGFILE"

###############################################################
# PORT 80 STATUS
###############################################################

echo "============================PORT 80 STATUS=======================" >> "$LOGFILE"
ss -tulpn | grep ":80" >> "$LOGFILE" 2>&1
echo "" >> "$LOGFILE"

###############################################################
# HTTPD PROCESS
###############################################################

echo "===========================HTTPD PROCESS=========================" >> "$LOGFILE"
ps -ef | grep httpd | grep -v grep >> "$LOGFILE"
echo "" >> "$LOGFILE"

###############################################################
# SYSTEM ERRORS
###############################################################

echo "===========================SYSTEM ERRORS=========================" >> "$LOGFILE"
sudo journalctl -p err -n 30 --no-pager >> "$LOGFILE" 2>&1
echo "" >> "$LOGFILE"

###############################################################
# DISK SPACE
###############################################################

echo "=============================DISK SPACE==========================" >> "$LOGFILE"
df -h / >> "$LOGFILE"
echo "" >> "$LOGFILE"

df -h /var >> "$LOGFILE"
echo "" >> "$LOGFILE"

echo "===========================END OF REPORT=========================" >> "$LOGFILE"
logger -t apache_diagnosis "Diagnosis is done"
