#!/bin/bash
rm log.file 2>/dev/null
noise_dir="noise" #директория хранения файла с шумами
volume_koef="volume=0.7" #параметр для управления громкостью файла с шумом
files_count=`find ./ -name "*.wav" |grep -v noise |wc -l`
#функция конвертации звука в нужный формат: wav pcm 800Гц
function f_convert_audio 
{
    input_file=$1
    type=$2
    duration=$3

    if [[ "$type" = "noise" ]]; #если обрабатывается файл с фоновым шумом - задаем доп параметры - обрезка, начиная с 20 секунды и уменьшение громкости
    then
        ffmpeg -i $input_file -f wav -acodec pcm_s16le -ar 8000 -ac 1 -filter:a $volume_koef -ss 2000ms -t ${duration}ms current_$type.wav 2>> log.file
        #echo "$input_file будет обрезан до ${duration} потому что его тип $type "
        #echo "ffmpeg -i $input_file -f wav -acodec pcm_s16le -ar 8000 -ac 1 -filter:a $volume_koef -ss 2000ms -t ${duration}ms current_$type.wav"
    else
        ffmpeg -i $input_file -f wav -acodec pcm_s16le -ar 8000 -ac 1 current_$type.wav 2>> log.file
    fi

    
}

function f_progress
{
    output_files_count=`find ./output/ -name "*.wav" |wc -l`
    percents=$(( $output_files_count*100/$files_count ))
    case $percents in
        20) echo "Текущий прогресс $percents%";;
        50) echo "Текущий прогресс $percents%";;
        75) echo "Текущий прогресс $percents%";;
        90) echo "Текущий прогресс $percents%...Почти готово.";;
        *) ;;
    esac

}


####Main####

echo "___________________________________________________________
Найдено $files_count звуковых файлов в формате .wav.
Начинаем обработку. Результат будет сохранен в файле log.file
___________________________________________________________"
for file in `find ./ -name "*.wav" |grep -v 'noise\|output' `
do
    
    [ ! -d output ] && mkdir output
    [ ! -d output/`echo $file |awk -F '\/' '{print$2}'` ] && mkdir output/`echo $file |awk -F '\/' '{print$2}'`
    f_convert_audio $file voice
    duration=`mediainfo $file --Inform="General;%Duration%" {}`
    noise_file=`find ./$noise_dir -type f | ( i=0; while read line; do lines[i++]="$line"; done; echo "${lines[$RANDOM % $i]}" )` #выбираем случайный файл с шумом 
    f_convert_audio $noise_file noise $duration
    #на этом этапе есть 2 файла: curren_voice и current_noise. сливаем их в один и прогоняем результат через основвную sox команду для получения результата
    #ffmpeg -i current_voice.wav -i current_noise.wav -filter_complex "[1][0]amerge=inputs=2[a]" -map "[a]" -ac 1 output/${file:2} 2>>log.file
    ffmpeg -i current_voice.wav -i current_noise.wav -filter_complex "[1][0]amerge=inputs=2[a]" -map "[a]" -ac 1 current_ready.wav 2>>log.file
    sox current_ready.wav -r 8000 -b 16 -c 1 output/${file:2} bandpass 1500 2400 
    rm current_*                                                  #удаляем текущие файлы в конце итерации
    cp `echo ${file%%.wav}`.txt ./output/`echo ${file%%.wav}`.txt #перемещение соотвествующего текстового файла в директорию
    f_progress
done
output_files_count=`find ./output/ -name "*.wav" |wc -l`
echo "___________________________________________________________
Результат: $output_files_count файлов в формате .wav. Располжены в папке output.
Спасибо, что были с нами :-)
___________________________________________________________"