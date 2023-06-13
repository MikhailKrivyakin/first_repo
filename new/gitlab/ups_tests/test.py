server = "http://10.2.0.190:6182"
# параметры ТГ бота для отправки оповещения:
bot_params = "bot5919117739:AAEE44LXoWDuTy8L_ZdgIt95D_-HhOOJ3VU"
chat_id = "-1001630087101"
parse_mode="HTML"
# имена моделей, которые будут использовать при тестах каждого сервиса
sbs_model_name = "calls"
spr_model_name = "common"
smc_model_name = "test_model_from_ups"
smc_second_model = "another_test_model_for_test"
see_model_name = "fio"
# название зип архива, для тестов экспорта/импорта модели
zipfile_to_get = "/root/files_for_auto-tests/model.zip"
# название корпусов, которые будем создавать/копировать
smc_corpus_name = "test_corpus_for_test"
smc_corpus_copy_name = "copy_of_test_corpus"
smc_corpus_rename_name = "renamed_test_korpus"
# сам корпус
csv_file =  '/root/files_for_auto-tests/trud5.csv'
csv_to_recieve='/root/files_for_auto-tests/exported_corpus.csv'
# тестовый хендлер
handler = '/root/files_for_auto-tests/handler.py'
# строки по которым будет идти сравнение
example_class = "schedule_work"
example_request = "режим работы"
# файл и тестовая строка для тестов SPR
voice_file = '/root/files_for_auto-tests/test.wav'
example_string = "добрый день девушка направила вчера письмо в минпромторг хотелось бы узнать где кому оно расписано"
# переменные для тестов SBS
speaker_name="/root/files_for_auto-tests/testSpeaker"
wav_to_add='/root/files_for_auto-tests/add_speaker.wav'
wav_to_verify="/root/files_for_auto-tests/verify_speaker.wav"
wav_to_find="/root/files_for_auto-tests/find_speakers.wav"
# переменные для тестов SEE
example_entitie = "кривякин михаил"
# переменная-флаг для обозначения найденных ошибок
anyErrors = False