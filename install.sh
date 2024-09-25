#!/bin/bash
cp ./check-to-shutdownvms.sh /usr/bin/ && chmod 744 /usr/bin/check-to-shutdownvms.sh
cp ./shutdownvms.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable shutdownvms
systemctl start shutdownvms
systemctl status shutdownvms
exit 0
