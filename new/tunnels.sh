#!/bin/bash

# скрипт для полнятия туннелей. Для работы требует наличия в системе sshpass. 
# объявление списка туннелей. формат порт_локалхоста:целевой_адрес:целевой_порт прокси_сервер пароль_прокси комментарий_без_проблеов
tunnels_list=("6014:10.0.41.14:22 devadmin@10.0.41.25 LOANL7bt SSH_порт_asr03" \
              "6041:10.0.41.41:22 devadmin@10.0.41.25 LOANL7bt SSH_порт_asr04" \
              "1481:10.0.41.14:6181 devadmin@10.0.41.25 LOANL7bt SMC_asr03" \
              "4181:10.0.41.41:6181 devadmin@10.0.41.25 LOANL7bt SMC_asr04"
              "4183:10.0.41.41:6183 devadmin@10.0.41.25 LOANL7bt SPR_asr04"
              "4184:10.0.41.41:6184 devadmin@10.0.41.25 LOANL7bt SEE_asr04"
              "1483:10.0.41.14:6183 devadmin@10.0.41.25 LOANL7bt SPR_asr03"
              "1484:10.0.41.14:6184 devadmin@10.0.41.25 LOANL7bt SEE_asr03")

# функция поднятия туннелей
function tunnels_up {
   for (( i=0; i<"${#tunnels_list[@]}"; i++ )); do
        # парсим элемент массива на переменные
        local_port=$(echo ${tunnels_list[i]} | awk '{print $1}' | awk -F ":" '{print $1}')
        dest_server=$(echo ${tunnels_list[i]} | awk '{print $1}' | awk -F ":" '{print $2}')
        dest_port=$(echo ${tunnels_list[i]} | awk '{print $1}' | awk -F ":" '{print $3}')
        proxy_data=$(echo ${tunnels_list[i]} | awk '{print $2}')
        proxy_pass=$(echo ${tunnels_list[i]} | awk '{print $3}')
        # сообщение с данными+выполнение итоговой команды
        echo "Пытаемся поднять туннель с порта $dest_port сервера $dest_server на локальный порт $local_port"
        eval "sshpass -p $proxy_pass ssh -f -N -L $local_port:$dest_server:$dest_port $proxy_data" && echo OK || echo "Туннель поднять не удалось"
   done
}

# функция вывода списка поднятых туннелей
function tunnels_list {
    echo -e "Ниже отображен список туннелей.\nВАЖНО! С списке будут только туннели, указанные в скрипте, он не покажет туннели, поднятые вручную!"
    echo "==========================================================================================================================================="
    # заголовок таблицы
    echo "Localhost port:       Remote port:        Remote server:              Proxy server:             Comment:"
    echo "-------------------------------------------------------------------------------------------------------------------"
    for (( i=0; i<"${#tunnels_list[@]}"; i++ )); do
        # парсим элемент массива на переменные
        local_port=$(echo ${tunnels_list[i]} | awk '{print $1}' | awk -F ":" '{print $1}')
        dest_server=$(echo ${tunnels_list[i]} | awk '{print $1}' | awk -F ":" '{print $2}')
        dest_port=$(echo ${tunnels_list[i]} | awk '{print $1}' | awk -F ":" '{print $3}')
        tunnel_comment=$(echo ${tunnels_list[i]} | awk '{print $4}')
        proxy_data=$(echo ${tunnels_list[i]} | awk '{print $2}')
        # проверяем наличие туннеля из массива в списке процессов и, если существует выводим информацию по нему
        if [ $(ps aux | grep $local_port:$dest_server:$dest_port | grep -c $proxy_data) -gt 0 ]; then
            echo "$local_port                       $dest_port$(smooth_table $dest_port)$dest_server              $proxy_data       $tunnel_comment"
        fi
        echo "-------------------------------------------------------------------------------------------------------------------"
   done
   echo done
}

# функция выравнивания таблицы для нормального отображения 2,3,4 значных портов
function smooth_table {
    dim=$((20-$(echo $1 | wc -c)))
    for (( i = 0; i < $dim; i++ )) 
    do 
        echo -n " "
    done

}


function tunnels_down {
    for (( i=0; i<"${#tunnels_list[@]}"; i++ )); do
        # парсим элемент массива на переменные
        local_port=$(echo ${tunnels_list[i]} | awk '{print $1}' | awk -F ":" '{print $1}')
        dest_server=$(echo ${tunnels_list[i]} | awk '{print $1}' | awk -F ":" '{print $2}')
        dest_port=$(echo ${tunnels_list[i]} | awk '{print $1}' | awk -F ":" '{print $3}')
        proxy_data=$(echo ${tunnels_list[i]} | awk '{print $2}')
        # определяем ПИД процесса
        tunnel_pid=$(ps aux | grep $local_port:$dest_server:$dest_port | grep $proxy_data | awk '{print $2}')
        # убиваем процесс
        kill $tunnel_pid && echo "Туннель с порта $dest_port сервера $dest_server на локальный порт $local_port выключен" || \
            echo "Туннель с порта $dest_port сервера $dest_server на локальный порт $local_port выключить не удалось, возможно, он не существует." 
        
   done
}

# удаление пробелов из строки
function string_no_space {
  no_space=`echo -e $@ | sed -e 's/ //g'`
  echo $no_space
}

# все возможные варианты элементов массива
function mix_array {
  # блок инициации массива переданного в функцию, по другому дурацкий баш не передает
  # длина массива
  newvar="${1}"
  shift
  # все элементы массива
  newarray=("${@}")
  # задание пустого массива куда складируются все варианты
  list=()
  for (( i=0; i<$newvar; i++ )); do
    list+=(${newarray[i]})
    for (( j=0; j<$newvar; j++ )); do
      if [ $i -ne $j ]; then
        list+=(${newarray[j]})
      fi
    done
  done
  # вывод функции
  echo ${list[*]}
}


# описание режимов работы скрипта, выводит при "пустом" запуске
function show_description {
  echo "ключи -up(--up) -l(--list) -d(--down) 

----совместный блок-------
"-up/--up"                   - поднять туннели из списка
вместе
"-l/--list"                  - показать список поднятых туннелей
"-d/--down"                  - погасить поднятые скриптом тунели


# Поднять туннели из списка
Пример использования: $0 -up
# Показать список поднятых туннелей
Пример использования: $0 --list
# Погасить поднятые туннели
Пример использования: $0 -down
"
}

########
# main #
########


# пустой запуск
if [ "$1" == "" ]; then show_description; exit; fi

# перебор ключей запуска
while (($#)); do
 arg=$1
  shift
   case $arg in
     # для двойных ключей с --
     --*) case ${arg:2} in
           # поднятие туннелей
           up)  key_up="up";;
           # остановка туннелей
           down)   key_down="down";;
           # показать список активных туннелей из списка
           list)  key_list="list";;
           *) echo "неправильный двойной ключ запуска";;
          esac;;

     # для одинарных ключей с -
     -*) case ${arg:1} in
          # поднятие туннелей
           up)  key_up="up";;
           # остановка туннелей
           d)   key_down="down";;
           # показать список активных туннелей из списка
           l)  key_list="list";;
           *) echo "неправильный одинарный ключ запуска";;
         esac;;
    esac
done

# массив ключей установки, все варианты ключей, при добалении нового ключа - дописать его СЮДА!
key_all=($key_up  \
         $key_down  \
         $key_list)
# все варианты, в перемешку, поступивших ключей
key_all_mix=$(mix_array ${#key_all[@]} ${key_all[@]})
# все ключи в кучу без пробелов
key_all_no_space=$(string_no_space ${key_all_mix[@]})

# выборка вариантов совместных ключей
case $key_all_no_space in
  # поднимаем туннели
  up     ) tunnels_up;;
  # выключаем туннели
  down    ) tunnels_down;;
  # показать список 
  list      ) tunnels_list;;
  # пустая строка
  ""          ) show_description;;
  *           ) echo "неправильное сочетание ключей";;
esac

exit 0

