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

# mid_360s
Livox-SDK2_config() {
	safe_remove "$QSC_WORKSPACE/src/Livox_SDK2/build/"

	cd $QSC_WORKSPACE/src/Livox_SDK2/ &&
		cmake -B build -S . &&
		cmake --build build --target install -- -j 16
}

# mid_360s
livox_ros_driver2_config() {
	source /opt/ros/noetic/setup.sh
	cd $QSC_WORKSPACE/src/livox_ros_driver2/ &&
		./build.sh ROS1
}
