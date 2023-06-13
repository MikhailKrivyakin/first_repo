import requests
import difflib
import json
from zipfile import ZipFile
import os
import time

# Скрипт автотестирования сервиса SBS
# Тестировать будем 8 имеющихся методов:
# 1.  Метод /sbs/ возвращающий список моделей
# 2.  Метод анализа записи, вовзращающий данные по возрасту/полу/эмоциональному настрою говорящего /sbs/analyze
# 3.  Метод поиска в записи спикера из заранее созданного слепка /sbs/search/
# 4.  Метод добавления нового спикера /sbs/speaker/
# 5.  Метод получения списка имеющихся в модели "слепков" GET /sbs/speakers/
# 6.  Метод удаления "слепка" спикера из списка DEL /sbs/speaker/
# 7.  Метод сравнения записи с имеющимся "спикером" /sbs/verify/
# 8.  Метод /sbs/embedding/

server = "http://10.2.0.190:6185"
# параметры ТГ бота для отправки оповещения:
bot_params = "bot5919117739:AAEE44LXoWDuTy8L_ZdgIt95D_-HhOOJ3VU"
chat_id = "-1001630087101"
parse_mode="HTML"
# имя тестовой модели
default_model_name = "calls"         # имя модели по умолчанию. 
speaker_name="testSpeaker"
wav_to_add='add_speaker.wav'
wav_to_verify="verify_speaker.wav"
wav_to_find="find_speakers.wav"
# переменная-флаг для обозначения найденных ошибок
anyErrors = False
#########################################################################
# Самый простой тест -  обращаемся к сервису за списком моделей, получаем код ответа и список
#########################################################################
def get_models_list(server):
    result = requests.get(f"{server}/sbs",None)
    # получаем RC запроса
    rc = result.status_code
    # получаем список моделей для проверки наличия модели по умолчанию
    models_list=result.json().get("models")
    if 200 == rc and default_model_name in models_list:
        # если получили 200 ответ - возвращаем просто ОК и список моделей(он будет нужен для проверки других методов)
        return "OK",models_list
    else:
        # в случае если ответ !=200 вовзвращаем сообщение с ошибкой и поднимаем флаг ошибка
        global anyErrors
        anyErrors = True
        return f"ERROR, RC: {result.status_code} "
        
    
#########################################################################
# тестируем создание нового слепка спикера
#########################################################################    
def test_add_speaker(server):
    # отправляем файл на сервер для создания слепка
    result = requests.post(
            url=f"{server}/sbs/speaker/{default_model_name}/{speaker_name}",
            files={'wav': (wav_to_add, open(wav_to_add, 'rb'),'audio/wav')})
    # получаем RC запроса
    rc = result.status_code
    # заправшиваем список спикеров что бы убедиться, что добавление прошло
    gsrc,speakers_list=get_speakers_list(server)
    if rc == 200 and speaker_name in speakers_list:
        # если получили 200 ответ и спискер появился в списке - отдаем ОК
        return "OK"
    else:
        global anyErrors
        anyErrors = True
        return f"ERROR, RC: {rc}"
    
    
#########################################################################
# получаем список спикеров
#########################################################################    
def get_speakers_list(server):
    result = requests.get(f"{server}/sbs/speakers/{default_model_name}",None)
    # получаем RC запроса
    rc = result.status_code
    # получаем список спикеров для проверки наличия модели по умолчанию
    speakers_list=result.json()
    if 200 == rc:
        # если получили 200 ответ - возвращаем просто ОК и список спикеров(он будет нужен для проверки других методов)
        return "OK",speakers_list
    else:
        # в случае если ответ !=200 вовзвращаем сообщение с ошибкой и поднимаем флаг ошибка
        global anyErrors
        anyErrors = True
        return f"ERROR, RC: {result.status_code} "

#########################################################################
# сравниваем спикера с тестовым файлом
#########################################################################
def test_verify_speaker(server):
    # отправляем файл на сервер для сравнения с нужным слепком
    result = requests.post(
            url=f"{server}/sbs/verify/{default_model_name}/{speaker_name}",
            files={'wav': (wav_to_verify, open(wav_to_verify, 'rb'),'audio/wav')})
    # получаем RC запроса
    rc = result.status_code
    # переводим ответ в JSON для того, что бы вытащить данные
    result = result.json()
    if rc == 200 and result.get("confidence") > 0.5:
        # если получили 200 ответ и он более чем наполовину совпадает со слепком - все норм
        return "OK"
    else:
        global anyErrors
        anyErrors = True
        return f"ERROR, RC: {rc}"
#########################################################################
# ищем нашего спикера в разговоре
#########################################################################
def test_search_speaker(server):
    # отправляем файл на сервер для поиска в нем спикера
    result = requests.post(
            url=f"{server}/sbs/search/{default_model_name}",
            files={'wav': (wav_to_find, open(wav_to_find, 'rb'),'audio/wav')})
    # получаем RC запроса
    rc = result.status_code
    # переводим ответ в JSON для того, что бы вытащить данные
    result = result.json()
    if rc == 200 and speaker_name in result.get("speaker"):
        # если получили 200 ответ и он более чем наполовину совпадает со слепком - все норм
        return "OK"
    else:
        global anyErrors
        anyErrors = True
        return f"ERROR, RC: {rc}"
    
    
#########################################################################
# анализируем фрагмет речи
#########################################################################
def test_analyze_speaker(server):
    # отправляем файл на сервер для анализа
    result = requests.post(
            url=f"{server}/sbs/analyze/{default_model_name}",
            files={'wav': (wav_to_find, open(wav_to_find, 'rb'),'audio/wav')})
    # получаем RC запроса
    rc = result.status_code
    if rc == 200:
        # если получили 200 ответ и он более чем наполовину совпадает со слепком - все норм
        return "OK"
    else:
        global anyErrors
        anyErrors = True
        return f"ERROR, RC: {rc}"

#########################################################################
# тест метода embedding
#########################################################################
def test_embedding(server):
    # отправляем файл на сервер для анализа
    result = requests.post(
            url=f"{server}/sbs/embedding/{default_model_name}",
            files={'wav': (wav_to_find, open(wav_to_find, 'rb'),'audio/wav')})
    # получаем RC запроса
    rc = result.status_code
    if rc == 200:
        # если получили 200 ответ и он более чем наполовину совпадает со слепком - все норм
        return "OK"
    else:
        global anyErrors
        anyErrors = True
        return f"ERROR, RC: {rc}"


#########################################################################
# тестируем удаление спикера
#########################################################################
def test_delete_speaker(server):
    # удаление модели происходит простым delete запросом к серверу/имя_модели
    result = requests.delete(f"{server}/sbs/speaker/{default_model_name}/{speaker_name}")
    # получаем RC запроса
    rc = result.status_code
    # переводим запрос в JSON для того, что бы вытащить данные
    result = result.json()
    # для доп.проверки удаления запрпашиваем список моделей
    gsrc,speakers_list = get_speakers_list(server)
    # проверяем успешность
    if 200 == rc and speaker_name not in speakers_list:
        # если получили 200 ответ - возвращаем просто ОК
        return f"OK"
    else:
    # в случае если ответ !=200 вовзвращаем сообщение с ошибкой
        global anyErrors
        anyErrors = True
        return f"ERROR, RC: {rc}, Messgae: {result.get('message')}"

    


###################################
#            MAIN
###################################
# шаблон итогового сообщения боту
message = '''
Результаты тестов сервиса <b>SBS</b>:
<code>GET  /sbs/           = </code><b>{0}</b>
<code>POST /sbs/analyze/   = </code><b>{1}</b>
<code>POST /sbs/embedding/ = </code><b>{2}</b>
<code>POST /sbs/search/    = </code><b>{3}</b>
<code>DEL  /sbs/speaker/   = </code><b>{4}</b>
<code>POST /sbs/speaker/   = </code><b>{5}</b>
<code>GET  /sbs/speakers/  = </code><b>{6}</b>
<code>POST /sbs/verify/    = </code><b>{7}</b>
'''   

# получаем результаты тестирования метода /spr/ в виде RC и списка моделей
print("Test /sbs/")
sbs_test_result, models = get_models_list(server)
# добавляем модель
print("Test /sbs/data POST")
add_speker_result = test_add_speaker(server)
# запрашиваем список спикеров
print("Test /sbs/speakers GET")
get_speakers_list_result,speakers_list = get_speakers_list(server)
# тестируем сравнение спикера со слепком
print("Test POST /sbs/verify")
verify_result = test_verify_speaker(server)
# ищем спикера в разговоре
print("Test POST /sbs/search")
search_result = test_search_speaker(server)
# анализируем запись по параметрам возрас/пол/настроение
print("Test POST /sbs/analyze")
analyze_result = test_analyze_speaker(server)
#  Тестируем метод embedding
print("Test POST /sbs/emedding")
embedding_test_result = test_embedding(server)
# удаляем тестового спикера
print("Test DELELE /sbs/speaker/")
del_speaker_result = test_delete_speaker(server)
# форматируем сообщение в итоговый вариант
message = message.format(sbs_test_result, analyze_result, embedding_test_result, search_result, del_speaker_result, add_speker_result, get_speakers_list_result, verify_result)
# отправка сообщения боту
r = requests.post(f"https://api.telegram.org/{bot_params}/sendMessage?chat_id={chat_id}&text={message}&parse_mode={parse_mode}" )

# проверяем, если были какие то ошибки - завершаемся с ошибкой
if  anyErrors:
    raise SystemError("Во время тестирования были ошибки!")
else:
    raise SystemExit()