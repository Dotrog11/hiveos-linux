#!/usr/bin/env bash

function claymore_zpools_gen() {
	[[ -z $ZPOOLS_TPL ]] &&
		echo -e "${YELLOW}WARNING: ZPOOLS_TPL is not set, skipping epools.txt generation${NOCOLOR}" &&
		return 1

	echo "Creating epools.txt"

	echo "$ZPOOLS_TPL" > $CLAYMORE_ZPOOLS_TXT

	return 0
}




function claymore_user_config_gen() {
	if [[ ! -z $CLAYMORE_Z_USER_CONFIG ]]; then
		echo "$CLAYMORE_USER_CONFIG_SEPARATOR" >> $CLAYMORE_Z_CONFIG
		echo "Appending user config";
		echo "$CLAYMORE_Z_USER_CONFIG" >> $CLAYMORE_Z_CONFIG
	fi
}





function miner_ver() {
	echo $MINER_LATEST_VER
}


function miner_config_echo() {
	local MINER_VER=`miner_ver`

	miner_echo_config_file "/hive/miners/$MINER_NAME/$MINER_VER/config.txt"
	miner_echo_config_file "/hive/miners/$MINER_NAME/$MINER_VER/epools.txt"
}


function miner_config_gen() {
	local MINER_VER=`miner_ver`

	CLAYMORE_Z_CONFIG="$MINER_DIR/$MINER_VER/config.txt"
	CLAYMORE_ZPOOLS_TXT="$MINER_DIR/$MINER_VER/epools.txt"
	CLAYMORE_USER_CONFIG_SEPARATOR="### USER CONFIG ###"

	mkfile_from_symlink $CLAYMORE_Z_CONFIG
	mkfile_from_symlink $CLAYMORE_ZPOOLS_TXT

	cat /hive/miners/claymore/config_global.txt | envsubst > $CLAYMORE_Z_CONFIG

	claymore_zpools_gen
	claymore_user_config_gen
}


