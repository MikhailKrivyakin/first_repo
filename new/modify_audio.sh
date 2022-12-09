#!/bin/bash
##  для работы скрипта необходимы пакеты sox ffmpeg parallel
##
rm *wav* 2>/dev/null                                #удаляем ненужные wav перед запуском скрипта
rm log.file error.log   2>/dev/null                 #удалить старые логи
export noise_dir="noise"                            #директория хранения файла с шумами
export volume_koef="volume=0.5"                     #параметр для управления громкостью файла с шумом
export JOBS_COUNT=10                                #количество одновременно обрабатываемых файлов. По умолчанию - 8.
export SOX_TEMPO_MIN=0.95                           #границы интервала ускорения/замедления голоса
export SOX_TEMPO_MAX=1.05                           #



function f_main
{   
    file=`echo ${1}|sed "s/.\///"`
    dictor=`echo $file | awk -F '\/' '{print $1}'`
    filename=`echo $file | awk -F '\/' '{print $2}'`
    #cp $file ./ 
     echo "file 'tmp_segment1_current_voice_$filename'
file 'tmp_segment2_muted_current_voice_$filename'
file 'tmp_segment3_current_voice_$filename' 
    ">list_$filename.txt                            #создание файла по которому ffmpeg будет выполнять слияние
    [ ! -d output ] && mkdir output
    [ ! -d output/$dictor ] && mkdir output/$dictor
    duration_original=`mediainfo $file --Inform="General;%Duration%" {}`
    f_convert_audio $file voice $duration_original
    noise_file=`find ./$noise_dir -type f | ( i=0; while read line; do lines[i++]="$line"; done; echo "${lines[$RANDOM % $i]}" )` #выбираем случайный файл с шумом 
     ####################место под функцию обработки громкости #########################
    f_сut_audio "current_voice_$filename" "$duration_original" "cut"
    f_сut_audio "current_voice_$filename" "$duration_original" "wave"
    duration_current=`mediainfo current_voice_$filename --Inform="General;%Duration%" {}`
    f_convert_audio "${noise_file:2}" "noise" "$duration_current"
    ffmpeg -v 0 -y -i current_voice_$filename -i current_noise_$filename -filter_complex "[1][0]amerge=inputs=2[a]" -map "[a]" -ac 1 current_ready_$filename 2>>log.file
    sox current_ready_$filename -r 8000 -b 16 -c 1 output/$dictor/$filename bandpass 1500 2400 2>>error.log
    [ `echo $?` -ne 0 ] && echo -e "This file had a problem during sox command:\n $file\n" >>error.log #запись имени проблемных файлов в лог
    rm current_*_$filename* list_$filename.txt   2>/dev/null                                              #удаляем текущие файлы в конце итерации
    cp `echo ${file%%.wav}`.txt ./output/`echo ${file%%.wav}`.txt                                         #перемещение соотвествующего текстового файла в директорию
   
 
}


#функция конвертации звука в нужный формат: wav pcm 800Гц
function f_convert_audio 
{
    input_file=$1
    type=$2
    duration=$3

    if [[ "$type" = "noise" ]]; #если обрабатывается файл с фоновым шумом - задаем доп параметры - обрезка, начиная с 20 секунды и уменьшение громкости
    then
        
        ffmpeg -v 0 -y -i $input_file -f wav -acodec pcm_s16le -ar 8000 -ac 1 -filter:a $volume_koef -ss 2000ms -t ${duration}ms current_${type}_$filename 2>> log.file
    else
        
        ffmpeg -v 0 -y -i $input_file -f wav -acodec pcm_s16le -ar 8000 -ac 1 current_${type}_$filename 2>> log.file
    fi

    
}
#функция "выкусывания" кусков из исходного ауидо с голосом
function f_сut_audio 
{   
    input=$1
    duration=$2
    to_do=$3
    case "$to_do" in
        cut)
            volume=0
            times_to_cut=$[ 50 + $RANDOM % 50 ]
            for ((i=0;i<$times_to_cut;i++)) 
                do 
                    
                    cut_dur=$[ 5 + $RANDOM % 15 ]
                    begin=$[ $RANDOM % $duration ] 
                    f_split_and_rejoin     
                    ffmpeg -v 0 -y -i $input -f wav -acodec pcm_s16le -ar 8000 -ac 1 $input>> log.file
                done
                
        ;;
        wave)
            times_to_cut=$[ 5 + $RANDOM % 5 ]
            for ((i=0;i<$times_to_cut;i++))  
                do 
                    
                    volume=`echo | awk '{ print rand()+0.5 }' | sed 's/,/./' |cut -c 1-3`
                    cut_dur=$[ 100 + $RANDOM % 100]
                    begin=$[ $RANDOM % $duration ] 
                    command1="cp tmp_segment1_$input tmp_segment_1_1_$input; sox tmp_segment_1_1_$input tmp_segment1_$input tempo $SOX_TEMPO_MIN"
                    command2="cp tmp_segment3_$input tmp_segment3_3_$input; sox tmp_segment3_3_$input tmp_segment3_$input tempo $SOX_TEMPO_MAX"
                    f_split_and_rejoin "$command1" "$command2"
                    ffmpeg -v 0 -y -i $input -f wav -acodec pcm_s16le -ar 8000 -ac 1 $input>> log.file
                done
                
        ;;
        *) ;;
    esac
    

}
function f_split_and_rejoin #функция режет исходный файл на 3 части и соединяет обратно после обработки 2го куска
{       
        
        ffmpeg -v 0 -y -i $input -f wav -acodec pcm_s16le -ar 8000 -ac 1 -t ${begin}ms tmp_segment1_$input 2>/dev/null
        eval `echo $1`
        ffmpeg -v 0 -y -i $input -f wav -acodec pcm_s16le -ar 8000 -ac 1 -ss ${begin}ms -t ${cut_dur}ms tmp_segment2_$input 2>/dev/null
        ffmpeg -v 0 -y -i $input -f wav -acodec pcm_s16le -ar 8000 -ac 1 -ss $[ $begin + $cut_dur ]ms tmp_segment3_$input 2>/dev/null      
        eval `echo $2`
        ffmpeg -v 0 -y -i tmp_segment2_$input -f wav -acodec pcm_s16le -ar 8000 -ac 1 -filter:a volume=$volume tmp_segment2_muted_$input 2>/dev/null
        ffmpeg -v 0 -y -f concat -safe 0 -i list_$filename.txt $input #2>/dev/null
        
        rm tmp_*$input
}





#экспорт функция для того что бы с ними смогла работать parallel 
export -f f_convert_audio
export -f f_main
export -f f_split_and_rejoin
export -f f_сut_audio

####Main####
echo "___________________________________________________________
Найдено `find ./ -name "*.wav" |grep -v "noise\|output" |wc -l` звуковых файлов в формате .wav.
Начинаем обработку. 
___________________________________________________________"

find ./ -name "*.wav" |grep -v 'noise\|output' |parallel --j $JOBS_COUNT f_main         #вызов основной функции в параллель на несколько потоков


echo "___________________________________________________________
Результат: `find ./output/ -name "*.wav" |wc -l` файлов в формате .wav. Располжены в папке output.
Спасибо, что были с нами :-)
___________________________________________________________"