#!/bin/bash
echo "Hostname  CPUnumber:  CPU idle:  CPU iowait:  CPU AvL 1m:   RAM available:  RAM available%:  Free disk on  '/':   '/boot/': '/opt/':  Free Inodes on '/'  '/boot/'  '/opt/' MaxFiles:              MaxProc:"
echo -n "$HOSTNAME   "
echo -n "`nproc`           "
echo -n "`iostat | sed '4!d' |awk '{print $6}'`      "
echo -n "`iostat | sed '4!d' |awk '{print $4}'`        "
echo -n "`uptime | awk '{print $8}'`         "
echo -n "`free -h |grep "Mem\|Память" |awk '{print $2}'`             "
echo -n "`free |grep "Mem\|Память" |awk '{print $7 / $2 *100}' `      "
echo -n "             `df -h | awk '/\/$/{print $5}'`         "
echo -n "`df -h | awk '/boot/{print $5}'`     "
echo -n "`df -h | awk '/opt/{print $5}'`     "
echo -n "                 `df -i |awk '/\/$/{print 100-$5}'`      "
echo -n "`df -i |awk '/boot/{print 100-$5}'`    "
echo -n "`df -i |awk '/opt/{print 100-$5}'`  "
echo -n "       `cat /proc/sys/fs/file-max`     "
echo "    `cat /proc/sys/kernel/pid_max`    "