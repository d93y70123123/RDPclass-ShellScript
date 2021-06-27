#!/bin/bash
username=${2}
IP=${1}
res=`cat <(echo "cmd.exe /c C:\users\public\check_pc_status.exe ${username}") <(sleep 0.5) |nc -w 0.5 -n ${IP} 3501 |grep -i 'No User'`
if [ "$res" ];then
	echo "$res"
fi
