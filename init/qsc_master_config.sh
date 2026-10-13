#!/usr/bin/env bash

# 系统版本号
REQUIRE_UBUNTU_VERSION="20.04"

# 用户名
USER_NAME="admin1"

# qsc 工作空间名
QSC_WORKSPACE="/home/$USER_NAME/qsc_ws"

HOST_NAME="qsc-master"

safe_remove() {
	local file_path="$1"

	local allowed_dir="/home/$USER_NAME/"

	local real_file
	real_file=$(realpath -m "${file_path}")

	if [[ "${real_file}" == "${allowed_dir}"* && -e "${file_path}" ]]; then
		rm -rf "${file_path}"
	fi
}

# 检查脚本执行权限
check_root_privileges() {
	if [ "$EUID" -ne 0 ]; then
		echo "Script does not have root privileges."
		echo "Please run as root or with sudo."
		exit 1
	fi
}
check_root_privileges

# 检查系统版本号
check_os_version() {
	local VERSION

	VERSION=$(lsb_release -sr)

	if [ "$VERSION" != "$REQUIRE_UBUNTU_VERSION" ]; then
		echo "System version is not Ubuntu $REQUIRE_UBUNTU_VERSION, current version: $VERSION"
		exit 1
	fi
}
check_os_version

# 校对时间
setup_timezone() {
	timedatectl set-timezone Asia/Shanghai
	timedatectl set-ntp true
}
setup_timezone

# 关闭系统升级
disable_upgrade() {
	systemctl disable --now unattended-upgrades.service
	apt remove -y unattended-upgrades update-manager
}
disable_upgrade

# 开机无密码自动登录
enable_automatic_login() {
	if [ -e "/etc/gdm3/custom.conf" ]; then
		cat >/etc/gdm3/custom.conf <<EOF
[daemon]
WaylandEnable=false
AutomaticLoginEnable=True
AutomaticLogin=$USER_NAME

[security]

[xdmcp]

[chooser]

[debug]

EOF
	else
		echo "/etc/gdm3/custom.conf not found"
	fi

}
enable_automatic_login

# gnome desktop 的设置
disable_gsettings() {
	sudo -u $USER_NAME gsettings set org.gnome.desktop.session idle-delay 0
	sudo -u $USER_NAME gsettings set org.gnome.desktop.screensaver lock-enabled false
	sudo -u $USER_NAME gsettings set org.gnome.desktop.screensaver idle-activation-enabled false
	sudo -u $USER_NAME gsettings set org.gnome.desktop.interface enable-animations false
}
disable_gsettings

# 屏蔽系统休眠单元
disable_sleep() {
	systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
}
disable_sleep

# 更新镜像站
update_mirror() {
	apt update -y
}
update_mirror

# 需要先安装过 ros ，添加过相关软件源
package_install() {
	apt-get install -y libpcap-dev cutecom ros-noetic-jsk-visualization
	apt install -y ros-noetic-serial ros-noetic-gtsam udev ros-noetic-geodesy
}
package_install

# 添加主从机 ip 和 port
# 空出一行防止追加到上一行尾
add_ros_config() {
	cat >>/home/$USER_NAME/.bashrc <<EOF

export ROS_HOSTNAME=192.168.10.1
export ROS_MASTER_URI=http://192.168.10.1:11311
export ROS_IP=192.168.10.1
EOF
}
add_ros_config

# hostname
setup_hostname() {
	hostnamectl set-hostname --static $HOST_NAME
}
setup_hostname

# 添加主从机 host
add_host() {
	cat >/etc/hosts <<EOF
127.0.0.1       localhost
127.0.1.1       qsc-master
192.168.10.2    tegra-ubuntu

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF
}
add_host

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

# 安装 todesk
todesk_install() {
	if [ -e "/home/$USER_NAME/todesk-v4.7.2.0-amd64.deb" ]; then
		apt-get install -y libappindicator3-dev
		apt-get install -y /home/$USER_NAME/todesk-v4.7.2.0-amd64.deb
	fi
}
todesk_install

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

autostart() {
	mkdir -pv /home/$USER_NAME/.config/autostart

	if [ ! -e "/home/$USER_NAME/.config/autostart/qsc.sh.desktop" ]; then
		cat >/home/$USER_NAME/.config/autostart/qsc.sh.desktop <<EOF
[Desktop Entry]
Type=Application
Exec=/home/$USER_NAME/qsc.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name[zh_CN]=qsc
Name=qsc
Comment[zh_CN]=
Comment=
EOF
	fi

	chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/.config/autostart/
}

# mid_360
Livox-SDK2_config() {
	safe_remove $QSC_WORKSPACE/src/Livox-SDK2/build/

	cd $QSC_WORKSPACE/src/Livox-SDK2/ &&
		cmake -B build -S . &&
		cmake --build build --target install -- -j 16
}

# mid_360
livox_ros_driver2_config() {
	source /opt/ros/noetic/setup.sh
	cd $QSC_WORKSPACE/src/livox_ros_driver2-master/ &&
		./build.sh ROS1
}

qsc_master() {
	if [ -e "/home/$USER_NAME/qsc_master.zip" ]; then
		safe_remove $QSC_WORKSPACE

		# unzip -q -o /home/$USER_NAME/qsc_master.zip -d /home/$USER_NAME/

		# unzip -q -o /home/$USER_NAME/qsc_master.zip "li_test/*" -d /home/$USER_NAME/
		# unzip -q -o /home/$USER_NAME/qsc_master.zip "pack/*" -d /home/$USER_NAME/
		unzip -q -o /home/$USER_NAME/qsc_master.zip "qsc_ws/*" -d /home/$USER_NAME/
		unzip -q -o /home/$USER_NAME/qsc_master.zip "qsc.sh" -d /home/$USER_NAME/

		# 删除上一台车的编译产物
		safe_remove $QSC_WORKSPACE/build/
		safe_remove $QSC_WORKSPACE/devel/

		Livox-SDK2_config
		livox_ros_driver2_config

		# 编译主程序
		source /opt/ros/noetic/setup.sh
		source $QSC_WORKSPACE/devel/setup.sh

		catkin_make \
			-C $QSC_WORKSPACE \
			-j 16 \
			-DENABLE_TRANSFORM=ON

		chmod +x /home/$USER_NAME/qsc.sh

		# 修复文件权限
		echo "修复文件权限..."
		chown $USER_NAME:$USER_NAME -R $QSC_WORKSPACE
		chown $USER_NAME:$USER_NAME /home/$USER_NAME/qsc.sh

		autostart

	else
		echo "请检查清扫车主机程序压缩包下载位置"
	fi
}
qsc_master

# 配置 qt 程序
pack_config() {
	if [ -e "/home/$USER_NAME/pack.zip" ]; then
		sudo -u $USER_NAME unzip -q -o /home/$USER_NAME/pack.zip -d /home/$USER_NAME/
		sudo -u $USER_NAME ln -s /home/$USER_NAME/pack/ROS_Qt_Test-x86_64.AppImage /home/$USER_NAME/桌面/
		sudo -u $USER_NAME mkdir -pv /home/$USER_NAME/bag/
		sudo -u $USER_NAME mkdir -pv /home/$USER_NAME/guanjiandian/
	fi
}
pack_config

# 配置定位程序
li_test_config() {
	if [ -e "/home/$USER_NAME/li_test.zip" ]; then
		sudo -u $USER_NAME unzip -q -o /home/$USER_NAME/li_test.zip -d /home/$USER_NAME/

		safe_remove /home/$USER_NAME/li_test/sc-lio-loam-one/devel/
		safe_remove /home/$USER_NAME/li_test/sc-lio-loam-one/build/

		catkin_make \
			-C /home/$USER_NAME/li_test/sc-lio-loam-one \
			-j 16

		safe_remove /home/$USER_NAME/li_test/sc-lio-loam-two/devel/
		safe_remove /home/$USER_NAME/li_test/sc-lio-loam-two/build/

		catkin_make \
			-C /home/$USER_NAME/li_test/sc-lio-loam-two \
			-j 16

		# 修复文件权限
		chown $USER_NAME:$USER_NAME -R /home/$USER_NAME/li_test/
	fi
}
li_test_config

# 配置 stlink
stlink_config() {
	if [ -e "/home/$USER_NAME/stlink.zip" ]; then
		unzip -q -o /home/$USER_NAME/stlink.zip -d /home/$USER_NAME/

		# 生成一个备份文件CMakeLists.txt.bak，然后将第12行行首加上#
		sed -i.bak '12s/^/#/' /home/$USER_NAME/stlink/CMakeLists.txt

		# 在 build 下编译
		cd /home/$USER_NAME/stlink/ &&
			cmake -B build -S . &&
			cmake --build build -- -j 16

		# 拷贝编译产物
		cp /home/$USER_NAME/stlink/build/bin/st-* /usr/local/bin
		cp /home/$USER_NAME/stlink/build/lib/*.so* /lib32

		# 拷贝 udev 规则
		cp /home/$USER_NAME/stlink/config/udev/rules.d/49-stlinkv* /etc/udev/rules.d/

		# 删除 stlink 文件夹
		rm -rf /home/$USER_NAME/stlink/

	else
		echo "stlink 编译失败"
	fi
}
stlink_config

# 安装刷底层固件的程序
stm32cubeprg_config() {
	local ZIP_FILE="/home/$USER_NAME/en.stm32cubeprg-lin-v2-17-0.zip"
	local EXTRACT_DIR="/home/$USER_NAME/en.stm32cubeprg-lin-v2-17-0"

	if [ -e "$ZIP_FILE" ]; then
		mkdir -pv "$EXTRACT_DIR"
		unzip -q -o "$ZIP_FILE" -d "$EXTRACT_DIR"

		chown $USER_NAME:$USER_NAME -R "$EXTRACT_DIR"

		find "$EXTRACT_DIR" -name "*.linux" -type f -exec chmod +x {} \;
		# find "$EXTRACT_DIR" -name "*.exe" -type f -exec chmod +x {} \;
	fi

	# 执行图形化安装
	if [ -e "$EXTRACT_DIR" ]; then
		sudo -u $USER_NAME $EXTRACT_DIR/SetupSTM32CubeProgrammer-2.17.0.linux
	else
		echo "stm32cubeprg 安装失败"
	fi

}
stm32cubeprg_config

# 配置串口权限
imu_config() {
	cat >/etc/udev/rules.d/70-ttyS1.rules <<EOF
KERNEL=="ttyS1", GROUP="dialout", MODE="0660"
EOF

	usermod -aG dialout $USER_NAME

	udevadm control --reload-rules
	udevadm trigger --subsystem-match=tty

}
imu_config

# 开启 ssh 作为现场调试手段
enable_ssh() {
	apt install -y openssh-server
	systemctl enable --now ssh
}
enable_ssh

rviz_init() {
	if [ -e "/home/$USER_NAME/rviz.zip" ]; then
		sudo -u $USER_NAME unzip -q -o /home/$USER_NAME/rviz.zip -d /home/$USER_NAME/
	fi
}
rviz_init
