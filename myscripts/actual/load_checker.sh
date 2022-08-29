#!/bin/bash


for site in $(cat sites.list)
do
    for till in $(cat posclients.list | grep $site)
    do
        echo -n "$till "
        cat 02-check-load-posclients/out-log/$till.txt |grep CPU |tr -d \"
    done

done
echo
echo done