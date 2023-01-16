function f_create_odbc_config_files  #функция создания конфиг файлов коннектра ODBC
{
    if [ -f /opt/voicetech/config/mysql.conf ]; then
    sql_conf='/opt/voicetech/config/mysql.conf'
    sql_server=`jq -r .host $sql_conf`
    sql_user=`jq -r .user $sql_conf`
    sql_pass=`jq -r .pass $sql_conf`

    echo "[VTMySQL] 
enabled=yes 
dsn=VTMySQL 
pre-connect=yes 
username=$sql_user
password=$sql_pass
forcecommit=no 
isolation=repeatable_read 
connect_timeout=3" > /etc/asterisk/res_odbc.conf #создание файла с данными для астера

echo "[MySQL ODBC 8.0 Unicode Driver] 
Driver=/usr/lib64/libmyodbc8w.so 
UsageCount=1 

[MySQL ODBC 8.0 ANSI Driver] 
Driver=/usr/lib64/libmyodbc8a.so 
UsageCount=1">>/etc/odbcinst.ini #дописывание драйверов в стандартный конфиг ODBC коннектера

echo "[VTMySQL] 
driver=/usr/lib64/libmyodbc8a.so 
server=$sql_server 
database=voicetech 
Port=3306 
readtimeout=2 
writetimeout=2 
option=3 
charset=utf8" >/etc/odbc.ini #созадние конфига для ODBC коннектера
else 
echo "_________________________________________
Внимание! На момент выполнения установки не был заполнен файл /opt/voicetech/config/mysql.conf! 
Данные для ODBC коннектера к базе нужно заполнить вручную в файлах:
res_odbc.conf
/etc/odbc.ini
"
fi

}