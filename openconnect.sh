#!/bin/bash
# auto create PC for prevention
# exec: sh openconnect.sh kai 120.114.140.28 20001 PC1-2 192.168.31.2

Username=${1}
user_IP=${2}
user_port=${3}
seat=${4}
vmip=${5}
# hostip=`mysql -u root -p2727175#356 -D GFDO -e "select host_ip from host where host_vm1='${seat}' || host_vm2='${seat}'" -B -N`

. /root/script/RDPclass/function.sh --source-only

# single_scan $hostip	$seat $vmip
# res=$?

firewall ${user_IP} ${user_port} ${vmip}
createRDP ${Username} ${user_IP} ${user_port}

check_used=`mysql -u root -p2727175#356 -D RDPclass -e "select username from userinfo where username='${Username}'" -B -N`
if [ $check_used ];then
    mysql -u root -p2727175#356 -D RDPclass -e "update userinfo set IP='${user_IP}',port='${user_port}',seat='${seat}',seatIP='${vmip}',usestatus=1 where username='${Username}'"
else
    mysql -u root -p2727175#356 -D RDPclass -e "insert into userinfo (username,IP,port,seat,seatIP,usestatus) values('${Username}','${user_IP}',${user_port},'${seat}','${vmip}',1);"
fi



## 下面沒用到
# if [ "${res}" == 0 ];then
# 	firewall ${user_IP} ${user_port} ${vmip}
# 	createRDP ${Username} ${user_IP} ${user_port}
# 	mysql -u root -p2727175#356 -D RDPclass -e "update userinfo set IP='${user_IP}',port='${user_port}',seat='${seat}',seatIP='${vmip}',usestatus=1 where username='${Username}'"
# elif [ "${res}" == 1 ];then
# 	echo 'host no open'
# 	# openhost
# 	# openvm
# elif [ "${res}" == 2 ];then
# 	echo 'vm no open have to open vm'
# 	# openvm
# elif [ "${res}" == 3 ];then
# 	echo 'already has user used'
# 	# sh pre_open.sh
# 	#找新的電腦
# fi

# firewall ${IP} ${port} ${vmip}

# createRDP ${Username} ${user_IP} ${port}

# #insert to DB