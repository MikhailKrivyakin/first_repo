#!/bin/bash
prg="./new_evaluate_spr_3_model.py"
serv_url="http://10.2.0.190:6183/spr/"
logfile="test.log"
modeldir="/model/"
testdir="/dataset/"
msg=""
function get_testresult {
  cd $testdir
  msg="${msg}
""$(for dr in $(ls -d */);do echo " набор "$dr" записей"|tr -d '\n'|tr -d '\/';cat $dr"accuracy.txt"|cut -d":" -f2;done)"
}
function check_model {
  message="no"
  for i in $(curl -s -X GET "$serv_url" -H "accept: application/json" | jq -c '.models' | sed 's/\[//;s/\]//;s/\"//g;s/,/ /g'); do
  if [ "$1" = "$i" ]; then
    message="yes"
  fi
  done
  echo "$message"
}
function install_model {
  curl -s -X POST "$serv_url""data/$1" -H  "accept: application/json" -H  "Content-Type: multipart/form-data" -F "zip-model=@$2;type=application/zip"  &> /dev/null
  if [ "$(check_model $1)" == "yes" ]; then
  echo "installed"
  else echo "error"
  fi
}
function delete_model {
  if [[ $(check_model $1)=="yes" ]]
  then
    curl -s -X DELETE "$serv_url""data/$1" -H "accept: application/json" &>/dev/null
  else
    echo "error"
    exit 1
  fi
  if [[ $(check_model $1)=="no" ]]
  then
    echo "deleted"
  else
    echo "error"
  fi
}
function do_test {
  url=$(echo $serv_url|sed 's/spr\///g')
  cd $testdir
  echo "actual;recognized by SPR;Resp.time;CER;wav;dataset" > errors.csv
  for dr in $(ls -d */)
  do
  echo "$prg $dr $url $model" >> $testdir"log"
  eval "$prg $dr $url $model" >> $testdir"log"
  sleep 2
  testset=$(echo $dr|sed 's/\///g')
  cat $model"_evaluation_report.csv" |grep -v ",0.00," |grep -v "actual"| sed 's/,/;/g'|sed 's/\./,/1;s/\./,/1'|awk -v m=$testset '{print$0";"m}' >> errors.csv
  rm -f $model"_evaluation_report.csv"
  done
}
function send_message {
  /usr/bin/curl --silent --data chat_id="-1001669151578" --data-urlencode "text=${msg}" "https://api.telegram.org/bot5186207563:AAHtoAx4bi8C6FNmOr-bHy1tBVpiBdio4dk/sendMessage?parse_mode=HTML" > /dev/null 2>&1
  echo "${msg}" > $testdir"messagefile"
}
while [ 1 ];do
sleep 120
cd $modeldir
find -name "model" -type f | while read fl; do
    sleep 120
    zip -j $fl".zip" $fl
    model=$(date +"%m%d%H%M")
    rm -f $fl
    res=$(install_model $model $fl".zip")
    echo $res > $testdir"log"
    rm -f $fl".zip"
    if [[ $res=="installed" ]]
    then
      msg="$(echo -e "ПРЕДЫДУЩИЙ ТЕСТ\n")"
      get_testresult
      echo "started test" >> $testdir"log"
      do_test
      msg="${msg}"$(echo -e "\n";echo -e "НОВАЯ МОДЕЛЬ\n")
      get_testresult
      send_message
      /usr/bin/curl -v -F "chat_id=-1001669151578" -F document=@$testdir"errors.csv" https://api.telegram.org/bot5186207563:AAHtoAx4bi8C6FNmOr-bHy1tBVpiBdio4dk/sendDocument
    else
      echo "model not installed" >> $testdir"log"
    fi
    mv $testdir"errors.csv" $testdir$(date +"%m%d%H%M")".csv"
    delete_model $model
done
