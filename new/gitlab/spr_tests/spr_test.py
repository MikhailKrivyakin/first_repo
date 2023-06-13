import requests
import difflib
import json
from zipfile import ZipFile
import os

# Скрипт автотестирования сервиса SPR
# Тестирповать будем все 5 имеющихся методов:
# 1. Метод /spr/ возвращающий список моделей
# 2. Метод Удаление модели /spr/data DELETE
# 3. Метод добавления модели /spr/data/ POST
# 4. Метод получения модели /spr/data/ GET
# 5. Метод расознования /spr/stt/

server = "http://10.2.0.190:6183"
bot_params = "bot5919117739:AAEE44LXoWDuTy8L_ZdgIt95D_-HhOOJ3VU"
chat_id = "-1001630087101"
model_name = "very-new-model"
zipfile =  '/root/files_for_auto-tests/model.zip'
zipfile_to_get = '/root/files_for_auto-tests/test_model_spr.zip'
voice_file = '/root/files_for_auto-tests/test.wav'
example_string = "добрый день девушка направила вчера письмо в минпромторг хотелось бы узнать где кому оно расписано"
parse_mode="HTML"
# переменная-флаг для обозначения найденных ошибок
anyErrors = False
#########################################################################
# Самый простой тест -  обращаемся к сервису за списком моделей, получаем код ответа и список
#########################################################################
def get_models_list(url):
    result = requests.get(f"{server}/spr",None)
    # получаем RC запроса
    rc = result.status_code
    if 200 == rc:
        # если получили 200 ответ - возвращаем просто ОК и список моделей(он будет нужен для проверки других методов)
        return "OK",result.json().get("models")
    else:
        # в случае если ответ !=200 вовзвращаем сообщение с ошибкой и поднимаем флаг ошибка
        global anyErrors
        anyErrors = True
        return f"ERROR, RC: {result.status_code} "
        
    
#########################################################################
# тестируем добавление модели на сервер. 
#########################################################################
def test_add_model(server):
        # отправляем ПОСТ запрос на сервер
         result = requests.post(
            url=f"{server}/spr/data/{model_name}",
            files={'zip-model': ('model.zip', open(zipfile, 'rb'),'application/zip')})
        # получаем RC запроса
         rc = result.status_code
        # переводим запрос в JSON для того, что бы вытащить данные
         result = result.json()
         if 200 == rc:
            # если получили 200 ответ - возвращаем просто ОК
            return f"OK"
         else:
            # в случае если ответ !=200 вовзвращаем сообщение с ошибкой
            global anyErrors
            anyErrors = True
            return f"ERROR, RC: {rc}, Messgae: {result.get('message')}"
        
        
#########################################################################
# тестируем удаление модели
#########################################################################
def test_delete_model(server):
    # удаление модели происходит простым delete запросом к серверу/имя_модели
    result = requests.delete(f"{server}/spr/data/{model_name}")
    # получаем RC запроса
    rc = result.status_code
    # переводим запрос в JSON для того, что бы вытащить данные
    result = result.json()
    # для доп.проверки удаления запрпашиваем список моделей
    gml_rc,models_list = get_models_list(server)
    # проверяем успешность
    if 200 == rc and model_name not in models_list:
        # если получили 200 ответ - возвращаем просто ОК
        return f"OK"
    else:
    # в случае если ответ !=200 вовзвращаем сообщение с ошибкой
        global anyErrors
        anyErrors = True
        return f"ERROR, RC: {rc}, Messgae: {result.get('message')}"

#########################################################################
# тестируем получемние зип.файла с моделью
#########################################################################
def test_get_model(server):
    # удаление модели происходит простым delete запросом к серверу/имя_модели
    result = requests.get(f"{server}/spr/data/{model_name}")
    # пишем в файл пришедший ответ
    with open(f"{zipfile_to_get}",'wb') as f:
        f.write(result.content)
    # получаем RC запроса
    rc = result.status_code
    # введем дополнительное грубое сравнение. Будем сравнивать размер полученного файла с исходным
    compare = os.stat(zipfile_to_get).st_size == os.stat(zipfile).st_size
    if 200 == rc and compare:
        # если получили 200 ответ - возвращаем просто ОК и удаляем файл
        os.remove(zipfile_to_get)
        return f"OK"
    else:
        # в случае если ответ !=200 вовзвращаем сообщение с ошибкой
        global anyErrors
        anyErrors = True
        os.remove(zipfile_to_get)
        return f"ERROR, RC: {rc}"
    
    
#########################################################################
# тестируем расознование 
##########################################################################
def test_recognition(server):
    data = open(voice_file, 'rb')  
    headers = {'content-type': 'audio/wav'}
    result= requests.post(f"{server}/spr/stt/{model_name}", data=data, headers=headers)
    # получаем RC запроса
    rc = result.status_code
    # переводим запрос в JSON для того, что бы вытащить данные
    result = result.json()
    recognised = result["text"]
    matcher = difflib.SequenceMatcher(None, recognised, example_string)
    if matcher.ratio() > 0.8 and rc == 200:
        # если получили 200 ответ и полученная строка совпадает с тестовой хотя бы на 80% - возвращаем просто ОК 
        return "OK"
    else:
        global anyErrors
        anyErrors = True
        return f"ERROR, RC: {rc}"
    
###################################
#            MAIN
###################################
# шаблон итогового сообщения боту
message = '''
Результаты тестов сервиса SPR:
    GET       /spr/       = <b>{0}</b>
    POST     /spr/data/  = <b>{1}</b>
    GET       /spr/data/  = <b>{2}</b>
    POST     /spr/stt    = <b>{3}</b>
    DELETE   /spr/data/  = <b>{4}</b>
'''   
# получаем результаты тестирования метода /spr/ в виде RC и списка моделей
spr_test_result, models = get_models_list(server)
# добавляем модель
add_model_result = test_add_model(server)
# тестируем получение архива с моделью
get_model_result = test_get_model(server)
# тестируем распознавание
recognition_result = test_recognition(server)
# удаляем модель 
delete_model_result = test_delete_model(server)
# форматируем сообщение в итоговый вариант
message = message.format(spr_test_result, add_model_result, get_model_result, recognition_result, delete_model_result)
# отправка сообщения боту
r = requests.post(f"https://api.telegram.org/{bot_params}/sendMessage?chat_id={chat_id}&text={message}&parse_mode={parse_mode}" )

# проверяем, если были какие то ошибки - завершаемся с ошибкой
if  anyErrors:
    raise SystemError("Во время тестирования были ошибки!")
else:
    raise SystemExit()