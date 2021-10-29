#!/bin/bash

profuse unit show $1| grep Till > tills_IP.list
date
cat tills_IP.list |  while read output
	do
		ip=$(echo $output | cut -c 39-50)
		name=$(echo $output | cut -c 1-11)
		ping -c 1 -W 5 $ip > /dev/null
		if [ $? -eq 0 ]; then
			echo "$name is up"
		else
			echo "$name is down"
		fi
	done
rm tills_IP.list;