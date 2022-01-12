#!/bin/bash

cat posclients.list | sed "/t001/d" | parallel --no-notice "tills_wf/wf_{}/{}.start.sh"  > logfile &