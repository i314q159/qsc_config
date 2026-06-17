#!/usr/bin/env bash

heartbeat_init() {
    if [ -e "/home/admin/heartbeat.zip" ]; then
        unzip -q -o /home/admin/heartbeat.zip -d /home/admin/
        chmod +x /home/admin/heartbeat/*
        sudo chown -R admin:admin /home/admin/heartbeat/

        cat >/etc/systemd/system/heartbeat.service <<EOF
[Unit]
Description=Heart Beat Service
After=network.target
Wants=network.target

[Service]
Type=simple
User=admin
WorkingDirectory=/home/admin/heartbeat/
ExecStart=/home/admin/heartbeat/heart_beat_arm64 server

[Install]
WantedBy=multi-user.target
EOF
        sudo systemctl daemon-reload

        sudo systemctl enable heartbeat.service
        sudo systemctl start heartbeat.service

    else
        echo "heartbeat.zip不在目录下"
    fi
}
heartbeat_init
