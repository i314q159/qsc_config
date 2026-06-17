#!/usr/bin/env bash

# 用户名
USER_NAME="admin"
QSC_ZIP="qsc_slaver.zip"

safe_remove() {
	local file_path="$1"

	local allowed_dir="/home/$USER_NAME/"

	local real_file
	real_file=$(realpath -m "${file_path}")

	if [[ "${real_file}" == "${allowed_dir}"* && -e "${file_path}" ]]; then
		rm -rf "${file_path}"
	fi
}

zip_qsc_ws() {
	safe_remove "/home/$USER_NAME/$QSC_ZIP"

	cd /home/$USER_NAME &&
		zip -r $QSC_ZIP qsc_ws/ slaver_startup.sh qsc_slaver.sh \
			-x="qsc_ws/devel/*" \
			-x="qsc_ws/build/*" \
			-x="qsc_ws/src/lyjc/src/dianxian_photo/*" \
			-x="qsc_ws/src/run/cmake-build-debug/*"
}
zip_qsc_ws
