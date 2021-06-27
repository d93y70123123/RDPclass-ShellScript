#!/bin/bash
# This script is for no used user
# exec: sh autocreate.sh kai 200.200.200.2 20001

. /root/script/RDPclass/function.sh --source-only

auto_scan_vm

echo ${ava_vm[@]}
