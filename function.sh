#! /bin/bash
# for RDPclass function of use 
# kai. 2021.06

# auto scan all PC nc status
auto_scan_nc(){
	available=()
	for IP in $( seq 3 42 )
	do
		vm_IP="192.168.31.${IP}"

		# check vm status
		vm_status=`./nc.sh ${vm_IP} 2> /dev/null`
		if [ "$vm_status" ];then
			vm_id=`mysql -u root -p2727175#356 -D GFDO -e "select vm from vm where vm_ip='${vm_IP}'" -B -N`
			available+=("${vm_id}")
		fi
	done
}

# auto scan all HOST status
auto_scan_host(){
	ava_host=()
	for IP in $( seq 53 71 )
	do
		host_IP="192.168.31.${IP}"

		# check host status
		ssh -o ConnectTimeout=1 root@$host_IP 'date' &> /dev/null; result=$? 
		if [ "$result" != 0 ];then
			host_num=`mysql -u root -p2727175#356 -D GFDO -e "select host_num from host where host_ip='${host_IP}'" -B -N`
			ava_host+=("${host_num}")
		fi
	done
}

# auto scan all vm status
auto_scan_vm(){
	ava_vm=()
	for IP in $( seq 3 21 )
	do
		host_IP="192.168.31.$((50+${IP}))"

		ssh -o ConnectTimeout=1 root@$host_IP 'date' &> /dev/null; result=$? 
		if [ "${result}" != 0 ];then
			continue
		fi
		for id in $( seq 1 2)
		do
			vmid=PC${IP}-${id}
			ssh -o ConnectTimeout=1 root@${host_IP} virsh list |grep ${vmid} ; vm_status=$? &> /dev/null
			
			# check vm status			
			if [ $vm_status != 0 ];then
				ava_vm+=("${vmid}")
			fi
		done
	done
}

# scan one PC status 
single_scan(){
	hostip=${1}
	seat=${2}
	vmip=${3}

	ssh -o ConnectTimeout=1 root@${hostip} date &> /dev/null; host_status=$?
	ssh -o ConnectTimeout=1 root@${hostip} virsh list |grep ${seat} &> /dev/null; vm_status=$?
	cd /root/script/RDPclass/
	vm_user_list=`./nc.sh ${vmip} 2> /dev/null`
	if [ $host_status == 0 ];then
		if [ $vm_status == 0 ];then
			if [ "${vm_user_list}" ];then
				return 0
			else
				return 3
			fi
		else 
			# openvm
			return 2
		fi
	else
		# openhost
		# openvm
		return 1
	fi
}

openhost(){
	pcmac=${1}
	vmid=${2}
	hostip=${3}

	ether-wake "$pcmac"
	i=0
	result='1'
	until [ "$result" == 0 ]
	do
		ssh -o ConnectTimeout=1 root@"${hostip}" 'date' &> /dev/null;result=$?
		i=$(echo $(($i+1)))
		sleep 5
		if [ "$i" == 20 ];then
			mysql -u root -p2727175#356 -D GFDO -e "update vm set vm_status=0 where vm='${vmid}'" -B -N
			mysql -u root -p2727175#356 -D GFDO -e "update host set host_status=0,vm_1_status=0 where mac='${pcmac}'" -B -N
			break
		fi
		if [ "$i" == 10 ];then
			ether-wake "$pcmac"
		fi
		mysql -u root -p2727175#356 -D GFDO -e "update host set host_status=1 where mac='${pcmac}'" -B -N
	done
}

openvm(){
	pcmac=${1}
	vmid=${2}
	hostip=${3}
	date=$( date +"%Y/%m/%d %T" )
	if [ $result == 0 ];then
		mysql -u root -p2727175#356 -D GFDO -e "update host set host_status=1 where mac='${pcmac}'" -B -N
		ssh -o ConnectTimeout=5 root@$hostip virsh nodedev-detach pci_0000_00_1c_2 &> /dev/null
		ssh -o ConnectTimeout=5 root@$hostip virsh nodedev-detach pci_0000_00_1c_4 &> /dev/null
		ssh -o ConnectTimeout=1 root@$hostip "virsh create /vm_data/xml/${vmid}.xml"; result=$?
		# ssh -o ConnectTimeout=5 root@$hostip "echo \"sh /vm_data/script/Pre.sh ${vmid}\"|at now"; result=$?
		if [ $result == 0 ];then
			mysql -u root -p2727175#356 -D GFDO -e "update vm set user='guest',vm_status=2,time='${date}' where vm='${vmid}'" -B -N
			mysql -u root -p2727175#356 -D GFDO -e "update host set vm_1_status=2 where mac='${pcmac}'" -B -N
			return 0
			break
		else
			sh /root/script/wakeup_pc_vm.sh 'guest' "${host_num}" $hostip $pcmac
		fi
	fi
}

createRDP(){
#	sh RDPcreate.sh
Username=${1}
user_IP=${2}
user_port=${3}

servermac='eno1'
serverip=`ifconfig "${servermac}" |grep 'inet ' |awk '{print $2}'`
cat << EOF > /var/www/html/rdpclass/rdppkg/${Username}.c
#include <stdio.h>
#include <stdlib.h>

int main() {
	system("mstsc /admin /v:${serverip}:${user_port}");
	return 0;
}
EOF
x86_64-w64-mingw32-gcc -o /var/www/html/rdpclass/rdppkg/${Username}.exe /var/www/html/rdpclass/rdppkg/${Username}.c

}

firewall(){
	user_IP=${1}
	user_port=${2}
	vmip=${3}

	out='eno1'
	iptables -A INPUT -i ${out} -s ${user_IP} -p tcp --dport ${user_port} -j ACCEPT
	iptables -t nat -A PREROUTING -i ${out} -p tcp -m tcp --dport ${user_port} -j DNAT --to-destination ${vmip}:3389
}

del_firewall(){
	user_IP=${1}
	user_port=${2}
	vmip=${3}

	out='eno1'
	iptables -D INPUT -i ${out} -s ${user_IP} -p tcp --dport ${user_port} -j ACCEPT
	iptables -t nat -D PREROUTING -i ${out} -p tcp -m tcp --dport ${user_port} -j DNAT --to-destination ${vmip}:3389
	
	# iptables -t nat -D PREROUTING -i eno1 -p tcp -m tcp --dport 12129 -j DNAT --to-destination 192.168.31.3:3389
	# iptables -D INPUT -s 123.205.165.140/32 -i eno1 -p tcp -m tcp --dport 12129 -j ACCEPT
}

del_userinfo(){
	Username=${1}
	mysql -u root -p2727175#356 -D RDPclass -e "delete from userinfo where username=${Username}"
}

