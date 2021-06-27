#! /bin/bash
# check host and vm status
# exec: sh pre_open.sh
. /root/script/RDPclass/function.sh --source-only

# 待測試
pre_open=`mysql -u root -p2727175#356 -D RDPclass -e "select * from pre_open" -B -N`
if [ "${pre_open}" ];then
    single_scan $hostip	$seat $vm_ip
    if [ "$res" == "use" ];then
        exit 0
    else
        mysql -u root -p2727175#356 -D RDPclass -e "delete from pre_open"
    fi
fi

# will return 'available[]' array 
auto_scan_nc

# 用NC敲過後，如果有回應，且沒有使用者登入，直接將該電腦設為預開機電腦
if [ "${available[0]}" ];then
    hostid=`mysql -u root -p2727175#356 -D GFDO -e "select host_num from host where host_vm1='${available[0]}' || host_vm2='${available[0]}'" -B -N`
    hostip=`mysql -u root -p2727175#356 -D GFDO -e "select host_ip from host where host_vm1='${available[0]}' || host_vm2='${available[0]}'" -B -N`
    vmip=`mysql -u root -p2727175#356 -D GFDO -e "select vm_ip from vm where vm='${available[0]}'" -B -N`
    mysql -u root -p2727175#356 -D RDPclass -e "insert into pre_open (hostid,vmid,hostip,vmip) values('PC${hostid}','${available[0]}','${hostip}','${vmip}')"
elif [ -z "${available[0]}" ];then
# 若沒有電腦使用，則重新判斷每台電腦是否開機，若有未開機狀態的電腦，則將電腦開機
    # will return ava_host array
    auto_scan_host
    if [ "${ava_host[0]}" ];then
        pcmac=`mysql -u root -p2727175#356 -D GFDO -e "select mac from host where host_num='${ava_host[0]}'" -B -N`
        hostip=`mysql -u root -p2727175#356 -D GFDO -e "select host_ip from host where host_num='${ava_host[0]}'" -B -N`
        ether-wake "$pcmac"
        openhost $pcmac "PC${ava_host[0]}-1" ${hostip}
        # i=0
        # until [ "$result" == 0 ]
        # do
        #     ssh -o ConnectTimeout=1 root@"$hostip" 'date' &> /dev/null;result=$?
        #     i=$(echo $(($i+1)))
        #     sleep 5
        #     if [ "$i" == 20 ];then
        #         mysql -u root -p2727175#356 -D GFDO -e "update vm set vm_status=0 where vm='PC${ava_host[0]}-1'" -B -N
        #         mysql -u root -p2727175#356 -D GFDO -e "update host set host_status=0,vm_1_status=0 where mac='${pcmac}'" -B -N
        #         break
        #     fi
        #     if [ "$i" == 10 ];then
        #         ether-wake "$pcmac"
        #     fi
        #     mysql -u root -p2727175#356 -D GFDO -e "update host set host_status=1 where mac='${pcmac}'" -B -N
        # done

        openvm $pcmac $vmid	$hostip
        # if [ $result == 0 ];then
        #     mysql -u root -p2727175#356 -D GFDO -e "update host set host_status=1 where mac='${pcmac}'" -B -N
        #     ssh -o ConnectTimeout=5 root@$hostip virsh nodedev-detach pci_0000_00_1c_2 &> /dev/null
        #     ssh -o ConnectTimeout=5 root@$hostip virsh nodedev-detach pci_0000_00_1c_4 &> /dev/null
        #     #ssh -o ConnectTimeout=1 root@$pcip "virsh create /vm_data/xml/${vmid}.xml"; result=$?
        #     ssh -o ConnectTimeout=5 root@$hostip "echo \"sh /vm_data/script/Pre.sh PC${ava_host[0]}-1\"|at now"; result=$?
        #     if [ $result == 0 ];then
        #         mysql -u root -p2727175#356 -D GFDO -e "update vm set user='guest',vm_status=2,time='${date}' where vm='${vmid}'" -B -N
        #         mysql -u root -p2727175#356 -D GFDO -e "update host set vm_1_status=2 where mac='${pcmac}'" -B -N
        #         break
        #     else
        #         sh /root/script/wakup_pc_vm.sh 'guest' "PC${ava_host[0]}-1" $hostip $pcmac
        #     fi
        # fi

        vmip=`mysql -u root -p2727175#356 -D GFDO -e "select vm_ip from vm where vm='PC${ava_host[0]}-1'" -B -N`
        mysql -u root -p2727175#356 -D RDPclass -e "insert into pre_open (hostid,vmid,hostip,vmip) values('PC-${ava_host[0]}','PC${ava_host[0]}-1','${hostip}','${vmip}')"
    fi
fi

# 未來再新增，有開機但沒有開虛擬機的預備開啟功能。
