#!/bin/bash

base=voicetech
MySQL=`echo mysql -u root --password="MySQLP@ssw0rd1" -h 10.2.0.215 --skip-column-names`
node_list=`jq -r .nodes /opt/voicetech/config/sync.conf |sed 's/"//g' |sed 's/,//g' |grep -v '\[\|\]'`

#функция проверки соответствия нод в базе, с нодами в файле sync.conf
function checknodes {
    node_list=`jq -r .nodes /opt/voicetech/config/sync.conf |sed 's/"//g' |sed 's/,//g' |grep -v '\[\|\]'`
    for node in `$MySQL -e "select onlyfornode from updated;" $base | sed "s/\t/|/g"` 
    do
        if [ `echo ${node_list} |grep -c ${node}` -eq 0 ];then
        $MySQL -e "DELETE FROM updated WHERE onlyForNode='${node}';" $base 
        fi
    done
    for node in `$MySQL -e "select onlyfornode from options;" $base | sed "s/\t/|/g"` 
    do
        if [ `echo ${node_list} |grep -c ${node}` -eq 0 ];then
        $MySQL -e "DELETE FROM options WHERE onlyForNode='${node}';" $base
        fi   
    done


}

checknodes




