#!/usr/bin/env bash

# TODO 等固定url，并封装为下载函数
download_form_server() {
	if [ ! -e "/home/admin1/yixian.rviz" ]; then
		sudo -u admin1 wget http://jiqiren.zkzc123.com/avatar/1151335495146541056.rviz -O /home/admin1/yixian.rviz
	fi

	if [ ! -e "/home/admin1/stlink.zip" ]; then
		sudo -u admin1 wget http://jiqiren.zkzc123.com/avatar/1151335667935088640.zip -O /home/admin1/stlink.zip
	fi

	if [ ! -e "/home/admin1/en.stm32cubeprg-lin-v2-17-0.zip" ]; then
		sudo -u admin1 wget http://jiqiren.zkzc123.com/avatar/1151336423274713088.zip -O /home/admin1/en.stm32cubeprg-lin-v2-17-0.zip
	fi

	if [ ! -e "/home/admin1/todesk-v4.7.2.0-amd64.deb" ]; then
		sudo -u admin1 wget http://jiqiren.zkzc123.com/avatar/1151336623494008832.deb -O /home/admin1/todesk-v4.7.2.0-amd64.deb
	fi

	# heartbeat
	# 2026-1-26
	local heartbeat_url="http://jiqiren.zkzc123.com/avatar/1175777691220185088.zip"
	if [ ! -e "/home/admin1/heartbeat.zip" ]; then
		sudo -u admin1 wget $heartbeat_url -O /home/admin1/heartbeat.zip
	fi

	# qsc_ws
	# 2026-1-22
	local qsc_master_url="http://jiqiren.zkzc123.com/avatar/1174131561864499200.zip"
	if [ ! -e "/home/admin1/qsc_master.zip" ]; then
		sudo -u admin1 wget $qsc_master_url -O /home/admin1/qsc_master.zip
	fi

	# pack
	# 2026-1-27
	local pack_url="http://jiqiren.zkzc123.com/avatar/1175989733671702528.zip"
	if [ ! -e "/home/admin1/pack.zip" ]; then
		sudo -u admin1 wget $pack_url -O /home/admin1/pack.zip
	fi

	# li_test
	# 2026-1-27
	local li_test_url="http://jiqiren.zkzc123.com/avatar/1175990604300161024.zip"
	if [ ! -e "/home/admin1/li_test.zip" ]; then
		sudo -u admin1 wget $li_test_url -O /home/admin1/li_test.zip
	fi

}
# download_form_server
