#!/usr/bin/env bash

rviz_init() {
	if [ -e "/home/admin1/rviz.zip" ]; then
		sudo -u admin1 unzip -q -o /home/admin1/rviz.zip -d /home/admin1/
	fi
}
rviz_init
