#!/bin/bash

function renew_list {
    mode=$1
    [ ! -f "$2" ] && echo "Не указан или неверно указан внешний список модулей. Выходим" && exit 1
    new_list=$2
    #перебор ключей для выбора какой список обновлять    
    case $mode in 
        full) 
            varname=modules_pip3_full
        ;;
        minimal) 
            varname=modules_pip3_minimal
        ;;
        *)
            echo "Неверный ключ выхова функции"
        ;;
    esac
    begin_line_number=`awk "/^${varname}/ {print NR}" $script_name `    # номер строки с объявлением переменной
    endline_number=`cat $script_name |tail -n +$begin_line_number | awk '/)$/ {print NR}' |head -n1` # количество строк от объявления переменной до конца массива
    final_number=$(( $begin_line_number+$endline_number-1 )) # считаем вторую границу диапазона, -1 для корректировки
    count=0 #ограничитель на количество модулей в строке итогового файла. Нужно для лучшей читаемости
    #начинаем формировать пременный файл
    echo -n "${varname}=(" > tmp.txt
    for module in $(cat $new_list) 
    do
        echo -n "\"$module\" ">> tmp.txt
        count=$(($count+1))
        [ $count -eq 5 ] && echo "\\">> tmp.txt && count=0 # 5 модулей в строке,после этого ставим \ и переходим на новую строку
    
    done
    echo ")">> tmp.txt
    sed -i "${begin_line_number},${final_number}d" $script_name 
    sed -i "$(($begin_line_number-1))r tmp.txt" $script_name
    rm -f tmp.txt

}