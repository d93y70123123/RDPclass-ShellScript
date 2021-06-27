#! /bin/bash
# check one status
# exec: sh single_scan.sh PC1-2 192.168.31.2
seat=${1}
vmip=${2}
hostip=`mysql -u root -p2727175#356 -D GFDO -e "select host_ip from host where host_vm1='${seat}' || host_vm2='${seat}'" -B -N`

. /root/script/RDPclass/function.sh --source-only
single_scan $hostip $seat $vmip

echo $?
