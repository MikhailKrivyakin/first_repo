#/bin/bash
#скрипт устанавливает версии ядра - для центос - последнию из имеющихся в репозитории, для дебиан - версию 5.19 из репозитория backports 
#также скрипт отключает selinux и выставляет в параметрах загрузчика загрузку самого последнего ядра из имеющихся

if [[ $EUID -ne 0 ]]; then
    echo "Скрипт должен быть запущен из под root"
    exit 1
fi

if [ -f "/etc/redhat-release" ]; then
    echo 'Определена ОС - Centos. Начинаем подготовку'
    rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
    yum install -y https://www.elrepo.org/elrepo-release-7.el7.elrepo.noarch.rpm 
    yum --disablerepo="*" --enablerepo="elrepo-kernel" list available
    yum --enablerepo=elrepo-kernel install -y kernel-ml
    sed -i "s/GRUB_DEFAULT=.*/GRUB_DEFAULT=0/" /etc/default/grub 
    grub2-mkconfig -o /boot/grub2/grub.cfg
    echo -e "Загрузчик Grub сконфигурирован: \n `cat /etc/default/grub |grep GRUB_DEFAULT=`"
    sed -i "s/SELINUX=.*/SELINUX=disabled/" /etc/selinux/config
    echo -e "Selinux отключен: \n ` cat /etc/selinux/config|grep 'SELINUX=disabled'`"
    yum --enablerepo="*" list available
    rm -f /etc/yum.repos.d/CentOS-Media.repo
    echo "Все готово. Можете перезагрузить систему"
elif [ -f "/etc/debian_version" ]; then
    echo 'Установка окружения debian'
    echo "deb http://deb.debian.org/debian bullseye-backports main contrib non-free" >> /etc/apt/sources.list
    apt update
    apt install -t bullseye-backports linux-image-5.19.0-0.deb11.2-amd64
    sed -i "s/GRUB_DEFAULT=.*/GRUB_DEFAULT=0/" /etc/default/grub 
    grub2-mkconfig -o /boot/grub2/grub.cfg
    sed -i "s/SELINUX=.*/SELINUX=disabled/" /etc/selinux/config
    echo -e "Selinux отключен: \n ` cat /etc/selinux/config|grep 'SELINUX=disabled'`" 
    echo "Все готово. Можете перезагрузить систему"
else
    echo "ОС не опознана - выход"
    exit 1
fi





