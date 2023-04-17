#!/bin/bash

while true
do
    if [ $(ip a | grep -c "tunsnx") -eq 0 ]; then
        /root/scripts/./start_snx_tun.sh
        
    fi
    sleep 600

done