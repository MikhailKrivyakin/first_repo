#!/bin/bash

function SetWorkingParameters() {
#WorkDir="/repos/packages"
WorkDir="/opt/repos/packages"
GitURL='https://bot:botP%40ssw0rd12$@git.connect2ai.net'
GitBranch='master'
RepoDirectories='Builders/tts.git Builders/urs.git Builders/spr.git Builders/pve.git Builders/ups.git Builders/ums.git Builders/smc.git Builders/see.git Builders/sbs.git'
api_token="glpat-9u85g1Bknw6GWsm1ia3g"
# добавляем ID репозиториев
# 4 - SPR
# 6 - ups
# 5 - smc
# 3 - see
# 27-sbs
repos=("4" "6" "5" "3" "27") 
}


function CreateDirectoryAndClone() {
    if [ ! -d ${WorkDir} ]; then
	mkdir -p ${WorkDir}
	if [ ! -d ${WorkDir} ]; then
	    echo Can not create working directory \"${WorkDir}\"
	    exit
	else
	    cd ${WorkDir}
	    for RepoDir in ${RepoDirectories}; do
		git clone -b "${GitBranch}" ${GitURL}/${RepoDir}
	    done
	fi
    fi
}

function external_cycle_of_bot() {
    cd $1

    pull=`git pull 2>&1`
    if [ `echo "$pull" | grep -c "Could not read from"` -ne 0 ]; then
	echo "Не удалось получить данные из $1"
	cd ..
	continue
    fi

    if [ `echo "$pull" | grep -c "error"` -ne 0 ]; then
	git fetch --all
	pull=`git reset --hard origin/master`
    fi

    if [ `echo "$pull" | grep -c "error\|fatal\|Already\|Уже\ обновлено"` -eq 0 ]; then
	product=`echo $1 | awk '{ print toupper($0) }'`
	comment=`git whatchanged master -1 --date=raw |head -n5 |tail -n1`
	msg="
<b>--------------------------------</b>
<b>В $product появились обновления.</b>
<b>--------------------------------</b>

$comment

Файлы:"

	while read line; do
	    msg="$msg
$line"
	done < <( git whatchanged master -1 --date=raw | grep -v old |awk '{print $6}' |grep -v '^[[:space:]]*$' )
	/usr/bin/curl --silent --data chat_id="-1001669151578" --data-urlencode "text=${msg}" "https://api.telegram.org/bot5186207563:AAHtoAx4bi8C6FNmOr-bHy1tBVpiBdio4dk/sendMessage?parse_mode=HTML" >/dev/null 2>&1
echo $msg
    fi

    cd ..
}
# функция будет автоматически "пинать" мирроринг указанных репозиториев. Это позволяет обойти стандартное гитлабовское обновление "раз в час"
function force_mirror_repo() {
	for repo in ${repos[@]} 
	do
		/usr/bin/curl --silent --request POST --header "PRIVATE-TOKEN: $api_token" "http://10.2.0.188:7080/api/v4/projects/${repo}/mirror/pull"	
		sleep 30
	done

}

######################## main program begins here ########################
SetWorkingParameters
CreateDirectoryAndClone
cd ${WorkDir}
ls -d */ | sed 's/\///g' | \
while read dr; do
   external_cycle_of_bot ${dr}
done
force_mirror_repo
exit
