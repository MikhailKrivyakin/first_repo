#!/bin/bash
. /opt/fujitsu/profuse/zonemaster/misc/lib/workflows.inc.sh

run_steps "$@"
if ! grep "^sys" out-runlog.txt > /dev/null; then
   exit 1
fi

if [ $(tail out-runlog.txt |grep "RUN COMPLETED"|wc -l) -gt 0 ] && [ $(tail out-runlog.txt |grep "Errors" | wc -l) -eq 0 ]; then
    echo $1 >> ../../ready_tills.list             #mark till as ready
fi
~
~
~
~
~
~
