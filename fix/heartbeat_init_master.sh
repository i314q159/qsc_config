#!/usr/bin/env bash

heartbeat_init() {
    if [ -e "/home/admin1/heartbeat.zip" ]; then
        unzip -q -o /home/admin1/heartbeat.zip -d /home/admin1/
        chmod +x /home/admin1/heartbeat/*
        sudo chown -R admin1:admin1 /home/admin1/heartbeat/

        cat >/etc/systemd/system/heartbeat.service <<EOF
[Unit]
Description=Heart Beat Service
After=network.target
Wants=network.target

[Service]
Type=simple
User=admin1
Restart=always
RestartSec=1
WorkingDirectory=/home/admin1/heartbeat/
ExecStart=/home/admin1/heartbeat/heart_beat_amd64 client

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
