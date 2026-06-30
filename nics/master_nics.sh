#!/usr/bin/env bash

static_nics=(
	"enp2s0,192.168.6.102/24"
	"enp3s0,192.168.2.102/24"
	"eno1,192.168.10.1/24"
)
dhcp_nic="enp4s0"

remove_nics_config() {
	nmcli -t -f NAME connection show | xargs -I {} nmcli connection delete "{}"
}
remove_nics_config

static_nics_config() {
	for item in "${static_nics[@]}"; do
		IFS=, read -r dev ip <<<"$item"
		con="static-$dev"
		nmcli con add con-name "$con" ifname "$dev" type ethernet ipv4.method manual ipv4.addresses "$ip"
		nmcli con modify "$con" connection.autoconnect yes
		nmcli con up "$con"
	done
}
static_nics_config

dhcp_nic_config() {
	nmcli con add con-name dhcp-$dhcp_nic ifname $dhcp_nic type ethernet ipv4.method auto
	nmcli con modify dhcp-$dhcp_nic connection.autoconnect yes
	nmcli con up dhcp-$dhcp_nic
}
dhcp_nic_config
