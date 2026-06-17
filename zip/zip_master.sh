#!/usr/bin/env bash

# 用户名
USER_NAME="admin1"
QSC_ZIP="qsc_master.zip"

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
		zip -r $QSC_ZIP qsc_ws/ qsc.sh \
			-x="qsc_ws/devel/*" \
			-x="qsc_ws/build/*" \
			-x="qsc_ws/src/topic_record/*.log" \
			-x="qsc_ws/src/ros_pub/rotating.*" \
			-x="qsc_ws/src/Livox-SDK2/build/*" \
			-x="qsc_ws/src/addObsMap.tgz" \
			-x="qsc_ws/src/qscmap.tgz" \
			-x="qsc_ws/src/realMap.tgz" \
			-x="qsc_ws/hybrid_map/*" \
			-x="qsc_ws/lowmap/*" \
			-x="qsc_ws/src/run/cmake-build-debug/*" \
			-x="qsc_ws/src/cleaningvehicle/cmake-build-debug/*" \
			-x="qsc_ws/src/lidar_get_reflector/cmake-build-debug/*" \
			-x="qsc_ws/src/corner/cmake-build-debug/*" \
			-x="qsc_ws/src/secletpath/cmake-build-debug/*" \
			-x="qsc_ws/src/log_bag/cmake-build-debug/*" \
			-x="qsc_ws/src/patchwork-plusplus_clean/cleaningvehicle/cmake-build-debug/*"
}
zip_qsc_ws

zip_li_test() {
	safe_remove "/home/$USER_NAME/li_test.zip"

	cd /home/$USER_NAME &&
		zip -r li_test.zip li_test/ \
			-x="li_test/sc-lio-loam-one/devel/*" \
			-x="li_test/sc-lio-loam-one/build/*" \
			-x="li_test/sc-lio-loam-two/devel/*" \
			-x="li_test/sc-lio-loam-two/build/*"
}
# zip_li_test

zip_li_test_nopcd() {
	safe_remove "/home/$USER_NAME/li_test_nopcd.zip"

	cd /home/$USER_NAME &&
		zip -r li_test_nopcd.zip li_test/ \
			-x="li_test/sc-lio-loam-one/devel/*" \
			-x="li_test/sc-lio-loam-one/build/*" \
			-x="li_test/sc-lio-loam-two/devel/*" \
			-x="li_test/sc-lio-loam-two/build/*" \
			-x="li_test/PCD/*"
}
# zip_li_test_nopcd

zip_pack() {
	safe_remove "/home/$USER_NAME/pack.zip"

	cd /home/$USER_NAME &&
		zip -r pack.zip pack/
}
# zip_pack
