#!/bin/bash

cat posclients.list | sed "/t001/d" | parallel "tills_wf/wf_{}/run-steps.sh"  > logfile &