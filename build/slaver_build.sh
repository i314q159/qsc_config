#!/usr/bin/env bash

# 用户名
USER_NAME="admin"

# qsc 工作空间名
QSC_WORKSPACE="/home/$USER_NAME/qsc_ws"

safe_remove() {
	local file_path="$1"

	local allowed_dir="/home/$USER_NAME/"

	local real_file
	real_file=$(realpath -m "${file_path}")

	if [[ "${real_file}" == "${allowed_dir}"* && -e "${file_path}" ]]; then
		rm -rf "${file_path}"
	fi
}

autostart() {
	mkdir -pv /home/$USER_NAME/.config/autostart

	if [ ! -e "/home/$USER_NAME/.config/autostart/slaver_startup.sh.desktop" ]; then
		cat >/home/$USER_NAME/.config/autostart/slaver_startup.sh.desktop <<EOF
[Desktop Entry]
Type=Application
Exec=/home/$USER_NAME/slaver_startup.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name[en_US]=qsc
Name=qsc
Comment[en_US]=
Comment=
EOF
	fi

	chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/.config/autostart/
}

qsc_slaver() {
	if [ -e "/home/$USER_NAME/qsc_ws" ]; then
		# 删除上一台车的编译产物
		safe_remove "$QSC_WORKSPACE/build/"
		safe_remove "$QSC_WORKSPACE/devel/"

		# 编译主程序
		source /opt/ros/noetic/setup.sh

		catkin_make \
			-C $QSC_WORKSPACE \
			-j 16

		chmod +x /home/$USER_NAME/slaver_startup.sh
		chmod +x /home/$USER_NAME/qsc_slaver.sh

		# 修复文件权限
		chown $USER_NAME:$USER_NAME -R /home/$USER_NAME/qsc_ws
		chown $USER_NAME:$USER_NAME /home/$USER_NAME/qsc_slaver.sh
		chown $USER_NAME:$USER_NAME /home/$USER_NAME/slaver_startup.sh

		autostart

	else
		echo "请检查清qsc_ws位置"
	fi

}
qsc_slaver
