#!/bin/bash

fade -H | grep -oP "\w\d\w\wmg02" >> zones.list

for i in  in `cat zones.list`; do

scp -i /opt/fujitsu/profuse/mom/data/cm/keys/deploy.key "/home/rusmik/2repo.tar" deploy@"$i":/tmp/ && ssh -i /opt/fujitsu/profuse/mom/data/cm/keys/deploy.key deploy@$i "sudo tar xvf /tmp/2repo.tar -C /root/ && rm /tmp/2repo.tar "

done

rm zones.list
