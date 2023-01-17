#!/bin/bash

# дата последнего редактирования 16.12.2022 12:36
# tested: centOS7,debian11

############################################
# критические переменные для быстрой смены #
############################################
# имя скрипта нужно для запуска на удаленном хосте и для запаковки архива в скрипт, автоматически
# обновляется при изменении имени
script_name="pve-1.022-universal.sh"
# местонахождение сервиса
pve_dir="/opt/pve"
# каталог куда распакуется внутренний архив
int_arch_extract_dir="archive"
# имя внутреннего архива, обновляется при перепаковке
int_arch_name="pve_offline.tgz"
# каталог системных пакетов созданных через --build
sys_dir="$int_arch_extract_dir/packages"
# версия питона для установки
# CentOS
python_ver_centos="3.9.16"
# Debian
python_ver_debian="3.9.16"
#AltLinux
python_ver_altlinux="3.9.16"
##############
# переменные #
##############
# переменные внутреннего архива
PAYLOAD_LINE=$(awk '/^__PAYLOAD_BEGINS__/ { print NR + 1; exit 0; }' $0)
# файл логов
log_file="script.log"
# расположение скрипта
actual_path=$(readlink -f "${BASH_SOURCE[0]}")
script_dir=$(dirname "$actual_path")
# временная папка
temp_dir="temp"
# внешний файл списка модулей pip3
list_pip3_modules_ext="freeze.txt"

# CentOS
# список пакетов для скачивания
# минимально необходимый набор системных пакетов
packages_system_centos=("yum-utils" "cmake" "gcc" "gcc-c++" "curl" "git" "patch" "mc")
# остальные пакеты
packages_main_centos=("python3-pip" "python3-devel" "gcc" "libsndfile" "python3-wheel" "python3-virtualenv" \
                      "rustc" "cargo" "openssl" "openssl-devel" "libffi" \
                      "libffi-devel" "zlib" "zlib-devel" "bzip2" "bzip2-devel" "libxml2" "libxml2-devel" \
                      "xmlsec1" "xmlsec1-openssl" "readline" "readline-devel" "sqlite" "sqlite-devel" \
                      "xz" "xz-devel" \
                      "ffmpeg")
# Debian
# минимально необходимый набор системных пакетов
packages_system_debian=("gcc" "g++" "cpp" "curl" "git" "patch" "cmake" "build-essential" \
                        "apt-transport-https" "gnupg2" "mc" "net-tools")
# остальные пакеты
packages_main_debian=("python3-pip" "gcc-c++" "python3-dev" "gcc" "libsndfile1" "python3-wheel" "python3-venv" \
                      "rustc" "cargo" "openssl" "libssl-dev" \
                      "libffi-dev" "zlib1g" "zlib1g-dev" "bzip2" "libbz2-dev" "libxml2" "libxml2-dev" \
                      "xmlsec1" "libxmlsec1-dev" "readline-common" "libreadline-dev" "sqlite3" \
                      "libsqlite3-dev" "xz-utils" "lzma" "liblzma-dev" \
                      "build-essential" \
                      "ffmpeg")
#Altlinux
# минимально необходимый набор системных пакетов
packages_system_altlinux=("python3" "openssl" "gcc" "cpp" "curl" "git" "patch" "cmake" \
                        "apt-https" "gnupg2" "mc" "net-tools" "libreadline7" "jq")
# остальные пакеты
packages_main_altlinux=("python3-pip" "python3-dev" "gcc" "gcc-c++" "libsndfile1" "python3-wheel" "python3-venv" \
                      "rustc" "cargo" "openssl" "libssl-devel" \
                      "libffi-devel" "zlib1g" "zlib1g-devel" "zlib-devel" "bzip2" "libbz2-dev" "libxml2" "libxml2-dev" \
                      "xmlsec1" "libxmlsec1-devel" "readline-common" "libreadline-devel" "libreadline-devel-static " "sqlite3" \
                      "libsqlite3-devel" "xz-utils" "lzma" "liblzma-devel" "libstdc++-devel-static" \
                      "build-essential" "bzip2-devel" \
                      "ffmpeg")
# список модулей pip3 для скачивания
modules_pip3=("pip" "setuptools" "pyinstaller" "wheel" "loguru" "pyyaml" "setuptools-rust==1.1.2" "pandas==1.4.4" \
              "requests==2.27.1" "sklearn" "matplotlib==3.4.3" "tokenizers" "numpy==1.23.3" "scipy==1.5.4" \
              "bs4" "uuid" "soundfile" "nltk==3.6.7" "Unidecode" "pydub" "gunicorn" "cython" "NumPy==1.23.3" \
              "hydra-core" "braceexpand" "webdataset" "torch_stft" "inflect==5.3.0" "pyannote-core" \
              "pyannote-metrics" "IPython==7.16.3" "editdistance" "pytorch_lightning==1.5.10" "Flask-Cors" \
              "Flask==2.1.0" "flask-restplus==0.13.0" "nemo-toolkit==1.7.1" "transformers==4.4.2" \
              "librosa==0.8.1" "youtokentome==1.0.3" "jinja2==3.0.0" "itsdangerous==2.0.1" "protobuf==3.19.4" \
              "Werkzeug==2.0.2" "torch" "packaging==21.0" "seaborn==0.11.2" \
              "cmake" "onnx==1.11.0" "sentencepiece")

######################
## функции-процедуры #
######################
# определение операционной системы
function detect_os {
  if [ -f /etc/redhat-release ]; then
    if [ `cat /etc/redhat-release | grep '^CentOS' | awk '{print tolower($1);}'` == "centos" ]; then
      os="centos"
      version=`cat /etc/redhat-release | grep '^CentOS' | awk '{print $4}'`
      codename=""
    fi
   elif [ -f /etc/os-release ]; then
    if [ `cat /etc/os-release | grep '^ID=' | sed s/'ID='//g | awk '{print tolower($0)}'` == "debian" ]; then
      os="debian"
      version=`cat /etc/debian_version | awk '{print $1}'`
      codename=`cat /etc/os-release | grep '^VERSION_CODENAME' | sed s/'VERSION_CODENAME='//g`
    elif [ `cat /etc/os-release | grep '^ID=' | sed s/'ID='//g | awk '{print tolower($0)}'` == "altlinux" ];then
      os="altlinux"
      version=`cat /etc/os-release  |grep VERSION_ID |sed 's/VERSION_ID=//g'`
      
    fi
  fi

  # имя ос
  if [ "$1" == "os" ]; then echo "$os"; fi
  # обрезка версии до первой точки
  if [ "$1" == "version" ]; then echo "$version" | sed 's/\..*//'; fi
  # кодовое имя дистрибутива
  if [ "$1" == "codename" ]; then echo "$codename"; fi
}

# установка репозиториев
function install_repo {
  case $(detect_os os) in
    centos)
     yum install -y epel-release
     # ffmpeg
     rpm -Uvh --replacepkgs http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-5.el7.nux.noarch.rpm
    ;;
    debian)
    ;;
    altlinux)
    ;;
  esac
}

# установка системных пакетов
function install_pac {
  cd $script_dir
  if [ $1 == "online" ]; then
    case $(detect_os os) in
      centos)
        yum install -y yum-utils
        yum-complete-transaction --cleanup-only
        # установка основных системных пакетов
        if [ "$2" == "system" ]; then
          for (( i=0; i<"${#packages_system_centos[@]}"; i++ )); do
            yum install -y ${packages_system_centos[i]}
          done
         # установка питоновских пакетов
         elif [ "$2" == "main" ]; then
          for (( i=0; i<"${#packages_main_centos[@]}"; i++ )); do
            yum install -y ${packages_main_centos[i]}
          done
        fi
      ;;
      debian)
        apt update
        if [ "$2" == "system" ]; then
          for (( i=0; i<"${#packages_system_debian[@]}"; i++ )); do
            apt install -y ${packages_system_debian[i]}
          done
         elif [ "$2" == "main" ]; then
          for (( i=0; i<"${#packages_main_debian[@]}"; i++ )); do
            apt install -y ${packages_main_debian[i]}
          done
        fi
      ;;
      altlinux)
        apt-get update
        if [ "$2" == "system" ]; then
          for (( i=0; i<"${#packages_system_altlinux[@]}"; i++ )); do
            apt-get install -y ${packages_system_altlinux[i]}
          done
         elif [ "$2" == "main" ]; then
          for (( i=0; i<"${#packages_main_altlinux[@]}"; i++ )); do
            apt-get install -y ${packages_main_altlinux[i]}
          done
        fi
      ;;
    esac
   elif [ $1 == "offline" ]; then
     case $(detect_os os) in
      centos)
        rpm -ivh --replacepkgs --force $2/*
      ;;
      debian)
        dpkg -i $2/*
      ;;
      altlinux)
        apt-get install -y $2/*
      ;;
    esac
  fi
}

# создание временных директорий
function create_temp_dirs {
  cd $script_dir
  if [ ! -d $int_arch_extract_dir ]; then mkdir $int_arch_extract_dir; fi
  if [ ! -d $int_arch_extract_dir/packages ]; then mkdir $int_arch_extract_dir/packages; fi
}

# скачать пакеты rpm
function download_pac {
  cd $script_dir
  cd $sys_dir
  case $(detect_os os) in
    centos)
      yum --enablerepo=base clean metadata
      # системные пакеты
      for (( i=0; i<"${#packages_system_centos[@]}"; i++ )); do
        repotrack -a x86_64 "${packages_system_centos[i]}"
      done
      # все основные пакеты
      for (( i=0; i<"${#packages_main_centos[@]}"; i++ )); do
        repotrack -a x86_64 "${packages_main_centos[i]}"
      done
    ;;
    debian)
      # системные пакеты
      apt update
      for (( i=0; i<"${#packages_system_debian[@]}"; i++ )); do
        apt install -y -d ${packages_system_debian[i]}
      done
      for (( i=0; i<"${#packages_main_debian[@]}"; i++ )); do
        apt install -y -d ${packages_main_debian[i]}
      done
      mv /var/cache/apt/archives/*.deb 
# этот вариант не скачивает все зависимости зависимостей
#      for (( i=0; i<"${#packages_system_debian[@]}"; i++ )); do
#        "pkgdownload.sh" "${packages_system_debian[i]}"
#      done
#      # все основные пакеты
#      for (( i=0; i<"${#packages_main_debian[@]}"; i++ )); do
#        "pkgdownload.sh" "${packages_main_debian[i]}"
#      done
# после последнего обновления этот вариант не работает
#        apt-offline set offline.sig --install-packages ${packages_system_debian[@]} ${packages_main_debian[@]}
#        apt-offline get offline.sig --no-checksum -d ''
    ;;
    altlinux)
       # системные пакеты
      apt-get update
      for (( i=0; i<"${#packages_system_altlinux[@]}"; i++ )); do
        apt-get install -y -d ${packages_system_altlinux[i]}
      done
      for (( i=0; i<"${#packages_main_altlinux[@]}"; i++ )); do
       apt-get install -y -d ${packages_main_altlinux[i]}
      done
       cp /var/cache/apt/archives/*.rpm $PWD/
    ;;
  esac
}

# формирование списка requirements.txt
function list_pip3_modules {
  cd $script_dir
  # проверка наличия внешнего файла списка модулей pip3
  if [ -f $list_pip3_modules_ext ]; then
    echo "существует внешний файл список модулей pip3" >> $log_file
    cp $list_pip3_modules_ext $temp_dir/modules/requirements.txt
   else
    echo "внешнего файла списка модулей pip3 не существует, загрузка внутреннего списка" >> $log_file
    for (( i=0; i<"${#modules_pip3[@]}"; i++ )); do
      echo ${modules_pip3[i]} >> $temp_dir/modules/requirements.txt
    done
  fi
}

# перенос pyenv из root директории
function download_pyenv {
 cd $script_dir
 rm -rf $HOME/.pyenv/versions/*
 mv $HOME/.pyenv archive/
 mkdir archive/.pyenv/cache
 case $(detect_os os) in
   centos)
     mv archive/.pyenv/sources/$python_ver_centos/Python-$python_ver_centos.tar.xz archive/.pyenv/cache
   ;;
   debian)
     mv archive/.pyenv/sources/$python_ver_debian/Python-$python_ver_debian.tar.xz archive/.pyenv/cache
   ;;
   altlinux)
    cp archive/.pyenv/sources/$python_ver_altlinux/Python-$python_ver_altlinux.tar.xz archive/.pyenv/cache
   ;;
 esac
}

# скачивание модулей python
function download_modules {
  cd $script_dir
  # переход локально на $python_ver_centos\debian
  case $(detect_os os) in
    centos)
      pyenv local $python_ver_centos
    ;;
    debian)
      pyenv local $python_ver_debian
    ;;
    altlinux)
      pyenv local $python_ver_altlinux
    ;;
  esac
  mkdir $temp_dir
  mkdir $temp_dir/modules
  # создание окружения на базе питона
  python3 -m venv $temp_dir
  # установка всех модулей
  source $temp_dir/bin/activate
    # обновление pip3
    pip3 install --upgrade pip
    pip3 install wheel
    pip3 install scikit-build
    pip3 install setuptools_rust
    pip3 install setuptools
    pip3 install --upgrade cython
    list_pip3_modules
    cd $temp_dir/modules
    pip3 download -r requirements.txt
  deactivate
  # переход локально на системную версию чтобы не сломать то что уже работает на системной
  pyenv local system
  rm -rf .python-version
  cd $script_dir
  mv temp/modules archive/
  rm -rf $temp_dir
}

# создание архива для включения в скрипт оффлайн установки
function create_arсhive {
  cd $script_dir
  tar -zcvf $int_arch_name -C $1 $(ls -A $1) --remove-files
  rm -rf $1
}

# распаковка внутреннего архива
function extract_archive {
  if [ $1 == "dir" ]; then
    echo "распаковка внутреннего архива в $int_arch_extract_dir">> $log_file
    mkdir -p $int_arch_extract_dir
    tail -n +${PAYLOAD_LINE} $0 | base64 -d | tar -xzf - --directory="$int_arch_extract_dir"
   elif [ $1 == "asis" ]; then
    echo "копирование внутреннего архива в каталог со скриптом">> $log_file
    tail -n +${PAYLOAD_LINE} $0 | base64 -d > $int_arch_name
  fi
  if [ "$?" != "0" ]; then
    echo "ошибка установки, архив внутренних ресурсов поврежден" >> $log_file
    clear_temp
    exit
  fi
}

# врезать в скрипт внешний архив
function pack_archive {
  # удалить всё что после payload
  sed -i '/^__PAYLOAD_BEGINS__$/q' $script_name
  # вставить архив в скрипт
  base64 $1 >> $script_name
  # обновить ифнормацию об имени архива в переменную
  sed -i 's/^int_arch_name=.*$/int_arch_name="'$1'"/g' $script_name
}

function null_archive {
  # удалить всё что после payload
  sed -i '/^__PAYLOAD_BEGINS__$/q' $script_name
}

function install_pyenv {
  cd $script_dir
  # удаление папки .pyenv если не установлена ни одна из версий питона
  if [ `ls $HOME/.pyenv/versions | wc -l` -eq 0 ]; then
   rm -rf $HOME/.pyenv
  fi
  # удаление всего кэша (надо посмотреть не вредно ли?)
  rm -rf $HOME/.cache/*
  if [ $1 == "online" ]; then
    curl https://pyenv.run | bash
    export PYENV_ROOT="$HOME/.pyenv"
    command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
    # установка питона с сохранением исходников ключ -k
    case $(detect_os os) in
      centos)
        if [ "`pyenv install --list | sed 's/^ *//g' | grep ^$python_ver_centos`" == "$python_ver_centos" ]; then
          pyenv install -s -k $python_ver_centos
         else
          echo "такой версии питона не существует, проверить версии: pyenv install --list"
          clear_temp
          exit
        fi
      ;;
      debian)
        if [ "`pyenv install --list | sed 's/^ *//g' | grep ^$python_ver_debian`" == "$python_ver_debian" ]; then
          pyenv install -s -k $python_ver_debian
         else
          echo "такой версии питона не существует, проверить версии: pyenv install --list"
          clear_temp
          exit
        fi
      ;;
      altlinux)
        if [ "`pyenv install --list | sed 's/^ *//g' | grep ^$python_ver_altlinux`" == "$python_ver_altlinux" ]; then
          pyenv install -s -k $python_ver_altlinux
         else
          echo "такой версии питона не существует, проверить версии: pyenv install --list"
          clear_temp
          exit
        fi
      ;;
    esac
   elif [ $1 == "offline" ]; then
    mv $int_arch_extract_dir/.pyenv /root
    export PYENV_ROOT="$HOME/.pyenv"
    command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
    # установка питона
    case $(detect_os os) in
      centos)
        pyenv install -s $python_ver_centos
      ;;
      debian)
        pyenv install -s $python_ver_debian
      ;;
      altlinux)
        pyenv install -s $python_ver_altlinux
      ;;
    esac
  fi
}

function install_pve {
  cd $script_dir
  # оффлайн установка pve
  if [ $1 == "offline" ]; then
    # переход локально
    case $(detect_os os) in
      centos)
        pyenv local $python_ver_centos
      ;;
      debian)
        pyenv local $python_ver_debian
      ;;
      altlinux)
        pyenv local $python_ver_altlinux
      ;;
        esac
    # создание окружения на базе питона
    python3 -m venv /opt/pve
    # установка модулей
    source /opt/pve/bin/activate
      cd $int_arch_extract_dir/modules
      # получить имя установочного пакета pip3
      filename_pip3=`ls -A | grep pip-*.whl`
      # получить имя установочного пакета setuptools
      filename_setuptools=`ls -A | grep setuptools-*.whl`
      # получить имя установочного пакета Cython
      filename_cython=`ls -A | grep Cython-*.whl`
      # получить имя установочного пакета pytest_runner
      filename_runner=`ls -A | grep pytest_runner-*.whl`
      # установить отдельно пакет pip3 (не ставится из общей массы)
      pip3 install $filename_pip3 --no-index --find-links '.'
      # установить отдельно пакет setuptools (не ставится из общей массы)
      pip3 install $filename_setuptools --no-index --find-links '.'
      # установить отдельно пакет Cython (не ставится из общей массы)
      pip3 install $filename_cython --no-index --find-links '.'
      # установить отдельно пакет pytest_runner (не ставится из общей массы)
      pip3 install $filename_runner --no-index --find-links '.'
      # установить всю общую массу модулей
      pip3 install -r requirements.txt --no-index --find-links '.'
    deactivate
    # переход локально на системную версию чтобы не сломать то что уже работает на системной
    pyenv local system
   # онлайн установка pve
   elif [ $1 == "online" ]; then
    # переход локально на версию питона установленную через pyenv
    case $(detect_os os) in
      centos)
        pyenv local $python_ver_centos
      ;;
      debian)
        pyenv local $python_ver_debian
      ;;
      altlinux)
        pyenv local $python_ver_altlinux
      ;;
    esac
    # создание окружения на базе питона установленного через pyenv
    python3 -m venv /opt/pve
    # установка модулей
    source /opt/pve/bin/activate
      curl -sS https://bootstrap.pypa.io/pip/get-pip.py | python3
      python3 -m pip install --upgrade pip
      # установка модулей питона из списка в массиве или из внешнего файла модулей
        if [ -f $list_pip3_modules_ext ]; then
          echo "существует внешний файл список модулей pip3" >> $log_file
          mapfile -t modules_pip3 < $list_pip3_modules_ext
          for (( i=0; i<"${#modules_pip3[@]}"; i++ )); do
            pip3 install ${modules_pip3[i]}
          done
        else
          echo "внешнего файла списка модулей pip3 не существует, загрузка внутреннего списка" >> $log_file
          for (( i=0; i<"${#modules_pip3[@]}"; i++ )); do
            pip3 install ${modules_pip3[i]}
          done
        fi
    deactivate
    # переход локально на системную версию чтобы не сломать то что уже работает на системной
    pyenv local system
  fi
}

# удаление старой версии pve
function clear_old {
  cd $script_dir
  rm -fR $pve_dir &> /dev/null
}

function clear_temp {
  cd $script_dir
  rm -rf $int_arch_extract_dir
  rm -rf .python-version
  rm -rf $int_arch_name
  rm -rf $HOME/.cache/pip
  rm -rf $sys_dir/offline.sig
}

# описание режимов работы скрипта
function show_description {
  echo "ключи -i(--install) -e(--extract) -p(--pack) -b(--build) -n(--null)
              -off(--offline) -on(--online)

"-i/--install"           - установить pve в online/offline режиме вместе с ключами -on/-off;
"-off/--offline"         - установка оффлайн (необходимо собрать скрипт с ключем -b/--build, размер ~3Гб)
"-on/--online"           - установка онлайн (собирать с ключем -b/--build не надо)
"-x/--extract"           - скопировать внутренний архив рядом со скриптом;
"-p/--pack имя_архива"   - запаковать архив в скрипт - архив создавать без абсолютных каталогов:
                           tar -czvf urs-install.tgz -C archive \$(ls -A archive);
"-d/--dir имя_каталога"  - совместно с -p/--pack или -x/--extract, сжать\распаковать каталог в\из архива;
"-b/--build"             - скачать все пакеты, и модули, и упаковать в скрипт для оффлайн установки;
"-n/--null"              - удалить внутренний архив из скрипта;

# Установить pve онлайн
Пример использования: $0 -i -on
# Установить pve оффлайн
Пример использования: $0 -i -off
# Скопировать внутренний архив рядом со скриптом не распаковывая в папку
Пример использования: $0 --extract
# Запаковать архив в скрипт
Пример использования: $0 --pack pve-offline.tgz
# Сжать каталог и запаковать архив в скрипт
Пример использования: $0 --pack -d archive
# Распаковать внутренний архив рядом со скриптом в каталог
Пример использования: $0 -x -d
# Собрать все пакеты для установки оффлайн pve
Пример использования: $0 --build
# Удалить внутренний архив из скрипта
Пример использования: $0 --null
"
}

########
# main #
########

if [ `echo $0 | sed 's/\\.\\///g'` != $script_name ]; then
  # обновление имени скрипта в переменной script_name вверху скрипта
  sed -i "s|^script_name=.*$|script_name=\"$0\"|g ; s/\\.\\///g" $0
  echo "скрипт был переименован, запустите ещё раз"
  exit
fi

# пустой запуск
if [ "$1" == "" ]; then show_description; exit; fi

# перебор ключей запуска
while (($#)); do
 arg=$1
  shift
   case $arg in
     # для ключей с --
     --*) case ${arg:2} in
           # установка
           install)  key_install="install";;
           # онлайн установка
           online)   key_online="online";;
           # оффлайн установка
           offline)  key_offline="offline";;
           # сборка внутреннего архива для оффлайн установки
           build)    key_build="build";;
           # удалить внутренний архив (слишком большой для редактирования скрипта)
           null)     key_null="null";;
           # скопировать архив рядом со скриптом не распаковывая его
           extract)  key_extract="extract";;
           # запаковать внешний архив в скрипт
           pack)     key_pack="pack"; key_p_arg=$1;;
           # сделать архив и запаковать в скрипт из директории
           dir)      key_dir="dir"; key_d_arg=$1;;
           # тестирование одиночных функций
           test)     key_test="test";;
           # все остальные ключи неправильные
           *)        echo "неправильные ключи запуска";;
          esac;;

     # для ключей с -
     -*) case ${arg:1} in
          # установка pve
          i)    key_i="i";;
          # онлайн установка
          on)   key_on="on";;
          # оффлайн установка
          off)  key_off="off";;
          # сборка внутреннего архива для оффлайн установки
          b)    key_b="b";;
          # удалить внутренний архив (слишком большой для редактирования скрипта)
          n)    key_n="n";;
          # скопировать архив рядом со скриптом не распаковывая его
          x)    key_x="x";;
          # запаковать внешний архив в скрипт
          p)    key_p="p"; key_p_arg=$1;;
          # сделать архив и запаковать в скрипт из директории
          d)    key_d="d"; key_d_arg=$1;;
          # для тестирования отдельных функций
          t)    key_t="t";;
          # все остальные ключи неправильные
          *)    echo "неправильные ключи запуска";;
         esac;;
    esac
done

# вариации совместных ключей
key_all="$key_i$key_install$key_on$key_online$key_off$key_offline$key_b$key_build$key_n$key_null$key_x$key_extract$key_p$key_pack$key_d$key_dir$key_t$key_test"
case $key_all in
  # онлайн установка
  ion|ionline|installon|installonline \
             ) clear_old; install_pac online system; install_repo; install_pac online main; install_pyenv online;
               install_pve online; clear_temp;;
  # оффлайн установка
  ioff|ioffline|installoff|installoffline \
             ) clear_old; extract_archive dir; install_pac offline $sys_dir; install_pyenv offline;
               install_pve offline; clear_temp;;
  # сборка внутреннего архива для оффлайн установки
  b|build    ) create_temp_dirs; download_pac; install_pac online system; install_repo;
               install_pac online main;  install_pyenv online; download_modules; download_pyenv;
               create_arсhive archive; pack_archive $int_arch_name; clear_temp;;
  # удалить внутренний архив (слишком большой для редактирования скрипта)
  n|null     ) null_archive;;
  # скопировать архив рядом со скриптом не распаковывая его
  x|extract  ) extract_archive asis;;
  # распаковать архив в папку рядом со скриптом
  xd|xdir|extractd|extractdir \
             ) extract_archive dir;;
  # запаковать архив в скрипт
  p|pack     ) pack_archive $key_p_arg;;
  # запаковать папку в архив и включить в скрипт
  pd|pdir|packd|packdir \
             ) create_arсhive $key_d_arg; pack_archive $int_arch_name; clear_temp;;
  # test function (раздел для тестирования одиночных функций)
  t|test     ) install_pyenv online; download_modules; download_pyenv; create_arсhive archive; ;;
  # пустая строка
#t|test     ) install_pyenv online; install_pve online; clear_temp;;
  # пустая строка
  ""         ) show_description;;
  *          ) echo "неправильное сочетание ключей";;
esac

exit 0
__PAYLOAD_BEGINS__
