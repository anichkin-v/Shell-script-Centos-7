#!/bin/bash

declare -r ens="ens224"
declare -r MAC="00:00:00:00:00:00"
declare -r IP="10.11.12.13"

cat << EOF > /etc/sysconfig/network-scripts/ifcfg-$ens
NAME="$ens"
HWADDR="$MAC"
DEVICE="$ens"
ONBOOT="yes"
IPADDR="$IP"
PREFIX="24"
DNS1="8.8.8.8"
EOF
echo
echo
echo
echo
echo "*********** Add NetWork port ifcfg-$ens *************"
echo
echo
echo
echo    ">>>>>>>>>>>>>> REBOOT NETWORK <<<<<<<<<<<<<<<<<<"
echo
echo
systemctl restart network
echo
echo
echo      "-------------------DONE-----------------------"