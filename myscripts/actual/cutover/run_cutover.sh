#!/bin/bash

#cat posclients.list | sed "/t001/d" | parallel --no-notice "tills_wf/wf_{}/{}.start.sh"  > logfile &

for till in $(cat posclients.list | sed "/t001/d")
do
./tills_wf/wf_$till/$till.start.sh >> logfile &
sleep 5

done