#!/bin/bash


old_dir=/srv/packages/installer/23_11_2022_new_arc
new_dir=/srv/packages/installer/28.12_arc

for file in `cat total.csv`
do
    filename=`echo $file |awk -F "," '{print $1}'`
    class=`echo $file |awk -F "," '{print $2}'`
    case $class in
        gos)
            echo "$filename is $class. should be gos"
        ;;
        addresses | adresses)
        echo "$filename is $class. should be adr"
        ;;
        common)
        echo "$filename is $class. should be common"
        ;;
        names)
        echo "$filename is $class. should be names"
        ;;
    esac
done