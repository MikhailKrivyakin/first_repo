import requests
import difflib
import json
from zipfile import ZipFile
import os
import time

# Скрипт автотестирования сервиса SMC
# Тестировать будем 10 имеющихся методов:
# 1.  Метод /smc/ возвращающий список моделей
# 2.  Метод Удаление модели /smc/data DELETE
# 3.  Метод добавления модели /smc/data/ POST в 2х вариациях - с загрузкой готовой модели и обучением из корпуса
# 4.  Метод получения модели /smc/data/ GET
# 5.  Метод получения матрицы (train и test) /spr/confusion/
# 6.  Метод получения лога модели /smc/log/
# 7.  Метод получения информации о модели /smc/info/
# 8.  Метод получения информации об ошибках модели /smc/errors/
# 9.  Метод вычленения класса из фразы /smc/classify/
# 10. Метод тестирования корпуса

server = "http://10.2.0.190:6181"
# параметры ТГ бота для отправки оповещения:
bot_params = "bot5919117739:AAEE44LXoWDuTy8L_ZdgIt95D_-HhOOJ3VU"
chat_id = "-1001630087101"
parse_mode="HTML"
# имя тестовой модели
model_name = "very-new-model" # имя основной модели для тестов
model_name1 = "very-new-model-b-zip" # имя модели, которую будем добавлять архивом, что бы не мешались друг другу
# корпус для обучения
csv_file =  '/root/files_for_auto-tests/trud5.csv'
# тестовый хендлер
handler = '/root/files_for_auto-tests/handler.py'
# имя под которым будем скачивать обученную модель
zipfile_to_get = '/root/files_for_auto-tests/test_model_smc.zip'
# строки по которым будет идти сравнение
example_entitie = "schedule_work"
example_request = "режим работы"
# переменная-флаг для обозначения найденных ошибок
anyErrors = False
#########################################################################
# Самый простой тест -  обращаемся к сервису за списком моделей, получаем код ответа и список
#########################################################################
def get_models_list(url):
    result = requests.get(f"{server}/smc",None)
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
            url=f"{server}/smc/data/{model_name}",
            files={'csv-file': ('trud5.csv', open(csv_file, 'rb'),'text/csv')})
        # получаем RC запроса
         rc = result.status_code
        # переводим запрос в JSON для того, что бы вытащить данные
         result = result.json()
         if 200 == rc:
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
            url=f"{server}/smc/data/{model_name1}",
            files={'zip-model': ('model.zip', open(zipfile_to_get, 'rb'),'application/zip')})
        # получаем RC запроса
         rc = result.status_code
        # для доп.проверки удаления запрпашиваем список моделей
         gml_rc,models_list = get_models_list(server)
         if 200 == rc and model_name1 in models_list:
            # если получили 200 ответ - возвращаем просто ОК и удаляем модель
            result = requests.delete(f"{server}/smc/data/{model_name1}")
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
    result = requests.delete(f"{server}/smc/data/{model_name}")
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
    result = requests.get(f"{server}/smc/data/{model_name}")
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
    result = requests.get(f"{server}/smc/info/{model_name}",None)
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
    result = requests.get(f"{server}/smc/log/{model_name}",None)
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
    result = requests.get(f"{server}/smc/errors/{model_name}",None)
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
# тестируем  получение класса  обученой моделью
##########################################################################
def test_get_class(server):
    params = {"text": f"{example_request}"}
    result = requests.get(f"{server}/smc/classify/{model_name}",params)
    # получаем RC запроса
    rc = result.status_code
    entitie = (result.json()["calculated"])
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
    result_train = requests.get(f"{server}/smc/confusion/{model_name}/train")
    # получаем RC запроса
    rc_train = result_train.status_code
    # запрос для получения тестовой матрицы
    result_test = requests.get(f"{server}/smc/confusion/{model_name}/test")
    # получаем RC запроса
    rc_test = result_test.status_code
    if 200 == rc_train == rc_test:
        # если получили 200 ответ - возвращаем просто ОК 
        return "OK"
    else:
        # в случае если ответ !=200 вовзвращаем сообщение с ошибкой и поднимаем флаг ошибка
        global anyErrors
        anyErrors = True
        return f"ERROR, RC_train: {rc_train}, RC_test: {rc_test}"

#########################################################################
# тестируем  модель корпусом 
##########################################################################
def test_model_by_csv(server):
    # отправляем ПОСТ запрос на сервер
         result = requests.post(
            url=f"{server}/smc/test/{model_name}",
            files={'csv-file': ('trud5.csv', open(csv_file, 'rb'),'text/csv')})
        # получаем RC запроса
         rc = result.status_code
        # переводим запрос в JSON для того, что бы вытащить данные
         result = result.json()
         if 200 == rc:
            # если получили 200 ответ - возвращаем просто ОК и ждем 2 минуты до завршения тестирования
            print("Ложимся спать на 2 минуты, пока модель тестируется")
            time.sleep(120)
            # после 5 минут ожидания проверяем обучилась ли модель:
            girc, info = test_get_info(server)
            if info.get('status') == "testing":
                print("Модель еще тестируется, ложимся спать еще на 2 минуты")
                time.sleep(120)
            return f"OK"
         else:
            # в случае если ответ !=200 вовзвращаем сообщение с ошибкой
            global anyErrors
            anyErrors = True
            return f"ERROR, RC: {rc}, Message: {result.get('message')}"
#########################################################################
# добавляем хендлер
##########################################################################
def add_handler(server):
     # отправляем ПОСТ запрос на сервер
         result = requests.post(
            url=f"{server}/smc/handler/{model_name}",
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
    result = requests.get(f"{server}/smc/handler/{model_name}",None)
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
    result = requests.delete(f"{server}/smc/handler/{model_name}")
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
Результаты тестов сервиса <b>SMC</b>:
<code>GET  /smc/           = </code><b>{0}</b>
<code>POST /smc/data/      = </code><b>{1}</b>
<code>GET  /smc/data/      = </code><b>{2}</b>
<code>GET  /smc/confusion/ = </code><b>{3}</b>
<code>DEL  /smc/data/      = </code><b>{4}</b>
<code>GET  /smc/classify/  = </code><b>{5}</b>
<code>GET  /smc/errors/    = </code><b>{6}</b>
<code>GET  /smc/info/      = </code><b>{7}</b>
<code>GET  /smc/logs/      = </code><b>{8}</b>
<code>POST /smc/test/      = </code><b>{9}</b>
<code>POST /smc/handler/   = </code><b>{10}</b>
<code>GET  /smc/handler/   = </code><b>{11}</b>
<code>DEL  /smc/handler/   = </code><b>{12}</b>
'''   

# получаем результаты тестирования метода /spr/ в виде RC и списка моделей
print("Test /smc/")
smc_test_result, models = get_models_list(server)
# добавляем модель
print("Test /smc/data POST csv")
add_model_by_csv_result = test_add_model_by_csv(server)
# тестируем получение архива с моделью
print("Test /smc/data GET")
get_model_result = test_get_model(server)
# тестируем получение класса
print("Test /smc/classify GET")
entitie_result = test_get_class(server)
# тестируем модель корпусом
print("Test smc/test POST")
test_model_result=test_model_by_csv(server)
# тестируем получение матрицы
print("Test /smc/confusion/ GET")
matrix_result = test_get_matrix(server)
# тестируем получение лога
print("Test /smc/log/ GET")
log_result = test_get_log_info(server)
# тестируем получение ошибок
print("Test /smc/errors/ GET")
error_result = test_get_errors_info(server)
# тестируем получение инфы о модели
print("Test /smc/info/ GET")
info_result,info_data = test_get_info(server)
# тестируем добавление модели из ЗИП архива
print("Test /smc/data POST by zip")
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
print("Test /smc/data DELETE")
delete_model_result = test_delete_model(server)
# форматируем сообщение в итоговый вариант
message = message.format(smc_test_result, add_model_by_csv_result, get_model_result, matrix_result, delete_model_result, entitie_result, error_result, info_result, log_result,test_model_result,add_handler_result, get_model_result,delete_model_result)
# отправка сообщения боту
r = requests.post(f"https://api.telegram.org/{bot_params}/sendMessage?chat_id={chat_id}&text={message}&parse_mode={parse_mode}" )

# проверяем, если были какие то ошибки - завершаемся с ошибкой
if  anyErrors:
    raise SystemError("Во время тестирования были ошибки!")
else:
    raise SystemExit()