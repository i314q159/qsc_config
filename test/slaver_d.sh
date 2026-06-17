#!/usr/bin/env bash

# TODO 等固定url，并封装为下载函数
download_form_server() {
	if [ ! -e "/home/admin/todesk-v4.7.2.0-arm64.deb" ]; then
		sudo -u admin wget http://jiqiren.zkzc123.com/avatar/1151337042593058816.deb -O /home/admin/todesk-v4.7.2.0-arm64.deb
	fi

	if [ ! -e "/home/admin/camera_calibration.zip" ]; then
		sudo -u admin wget http://jiqiren.zkzc123.com/avatar/1176353858314702848.zip -O /home/admin/camera_calibration.zip
	fi

	if [ ! -e "/home/admin/heartbeat.zip" ]; then
		sudo -u admin wget http://jiqiren.zkzc123.com/avatar/1171312713159282688.zip -O /home/admin/heartbeat.zip
	fi

	# 2026-1-19
	local zip_url="http://jiqiren.zkzc123.com/avatar/1173043693645598720.zip"
	if [ ! -e "/home/admin/qsc_slaver.zip" ]; then
		sudo -u admin wget $zip_url -O /home/admin/qsc_slaver.zip
	fi

}
# download_form_server
