#!/usr/bin/env bash

# todesk 监控
todesk_monitor() {
	cat >/usr/local/bin/todesk_monitor.sh <<'EOF'
#!/usr/bin/env bash

LOG_FILE="/var/log/todesk_monitor.log"

SERVICE_NAME="todeskd.service"

CURRENT_TIME=$(date "+%Y-%m-%d %H:%M:%S")

SERVER_STATUS=$(systemctl is-active $SERVICE_NAME)
if [ "$SERVER_STATUS" != "active" ]; then
    echo "[$CURRENT_TIME] 警告: $SERVICE_NAME 服务未运行！状态: $SERVER_STATUS" >> "$LOG_FILE"
    systemctl restart $SERVICE_NAME
fi

EOF
	chmod +x /usr/local/bin/todesk_monitor.sh

	cat >/etc/systemd/system/todesk-monitor.service <<EOF
[Unit]
Description=ToDesk Process Monitor Service
After=network.target

[Service]
Type=oneshot
User=root
ExecStart=/usr/local/bin/todesk_monitor.sh

[Install]
WantedBy=multi-user.target
EOF

	cat >/etc/systemd/system/todesk-monitor.timer <<EOF
[Unit]
Description=Timer for ToDesk Process Monitor
After=network.target

[Timer]
OnBootSec=1min
OnUnitActiveSec=1min
Unit=todesk-monitor.service

[Install]
WantedBy=timers.target
EOF

	systemctl daemon-reload

	systemctl enable --now todesk-monitor.timer
}
todesk_monitor

# 开启 ssh 作为现场调试手段
enable_ssh() {
	apt install -y openssh-server
	systemctl enable --now ssh
}
enable_ssh
