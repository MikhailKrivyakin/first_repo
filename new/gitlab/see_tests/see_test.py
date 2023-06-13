import requests
import difflib
import json
from zipfile import ZipFile
import os
import time

# Скрипт автотестирования сервиса SEE
# Тестировать будем 9 имеющихся методов:
# 1. Метод /see/ возвращающий список моделей
# 2. Метод Удаление модели /see/data DELETE
# 3. Метод добавления модели /see/data/ POST в 2х вариациях - с загрузкой готовой модели и обучением из корпуса
# 4. Метод получения модели /see/data/ GET
# 5. Метод получения матрицы (train и test) /spr/confusion/
# 6. Метод получения лога модели /see/log/
# 7. Метод получения информации о модели /see/info/
# 8. Метод получения информации об ошибках модели /see/errors/
# 9. Метод вычленения сущности из фразы /see/entities/

server = "http://10.2.0.190:6184"
# параметры ТГ бота для отправки оповещения:
bot_params = "bot5919117739:AAEE44LXoWDuTy8L_ZdgIt95D_-HhOOJ3VU"
chat_id = "-1001630087101"
parse_mode="HTML"
# имя тестовой модели
model_name = "very-new-model" # имя основной модели для тестов
model_name1 = "very-new-model-b-zip" # имя модели, которую будем добавлять архивом, что бы не мешались друг другу
# корпус для обучения
csv_file =  '/root/files_for_auto-tests/trud5.csv'
# имя под которым будем скачивать обученную модель
zipfile_to_get = '/root/files_for_auto-tests/test_model_see.zip'
# тестовый хендлер
handler = '/root/files_for_auto-tests/handler.py'
# строки по которым будет идти сравнение
example_entitie = "schedule_work"
example_request = "режим работы"
# переменная-флаг для обозначения найденных ошибок
anyErrors = False
#########################################################################
# Самый простой тест -  обращаемся к сервису за списком моделей, получаем код ответа и список
#########################################################################
def get_models_list(url):
    result = requests.get(f"{server}/see",None)
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
# тестируем обучение модели на сервере тестовым CSV корпусом
#########################################################################
def test_add_model_by_csv(server):
        # отправляем ПОСТ запрос на сервер
         result = requests.post(
            url=f"{server}/see/data/{model_name}",
            files={'csv': ('trud5.csv', open(csv_file, 'rb'),'text/csv')})
        # получаем RC запроса
         rc = result.status_code
        # переводим запрос в JSON для того, что бы вытащить данные
         result = result.json()
        # для доп.проверки удаления запрпашиваем список моделей
         gml_rc,models_list = get_models_list(server)
         if 200 == rc and model_name in models_list:
            # если получили 200 ответ - возвращаем просто ОК и ждем 5 минут до завршения обучения
            print("Ложимся спать на 5 минут, пока модель учится")
            time.sleep(300)
            # после 5 минут ожидания проверяем обучилась ли модель:
            girc, info = test_get_info(server)
            if info.get('status') == "training":
                print("Модель еще учится, ложимся спать еще на 5 минут")
                time.sleep(300)
            return f"OK"
         else:
            # в случае если ответ !=200 вовзвращаем сообщение с ошибкой
            global anyErrors
            anyErrors = True
            return f"ERROR, RC: {rc}, Messgae: {result.get('message')}"


#########################################################################
# тестируем добавление модели на сервер зип архивоми и сразу же удаляем её
#########################################################################
def test_add_model_by_zip(server):
        # отправляем ПОСТ запрос на сервер
         result = requests.post(
            url=f"{server}/see/data/{model_name1}",
            files={'zip-model': ('model.zip', open(zipfile_to_get, 'rb'),'application/zip')})
        # получаем RC запроса
         rc = result.status_code
        # для доп.проверки удаления запрпашиваем список моделей
         gml_rc,models_list = get_models_list(server)
         if 200 == rc and model_name1 in models_list:
            # если получили 200 ответ - возвращаем просто ОК и удаляем модель
            result = requests.delete(f"{server}/see/data/{model_name1}")
            os.remove(zipfile_to_get)
            return f"OK"
         else:
            # в случае если ответ !=200 вовзвращаем сообщение с ошибкой
            global anyErrors
            anyErrors = True
            os.remove(zipfile_to_get)
            return f"ERROR, RC: {rc}, Messgae: {result.get('message')}"
        
        
#########################################################################
# тестируем удаление модели
#########################################################################
def test_delete_model(server):
    # удаление модели происходит простым delete запросом к серверу/имя_модели
    result = requests.delete(f"{server}/see/data/{model_name}")
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
    result = requests.get(f"{server}/see/data/{model_name}")
    # пишем в файл пришедший ответ
    with open(f"{zipfile_to_get}",'wb') as f:
        f.write(result.content)
    # получаем RC запроса
    rc = result.status_code
    if 200 == rc:
        # если получили 200 ответ - возвращаем просто ОК и удаляем файл
        return f"OK"
    else:
        # в случае если ответ !=200 вовзвращаем сообщение с ошибкой
        global anyErrors
        anyErrors = True
        return f"ERROR, RC: {rc}"
    
    
#########################################################################
# тестируем  получение информации о модели
##########################################################################
def test_get_info(server):
    result = requests.get(f"{server}/see/info/{model_name}",None)
    # получаем RC запроса
    rc = result.status_code
    # переводим ответ в JSON
    result = result.json()
    if 200 == rc:
        # если получили 200 ответ - возвращаем просто ОК 
        return "OK", result
    else:
        # в случае если ответ !=200 вовзвращаем сообщение с ошибкой и поднимаем флаг ошибка
        global anyErrors
        anyErrors = True
        return f"ERROR, RC: {result.status_code} "
    
#########################################################################
# тестируем  получение лога модели
##########################################################################
def test_get_log_info(server):
    result = requests.get(f"{server}/see/log/{model_name}",None)
    # получаем RC запроса
    rc = result.status_code
    if 200 == rc:
        # если получили 200 ответ - возвращаем просто ОК 
        return "OK"
    else:
        # в случае если ответ !=200 вовзвращаем сообщение с ошибкой и поднимаем флаг ошибка
        global anyErrors
        anyErrors = True
        return f"ERROR, RC: {result.status_code} "
    
#########################################################################
# тестируем  получение информации об ошибках модели
##########################################################################
def test_get_errors_info(server):
    result = requests.get(f"{server}/see/errors/{model_name}",None)
    # получаем RC запроса
    rc = result.status_code
    if 200 == rc:
        # если получили 200 ответ - возвращаем просто ОК 
        return "OK"
    else:
        # в случае если ответ !=200 вовзвращаем сообщение с ошибкой и поднимаем флаг ошибка
        global anyErrors
        anyErrors = True
        return f"ERROR, RC: {result.status_code}"
    
#########################################################################
# тестируем  получение сущности обученой моделью
##########################################################################
def test_get_entities(server):
    params = {"text": f"{example_request}"}
    result = requests.get(f"{server}/see/entities/{model_name}",params)
    # получаем RC запроса
    rc = result.status_code
    entitie = (result.json()[f"{model_name}"][0]["calculated"])
    if 200 == rc and entitie == example_entitie:
        # если получили 200 ответ - возвращаем просто ОК 
        return "OK"
    else:
        # в случае если ответ !=200 вовзвращаем сообщение с ошибкой и поднимаем флаг ошибка
        global anyErrors
        anyErrors = True
        return f"ERROR, RC: {result.status_code}"
    

#########################################################################
# тестируем  получение матриц
##########################################################################
def test_get_matrix(server):
    # запрос для получения тренировочной матрицы
    result = requests.get(f"{server}/see/confusion/{model_name}/train")
    # получаем RC запроса
    rc = result.status_code
    if 200 == rc:
        # если получили 200 ответ - возвращаем просто ОК 
        return "OK"
    else:
        # в случае если ответ !=200 вовзвращаем сообщение с ошибкой и поднимаем флаг ошибка
        global anyErrors
        anyErrors = True
        return f"ERROR, RC: {result.status_code}"
#########################################################################
# добавляем хендлер
##########################################################################
def add_handler(server):
     # отправляем ПОСТ запрос на сервер
         result = requests.post(
            url=f"{server}/see/handler/{model_name}",
            files={'handler': (handler, open(handler, 'rb'),'text/csv')})
        # получаем RC запроса
         rc = result.status_code
        # переводим запрос в JSON для того, что бы вытащить данные
         result = result.json()
         print(result)
         if 200 == rc:
            return f"OK"
         else:
            # в случае если ответ !=200 вовзвращаем сообщение с ошибкой
            global anyErrors
            anyErrors = True
            return f"ERROR, RC: {rc}, Messgae: {result.get('message')}"
#########################################################################
# проверяем список хендлеров
##########################################################################
def get_handler(server):
    result = requests.get(f"{server}/see/handler/{model_name}",None)
    # получаем RC запроса
    rc = result.status_code
    if 200 == rc:
        # если получили 200 ответ - возвращаем просто ОК и список моделей(он будет нужен для проверки других методов)
        return "OK"
    else:
        # в случае если ответ !=200 вовзвращаем сообщение с ошибкой и поднимаем флаг ошибка
        global anyErrors
        anyErrors = True
        return f"ERROR, RC: {rc} " 
#########################################################################
# удаляем хендлер
##########################################################################      
def delete_handler(server):
    result = requests.delete(f"{server}/see/handler/{model_name}")
    # получаем RC запроса
    rc = result.status_code
    if 200 == rc:
        # если получили 200 ответ - возвращаем просто ОК и список моделей(он будет нужен для проверки других методов)
        return "OK"
    else:
        # в случае если ответ !=200 вовзвращаем сообщение с ошибкой и поднимаем флаг ошибка
        global anyErrors
        anyErrors = True
        return f"ERROR, RC: {rc} "     



###################################
#            MAIN
###################################
# шаблон итогового сообщения боту
message = '''
Результаты тестов сервиса <b>SEE</b>:
<code>GET  /see/           = </code><b>{0}</b>
<code>POST /see/data/      = </code><b>{1}</b>
<code>GET  /see/data/      = </code><b>{2}</b>
<code>GET  /see/confusion/ = </code><b>{3}</b>
<code>DEL  /see/data/      = </code><b>{4}</b>
<code>GET  /see/classify/  = </code><b>{5}</b>
<code>GET  /see/errors/    = </code><b>{6}</b>
<code>GET  /see/info/      = </code><b>{7}</b>
<code>GET  /see/logs/      = </code><b>{8}</b>
<code>POST /see/handler/   = </code><b>{9}</b>
<code>GET  /see/handler/   = </code><b>{10}</b>
<code>DEL  /see/handler/   = </code><b>{11}</b>
'''   
# получаем результаты тестирования метода /spr/ в виде RC и списка моделей
print("Test /see/")
see_test_result, models = get_models_list(server)
# добавляем модель
print("Test /see/data POST csv")
add_model_by_csv_result = test_add_model_by_csv(server)
# тестируем получение архива с моделью
print("Test /see/data GET")
get_model_result = test_get_model(server)
# тестируем получение сущности
entitie_result = test_get_entities(server)
# тестируем получение матрицы
print("Test /see/confusion/ GET")
matrix_result = test_get_matrix(server)
# тестируем получение лога
print("Test /see/log/ GET")
log_result = test_get_log_info(server)
# тестируем получение ошибок
print("Test /see/errors/ GET")
error_result = test_get_errors_info(server)
# тестируем получение инфы о модели
print("Test /see/info/ GET")
info_result,info_data = test_get_info(server)
# тестируем добавление модели из ЗИП архива
print("Test /see/data POST by zip")
zip_result = test_add_model_by_zip(server)
# тестируем добавление хенлера
print("Test /smc/handler POST")
add_handler_result = add_handler(server)
# тестируем получение хендлера
print("Test /smc/handler GET")
zip_result = get_handler(server)
# тестируем удаление хендлера
print("Test /smc/handler DELETE")
zip_result = delete_handler(server)
# удаляем модель 
print("Test /see/data DELETE")
delete_model_result = test_delete_model(server)
# форматируем сообщение в итоговый вариант
message = message.format(see_test_result, add_model_by_csv_result, get_model_result, matrix_result, delete_model_result, entitie_result, error_result, info_result, log_result, add_handler_result, get_model_result,delete_model_result)
# отправка сообщения боту
r = requests.post(f"https://api.telegram.org/{bot_params}/sendMessage?chat_id={chat_id}&text={message}&parse_mode={parse_mode}" )

# проверяем, если были какие то ошибки - завершаемся с ошибкой
if  anyErrors:
    raise SystemError("Во время тестирования были ошибки!")
else:
    raise SystemExit()