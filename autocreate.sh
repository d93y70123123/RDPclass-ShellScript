#!/bin/bash
# This script is for no used user
# exec: sh autocreate.sh kai 200.200.200.2 20001

Username=${1}
user_IP=${2}
user_port=${3}

. /root/script/RDPclass/function.sh --source-only

# 判斷有沒有使用過 | insert 跟 update
check_used=`mysql -u root -p2727175#356 -D RDPclass -e "select username from userinfo where username='${Username}'" -B -N`
if [ $check_used ];then
    mysql -u root -p2727175#356 -D RDPclass -e "update userinfo set IP='${user_IP}',port='${user_port}',seat='${seat}',seatIP='${vmip}',usestatus=1 where username='${Username}'"
    # echo "insert"
else
    mysql -u root -p2727175#356 -D RDPclass -e "insert into userinfo (username,IP,port,seat,seatIP,usestatus) values('${Username}','${user_IP}',${user_port},'${seat}','${vmip}',1);"
    # echo "update"
fi

auto_scan_nc
if [ "${available[0]}" ];then
    echo "auto_scan_nc"
    seat=${available[0]}
    vmip=`mysql -u root -p2727175#356 -D GFDO -e "select vm_ip from vm where vm='${available[0]}'" -B -N`
    firewall ${user_IP} ${user_port} ${vmip}
	createRDP ${Username} ${user_IP} ${user_port}

    # 判斷第一次跟用過 | insert 跟 update
    check_used=`mysql -u root -p2727175#356 -D RDPclass -e "select username from userinfo where username='${Username}'" -B -N`
    mysql -u root -p2727175#356 -D RDPclass -e "update userinfo set IP='${user_IP}',port='${user_port}',seat='${seat}',seatIP='${vmip}',usestatus=1 where username='${Username}'"

    # mysql -u root -p2727175#356 -D RDPclass -e "insert into pre_open (hostid,vmid,hostip,vmip) values('PC${hostid}','${available[0]}','${hostip}','${vmip}')"
elif [ -z "${available[0]}" ];then
    # 若沒有電腦使用，則重新判斷每台電腦是否開機，若有未開機狀態的電腦，則將電腦開機
    # will return ava_host array
    echo "auto_scan_host"
    auto_scan_host
    if [ "${ava_host[0]}" ];then
        echo "will open ${ava_host[0]}"
        pcmac=`mysql -u root -p2727175#356 -D GFDO -e "select mac from host where host_num='${ava_host[0]}'" -B -N`
        hostip=`mysql -u root -p2727175#356 -D GFDO -e "select host_ip from host where host_num='${ava_host[0]}'" -B -N`
        seat="PC${ava_host[0]}-1"
        vmip=`mysql -u root -p2727175#356 -D GFDO -e "select vm_ip from vm where vm='${seat}}'" -B -N`

        mysql -u root -p2727175#356 -D RDPclass -e "update userinfo set IP='${user_IP}',port='${user_port}',seat='${seat}',seatIP='${vmip}',usestatus=2 where username='${Username}'"
        ether-wake "$pcmac"
        openhost ${pcmac} ${seat} ${hostip}

        mysql -u root -p2727175#356 -D RDPclass -e "update userinfo set IP='${user_IP}',port='${user_port}',seat='${seat}',seatIP='${vmip}',usestatus=3 where username='${Username}'"
        openvm ${pcmac} ${seat} ${hostip}
        res=$?
        # single_scan $hostip $seat $vmip
        # 等等思考一下
        # mysql -u root -p2727175#356 -D RDPclass -e "update userinfo set IP='${user_IP}',port='${user_port}',seat='${seat}',seatIP='${vmip}',usestatus=2 where username='${Username}'"`
        if [ "${res}" == 0 ];then
            firewall ${user_IP} ${user_port} ${vmip}
            # echo 'firewall'
    	    createRDP ${Username} ${user_IP} ${user_port}
            # echo "createRDP"
	        mysql -u root -p2727175#356 -D RDPclass -e "update userinfo set IP='${user_IP}',port='${user_port}',seat='${seat}',seatIP='${vmip}',usestatus=1 where username='${Username}'"            
        else
            # echo 'vm open faild'
            mysql -u root -p2727175#356 -D RDPclass -e "update userinfo set IP='${user_IP}',port='${user_port}',seat='${seat}',seatIP='${vmip}',usestatus=5 where username='${Username}'"
        fi
    else
        auto_scan_vm
        echo "will check vm state : ${ava_vm[0]}"
        if [ ${ava_vm[0]} ];then
            firewall ${user_IP} ${user_port} ${vmip}
	        createRDP ${Username} ${user_IP} ${user_port}
        fi
    fi
fi