#!/bin/bash
# kai. 202106. auto create PC for prevention
# exec: sh disconnect.sh kai 120.114.140.28 20001 PC1-2 192.168.31.2

Username=${1}
user_IP=${2}
user_port=${3}
seat=${4}
vmip=${5}

. /root/script/RDPclass/function.sh --source-only

del_firewall ${user_IP} ${user_port} ${vmip}
# del_userinfo ${Username}
mysql -u root -p2727175#356 -D RDPclass -e "update userinfo set IP='${user_IP}',port='${user_port}',seat='${seat}',seatIP='${vmip}',usestatus=0 where username='${Username}'"
