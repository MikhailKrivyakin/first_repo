#!/bin/bash

product="voicetech"
dir="/opt"
packages="$dir/$product/packages"
build="$dir/$product/compiled"

function compile {

    tar -cf flora-voice.tar mrcp.tar.gz \
                            keys.tar.gz \
                            config/ \
                            integrations/internal/isTime.sh \
                            integrations/internal/functions.sh \
                            integrations/internal/biometry.sh \
                            integrations/internal/assistant.py
    gzip -9 flora-voice.tar

}

if [ "$1" == "" ]; then
    echo "Формат вызова ./build-voice.sh ОПИСАНИЕ_СБОРКИ.
    Для успешной работы скрипта рядом с ним должны находится следующие файлы:
    .version
    mrcp.tar.gz
    keys.tar.gz
    config/*
    integrations/internal/isTime.sh
    integrations/internal/functions.sh
    integrations/internal/biometry.sh
    integrations/internal/assistant.py

    "
    exit
fi

version=`cat .version`


compile

cp flora-voice flora-voice-${version}-install
cat flora-voice.tar.gz | base64 >> flora-voice-${version}-install
chmod +x flora-voice-${version}-install
rm flora-voice.tar.gz
md5sum flora-voice-${version}-install | cut -d' ' -f1 > /flora-voice-${version}-install.md5sum

echo "$1" > flora-voice-${version}-install.description
