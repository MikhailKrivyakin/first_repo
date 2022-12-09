#!/bin/bash
rm *wav
rm log.file current* error.log 2>/dev/null
noise_dir="noise" #директория хранения файла с шумами
volume_koef="volume=0.6" #параметр для управления громкостью файла с шумом
files_count=`find ./ -name "*.wav" |grep -v "noise\|output" |wc -l`
printed_percent=0
#функция конвертации звука в нужный формат: wav pcm 800Гц
echo "file 'tmp_segment1.wav'
file 'tmp_segment2_muted.wav'
file 'tmp_segment3.wav' 
">list.txt
function f_convert_audio 
{
    input_file=$1
    type=$2
    duration=$3

    if [[ "$type" = "noise" ]]; #если обрабатывается файл с фоновым шумом - задаем доп параметры - обрезка, начиная с 20 секунды и уменьшение громкости
    then
        ffmpeg -v 0 -y -i $input_file -f wav -acodec pcm_s16le -ar 8000 -ac 1 -filter:a $volume_koef -ss 2000ms -t ${duration}ms current_$type.wav 2>> log.file
    else
        ffmpeg -v 0 -y -i $input_file -f wav -acodec pcm_s16le -ar 8000 -ac 1 current_$type.wav 2>> log.file
    fi

    
}
#функция "выкусывания" кусков из исходного ауидо с голосом
function f_сut_audio 
{   
    input="current_voice.wav"
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
                   # [ $begin -gt $cut_dur ] && begin=$[ $begin - $cut_dur ]
                    f_split_and_rejoin     
                    
                done
                cp $input  temp_cut.wav
        ;;
        wave)
            times_to_cut=$[ 5 + $RANDOM % 5 ]
            for ((i=0;i<$times_to_cut;i++))  
                do 
                    
                    volume=`echo | awk '{ print (rand()*1)+0.7 }' | sed 's/,/./' |cut -c 1-3`
                    cut_dur=$[ 100 + $RANDOM % 100]
                    begin=$[ $RANDOM % $duration ] 
                    #[ $begin -gt $cut_dur ] && begin=$[ $begin - $cut_dur ]
                    #command1="cp tmp_segment1.wav tmp_segment_1_1.wav; fffmpeg -y -i tmp_segment_1_1.wav -af atempo=0.95 tmp_segment1.wav 2>>/dev/null"
                    #command2=" cp tmp_segment3.wav tmp_segment3_3.wav; ffmpeg -y -i tmp_segment3_3.wav -af atempo=1.05 tmp_segment3.wav 2>>/dev/null"
                    command1="cp tmp_segment1.wav tmp_segment_1_1.wav; sox tmp_segment_1_1.wav tmp_segment1.wav tempo 0.85"
                    command2="cp tmp_segment3.wav tmp_segment3_3.wav; sox tmp_segment3_3.wav tmp_segment3.wav tempo 1.2"
                    f_split_and_rejoin "$command1" "$command2"
                    
                done
                cp $input  temp.wav
        ;;
        *) ;;
    esac
    

}
function f_split_and_rejoin #функция режет исходный файл на 3 части и соединяет обратно после обработки 2го куска
{
     
        ffmpeg -v 0 -y -i $input -f wav -acodec pcm_s16le -ar 8000 -ac 1 -t ${begin}ms tmp_segment1.wav 2>/dev/null
        eval `echo $1`
        ffmpeg -v 0 -y -i $input -f wav -acodec pcm_s16le -ar 8000 -ac 1 -ss ${begin}ms -t ${cut_dur}ms tmp_segment2.wav 2>/dev/null
        ffmpeg -v 0 -y -i $input -f wav -acodec pcm_s16le -ar 8000 -ac 1 -ss $[ $begin + $cut_dur ]ms tmp_segment3.wav 2>/dev/null      
        eval `echo $2`
        ffmpeg -v 0 -i tmp_segment2.wav -f wav -acodec pcm_s16le -ar 8000 -ac 1 -filter:a volume=$volume tmp_segment2_muted.wav 2>/dev/null
        ffmpeg -v 0 -y -f concat -safe 0 -i list.txt current_voice.wav 2>/dev/null
        ffmpeg -v 0 -y -i current_voice.wav -f wav -acodec pcm_s16le -ar 8000 -ac 1 current_voice.wav 2>> log.file
        rm tmp*
}

#функция для отображения прогресса
function f_progress
{
    output_files=`find ./output/ -name "*.wav" |wc -l`
    percents=$(( $output_files*100/$files_count ))
    case "$percents" in
        20) [ $printed_percent -eq 20 ] || echo "Текущий прогресс $percents%" && printed_percent=20;;
        50) [ $printed_percent -eq 50 ] |ssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss| echo "Текущий прогресс $percents%" && printed_percent=50;;
        75) [ $printed_percent -eq 75 ] || echo "Текущий прогресс $percents%" && printed_percent=75;;
        90) [ $printed_percent -eq 90 ] || echo "Текущий прогресс $percents%" && printed_percent=90;;
        *) ;;
    esac

}


####Main####

echo "___________________________________________________________
Найдено $files_count звуковых файлов в формате .wav.
Начинаем обработку. 
___________________________________________________________"
for file in `find ./ -name "*.wav" |grep -v 'noise\|output' `
do
    rm *wav 2>/dev/null
    [ ! -d output ] && mkdir output
    [ ! -d output/`echo $file |awk -F '\/' '{print$2}'` ] && mkdir output/`echo $file |awk -F '\/' '{print$2}'`
    duration_original=`mediainfo $file --Inform="General;%Duration%" {}`
    f_convert_audio $file voice $duration_original
    noise_file=`find ./$noise_dir -type f | ( i=0; while read line; do lines[i++]="$line"; done; echo "${lines[$RANDOM % $i]}" )` #выбираем случайный файл с шумом 
    ####################место под функцию обработки громкости #########################
    f_сut_audio "current_voice.wav" $duration_original cut
    f_сut_audio "current_voice.wav" $duration_original wave
    duration_current=`mediainfo current_voice.wav --Inform="General;%Duration%" {}`
    f_convert_audio $noise_file noise $duration_current
    ffmpeg -v 0 -y -i current_voice.wav -i current_noise.wav -filter_complex "[1][0]amerge=inputs=2[a]" -map "[a]" -ac 1 current_ready.wav 2>>log.file
    sox current_ready.wav -r 8000 -b 16 -c 1 output/${file:2} bandpass 1500 2400 2>>error.log
    [ `echo $?` -ne 0 ] && echo -e "This file had a problem during sox command:\n $file\n" >>error.log #запись имени проблемных файлов в лог
    rm current_*                                                  #удаляем текущие файлы в конце итерации
    cp `echo ${file%%.wav}`.txt ./output/`echo ${file%%.wav}`.txt #перемещение соотвествующего текстового файла в директорию
    f_progress
done
output_files_count=`find ./output/ -name "*.wav" |wc -l`
echo "___________________________________________________________
Результат: $output_files_count файлов в формате .wav. Располжены в папке output.
Спасибо, что были с нами :-)
___________________________________________________________"