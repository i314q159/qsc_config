#!/usr/bin/env bash

USER_NAME="admin"

# 磁盘清理
disk_cleaner() {
	cat >/usr/local/bin/disk_cleaner.sh <<EOF
#!/usr/bin/env bash

TRASH_DIR="/home/$USER_NAME/.local/share/Trash/"
ROS_LOG_DIR="/home/$USER_NAME/.ros/log/"

# 清理回收站
if [ -d "\$TRASH_DIR" ]; then
    rm -rf "\$TRASH_DIR"/*
    echo "\$(date '+%Y-%m-%d %H:%M:%S') 已清空回收站" >> /var/log/disk_cleaner.log
fi

# 清理ROS日志
if [ -d "\$ROS_LOG_DIR" ]; then
    rm -rf "\$ROS_LOG_DIR"/*
    echo "\$(date '+%Y-%m-%d %H:%M:%S') 已清空 ROS 日志" >> /var/log/disk_cleaner.log
fi

EOF

	chmod +x /usr/local/bin/disk_cleaner.sh

	cat >/etc/systemd/system/disk-cleaner.service <<EOF
[Unit]
Description=Disk Cleaner Service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/disk_cleaner.sh

[Install]
WantedBy=multi-user.target
EOF

	cat >/etc/systemd/system/disk-cleaner.timer <<EOF
[Unit]
Description=disk-cleaner.service

[Timer]
OnCalendar=*-*-* 00:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

	systemctl daemon-reload
	systemctl enable --now disk-cleaner.timer
}
disk_cleaner
