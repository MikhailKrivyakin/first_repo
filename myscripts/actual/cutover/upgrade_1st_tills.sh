#!/bin/bash

cat posclients.list | grep "t001" | parallel --no-notice "tills_wf/wf_{}/{}.start.sh"  > logfile &