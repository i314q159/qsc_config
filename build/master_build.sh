#!/usr/bin/env bash

# 用户名
USER_NAME="admin1"

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

Livox-SDK2_config() {
	safe_remove "$QSC_WORKSPACE/src/Livox-SDK2/build/"

	cd $QSC_WORKSPACE/src/Livox-SDK2/ &&
		cmake -B build -S . &&
		cmake --build build --target install -- -j 16
}

livox_ros_driver2_config() {
	source /opt/ros/noetic/setup.sh
	cd $QSC_WORKSPACE/src/livox_ros_driver2-master/ &&
		./build.sh ROS1
}

qsc_master() {
	if [ -e "/home/$USER_NAME/qsc_ws" ]; then
		# 删除上一台车的编译产物
		safe_remove "$QSC_WORKSPACE/build/"
		safe_remove "$QSC_WORKSPACE/devel/"

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

	else
		echo "请检查qws_ws位置"
	fi
}
qsc_master
