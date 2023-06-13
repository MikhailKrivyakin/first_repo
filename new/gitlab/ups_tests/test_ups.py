import requests
import difflib
import json
from zipfile import ZipFile
import os
import time

# Скрипт автотестирования сервиса UPS
# Тестировать будем 8 имеющихся групп методов:
# Группа /model:
#           /add/
#           /apply/
#           /delete/
#           /errors/
#           /export/
#           /import/
#           /info/{servicetype}
#           /info/{servicetype}/{model}
#           /install/
#           /log/
#           /restore/
#           /handler/ add
#           /handler/ get
#           /handler delete
# Группа /corpus/
#           /copy/
#           /delete/
#           /export/
#           /get/
#           /import/
#           /list/
#           /put/
#           /rename/
# Группа /server/
#           /get/adrdresses/
#           /get/models/
# Группа /lang/
#           /lang/
# Группа /smc/
#           /classify/
#           /stop/
#           /test/
#           /train/
# Группа /see/
#           /entities/
#           /stop/
#           /train/
# Группа /spr/
#           /stt/
# Группа /sbs/
#           /analyze/
#           /embidding/
#           /search/
#           /speaker/ post
#           /speaker/ del
#           /speakers/
#           /verify


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
zipfile_to_get = "/root/files_for_auto-tests/model_from_ups.zip"
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
speaker_name="testSpeaker"
wav_to_add='/root/files_for_auto-tests/add_speaker.wav'
wav_to_verify="/root/files_for_auto-tests/verify_speaker.wav"
wav_to_find="/root/files_for_auto-tests/find_speakers.wav"
# переменные для тестов SEE
example_entitie = "кривякин михаил"
# переменная-флаг для обозначения найденных ошибок
anyErrors = False
# шаблон итогового сообщения боту
message = '''
Результаты тестов сервиса <b>UPS</b>:
<b>------------------------------------------</b>
'''   
# функция для получения результаты тестирования простых методов GET, где получаем только RC 
def get_result(url):
    global anyErrors
    result = requests.get(url,None)
    # получаем RC запроса
    rc = result.status_code
    if 200 == rc:
        # если получили 200 ответ - возвращаем соответствующий кусок сообщения
        return "OK"
    else:
        # в случае если ответ !=200 вовзвращаем сообщение с ошибкой и поднимаем флаг ошибка
        anyErrors = True
        return f"ERROR, RC: {rc}"
    
    
###############################################################################################################################################################################
#  Группа методов /server/. Тестировать будем на примере smc
###############################################################################################################################################################################
def test_server_group(server):
    global anyErrors
    # шаблон строки для группы методов
    promt = '''Группа методов /server/ :
<code>/get/addresses: </code><b>{adr_res}</b>
<code>/get/models:    </code><b>{mod_res}</b>
'''
    # Тестируем получение списка серверов SMC
    adr_result = requests.get(f"{server}/server/get/addresses/smc",None)
    # получаем RC запроса
    adr_rc = adr_result.status_code
    if 200 == adr_rc:
        # если получили 200 ответ - возвращаем соответствующий кусок сообщения
        adr_promt = "OK"
    else:
        # в случае если ответ !=200 вовзвращаем сообщение с ошибкой и поднимаем флаг ошибка
        anyErrors = True
        adr_promt = f"ERROR, RC: {adr_rc}"
    # Тестируем получение списка моделей SMC тренера
    mod_result = requests.get(f"{server}/server/get/addresses/smc/trainer",None)
    # получаем RC запроса
    mod_rc = mod_result.status_code
    if 200 == mod_rc:
        # если получили 200 ответ - возвращаем соответствующий кусок сообщения
        mod_promt = "OK"
    else: 
        # в случае если ответ !=200 вовзвращаем сообщение с ошибкой и поднимаем флаг ошибка
        anyErrors = True
        mod_promt = f"ERROR, RC: {mod_rc}"
    promt = promt.format(adr_res = adr_promt,mod_res = mod_promt)
    return promt


###############################################################################################################################################################################
#  Группа методов /server/. КОНЕЦ!
###############################################################################################################################################################################     

###############################################################################################################################################################################
#  Группа методов /corpus/. Тестировать будем на примере smc
###############################################################################################################################################################################
def test_corpus_group(server):
    promt = '''Группа методов /corpus/ :
<code>/copy/:      </code><b>{copy_res}</b>
<code>/delete/:    </code><b>{delete_res}</b>
<code>/export/:    </code><b>{export_res}</b>
<code>/get/:       </code><b>{get_res}</b>
<code>/import/:    </code><b>{import_res}</b>
<code>/list/:      </code><b>{list_res}</b>
<code>/rename/:    </code><b>{rename_res}</b>
<code>/put/:       </code><b>{put_res}</b>
    '''
   
    ###################### Получение списка корпусов ######################
    def get_corpus_list(server):
        global anyErrors
        result = requests.get(f"{server}/corpus/list/smc",None)
        # получаем RC запроса
        rc = result.status_code
        if 200 == rc:
            # если получили 200 ответ - возвращаем просто ОК и список моделей(он будет нужен для проверки других методов)
            return "OK",result.json()
        else:
            # в случае если ответ !=200 вовзвращаем сообщение с ошибкой и поднимаем флаг ошибка
            anyErrors = True
            return f"ERROR, RC: {result.status_code} "
        
    ###################### Импорт нового корпуса ######################
    def import_corpus(server):
         global anyErrors
        # отправляем ПОСТ запрос на сервер
         result = requests.post(
            url=f"{server}/corpus/import/smc",
            files={'csv': (csv_file, open(csv_file, 'rb'),'text/csv')},
            data={'name': smc_corpus_name})
        # получаем RC запроса
         rc = result.status_code
        # переводим запрос в JSON для того, что бы вытащить данные
         result = result.json()
        # для доп.проверки добавления запрпашиваем список корпусов
         cp_res,corpuses = get_corpus_list(server) 
         if 200 == rc and smc_corpus_name in corpuses:
            # если получили 200 ответ и корпус появился в списке - возвращаем просто ОК и ждем 5 минут до завршения обучения
            return f"OK"
         else:
            # в случае если ответ !=200 вовзвращаем сообщение с ошибкой
            anyErrors = True
            return f"ERROR, RC: {rc}, Message: {result.get('message')}"
    ###################### копируем   корпус ######################
    def copy_corpus(server):
         global anyErrors
         params = {"srcname": smc_corpus_name, "dstname": smc_corpus_copy_name}
        # отправляем ПОСТ запрос на сервер
         result = requests.post(
            url=f"{server}/corpus/copy/smc",data=params)
        # получаем RC запроса
         rc = result.status_code
        # переводим запрос в JSON для того, что бы вытащить данные
         result = result.json()
        # для доп.проверки добавления запрпашиваем список корпусов
         cp_res,corpuses = get_corpus_list(server) 
         if 200 == rc and smc_corpus_copy_name in corpuses:
            # если получили 200 ответ и корпус появился в списке - возвращаем просто ОК и ждем 5 минут до завршения обучения
            return f"OK"
         else:
            # в случае если ответ !=200 вовзвращаем сообщение с ошибкой
            anyErrors = True
            return f"ERROR, RC: {rc}, Message: {result.get('message')}"

    ###################### копируем   корпус ######################
    def copy_corpus(server):
         global anyErrors
         params = {"srcname": smc_corpus_name, "dstname": smc_corpus_copy_name}
        # отправляем ПОСТ запрос на сервер
         result = requests.post(
            url=f"{server}/corpus/copy/smc",data=params)
        # получаем RC запроса
         rc = result.status_code
        # переводим запрос в JSON для того, что бы вытащить данные
         result = result.json()
        # для доп.проверки добавления запрпашиваем список корпусов
         cp_res,corpuses = get_corpus_list(server) 
         if 200 == rc and smc_corpus_copy_name in corpuses:
            # если получили 200 ответ и корпус появился в списке - возвращаем просто ОК и ждем 5 минут до завршения обучения
            return f"OK"
         else:
            # в случае если ответ !=200 вовзвращаем сообщение с ошибкой
            anyErrors = True
            return f"ERROR, RC: {rc}, Message: {result.get('message')}"
    
        ###################### переименуем корпус   ######################
    def rename_corpus(server):
         global anyErrors
         params = {"srcname": smc_corpus_copy_name, "dstname": smc_corpus_rename_name}
        # отправляем ПОСТ запрос на сервер
         result = requests.post(
            url=f"{server}/corpus/rename/smc",data=params)
        # получаем RC запроса
         rc = result.status_code
        # переводим запрос в JSON для того, что бы вытащить данные
         result = result.json()
        # для доп.проверки добавления запрпашиваем список корпусов
         cp_res,corpuses = get_corpus_list(server) 
         if 200 == rc and smc_corpus_copy_name not in corpuses and smc_corpus_rename_name in corpuses:
            # если получили 200 ответ, проверили, что исходный корпус пропал из списка, а новый появился
            return f"OK"
         else:
            # в случае если ответ !=200 вовзвращаем сообщение с ошибкой
            anyErrors = True
            return f"ERROR, RC: {rc}, Message: {result.get('message')}"
          ###################### переименуем корпус   ######################
    def delete_corpus(server):
         global anyErrors
         params = {"name": smc_corpus_rename_name}
        # отправляем ПОСТ запрос на сервер
         result = requests.delete(
            url=f"{server}/corpus/delete/smc",data=params)
        # получаем RC запроса
         rc = result.status_code
        # переводим запрос в JSON для того, что бы вытащить данные
         result = result.json()
        # для доп.проверки добавления запрпашиваем список корпусов
         cp_res,corpuses = get_corpus_list(server) 
         if 200 == rc and smc_corpus_rename_name not in corpuses:
            # если получили 200 ответ, проверили, что наш переименованный корпус удалился
            return f"OK"
         else:
            # в случае если ответ !=200 вовзвращаем сообщение с ошибкой
            anyErrors = True
            return f"ERROR, RC: {rc}, Message: {result.get('message')}"  
        
       ###################### Получение данные корпуса ######################
    def get_corpus_data(server):
        global anyErrors
        result = requests.get(f"{server}/corpus/get/smc?name={smc_corpus_name}") # передал параметр в URL, криво но стандартный метод через data не работает почему то здесь
        # получаем RC запроса
        rc = result.status_code
        if 200 == rc:
            # если получили 200 ответ - возвращаем просто ОК и список моделей(он будет нужен для проверки других методов)
            return "OK"
        else:
            # в случае если ответ !=200 вовзвращаем сообщение с ошибкой и поднимаем флаг ошибка
            anyErrors = True
            return f"ERROR, RC: {result.status_code} "
     ###################### Получение данные корпуса ######################
    def export_corpus(server):
        global anyErrors
        params = {"name": smc_corpus_name}
        result = requests.get(f"{server}/corpus/export/smc", params)
        # пишем в файл пришедший ответ
        with open(f"{csv_to_recieve}",'wb') as f:
            f.write(result.content)
        rc = result.status_code
        if 200 == rc:
            # если получили 200 ответ - возвращаем просто ОК и список моделей(он будет нужен для проверки других методов)
            os.remove(csv_to_recieve)
            return "OK"
        else:
            # в случае если ответ !=200 вовзвращаем сообщение с ошибкой и поднимаем флаг ошибка
            anyErrors = True
            os.remove(csv_to_recieve)
            return f"ERROR, RC: {result.status_code} "
    def put_phrase_to_corpus(server):
        global anyErrors
        params = {"json": '[["end_work","test_phrase"]]',
                  "name": smc_corpus_rename_name}
        result = requests.post(f"{server}/corpus/put/smc", data=params)
        rc = result.status_code
        if 200 == rc:
            # если получили 200 ответ - возвращаем просто ОК 
            return "OK"
        else:
            # в случае если ответ !=200 вовзвращаем сообщение с ошибкой и поднимаем флаг ошибка
            anyErrors = True
            return f"ERROR, RC: {result.status_code} "
        
        
    list_res,corpuses = get_corpus_list(server)
    promt = promt.format(import_res=import_corpus(server),
                          list_res=list_res,
                          copy_res=copy_corpus(server),
                          rename_res=rename_corpus(server),
                          put_res=put_phrase_to_corpus(server),
                          delete_res=delete_corpus(server),
                          get_res=get_corpus_data(server),
                          export_res=export_corpus(server)
                          )
    
    
     
    return promt
###############################################################################################################################################################################
#  Группа методов /corpus/. КОНЕЦ!
###############################################################################################################################################################################        

###############################################################################################################################################################################
#  Группа методов /model/+/sms/
###############################################################################################################################################################################           
def test_model_group(server):
    promt = '''Группа методов /model/:
<code>/add/:        </code><b>{add_res}</b>
<code>/apply/:      </code><b>{apply_res}</b>
<code>/delete/:     </code><b>{delete_res}</b>
<code>/errors/:     </code><b>{error_res}</b>
<code>/export/:     </code><b>{export_res}</b>
<code>/handler/post:</code><b>{add_handler_res}</b>
<code>/handler/get: </code><b>{get_handler_res}</b>
<code>/handler/del: </code><b>{del_handler_res}</b>
<code>/import/:     </code><b>{import_res}</b>
<code>/info/service:</code><b>{info_res}</b>
<code>/info/model:  </code><b>{model_info_res}</b>
<code>/install/:    </code><b>{install_res}</b>
<code>/log/:        </code><b>{log_res}</b>
<code>/restore/:    </code><b>{restore_res}</b>
Группа методов /smc/:
<code>/classify/:   </code><b>{classify_res}</b>
<code>/stop/:       </code><b>{stop_res}</b>
<code>/test/:       </code><b>{test_res}</b>
<code>/train/:      </code><b>{train_res}</b>
    '''
    # добавляем новую модель в список
    def add_model(server):
        global anyErrors
        result = requests.post(f"{server}/model/add/smc/{smc_model_name}",None)
        # получаем RC запроса
        rc = result.status_code
        if 200 == rc:
            # если получили 200 ответ - возвращаем просто ОК и список моделей(он будет нужен для проверки других методов)
            return "OK"
        else:
            # в случае если ответ !=200 вовзвращаем сообщение с ошибкой и поднимаем флаг ошибка
            anyErrors = True
            return f"ERROR, RC: {result.status_code},Message: {result.json()}"
    # обучаем нашу модель заранее добавленным корпусом
    def train_model(server):
        global anyErrors
        # отправляем ПОСТ запрос на сервер
        result = requests.post(
            url=f"{server}/smc/train/{smc_model_name}",
            data={'corpus': smc_corpus_name})
        # получаем RC запроса
        rc = result.status_code
        # переводим запрос в JSON для того, что бы вытащить данные
        result = result.json()
        # для доп.проверки добавления запрпашиваем список моделей на сервере
        models = requests.get(f"{server}/model/info/smc").json()
        if 200 == rc and smc_model_name in models:
            # если получили 200 ответ и модель появилась в списке - возвращаем просто ОК и ждем 5 минут до завршения обучения
            print("Ложимся спать на 5 минут, пока модель учится")
            time.sleep(300)
            # после 5 минут ожидания проверяем обучилась ли модель:
            models = requests.get(f"{server}/model/info/smc").json()
            if models.get(smc_model_name).get("future").get("status") == "training":
                print("Модель еще учится, ложимся спать еще на 5 минут")
                time.sleep(300)
            return f"OK"
        else:
            # в случае если ответ !=200 вовзвращаем сообщение с ошибкой
            anyErrors = True
            return f"ERROR, RC: {rc}, Message: {result.get('message')}"
    # устанавливаем модель
    def install_model(server):
        global anyErrors
        # отправляем ПОСТ запрос на сервер
        result = requests.post(url=f"{server}/model/install/smc/{smc_model_name}")
        # получаем RC запроса
        rc = result.status_code
        # переводим запрос в JSON для того, что бы вытащить данные
        result = result.json()
        # для доп.проверки добавления запрпашиваем список моделей на сервере
        models = requests.get(f"{server}/model/info/smc").json()
        # если код 200 и статус модели изменился на "установлена" то все ОК
        if 200 == rc and models.get(smc_model_name).get("future").get("status") == "installed":
            return f"OK"
        else:
            # в случае если ответ !=200 вовзвращаем сообщение с ошибкой
            anyErrors = True
            return f"ERROR, RC: {rc}, Message: {result.get('message')}"
    # тестируем обученну модель перед примененеием
    def test_model(server):
        # отправляем ПОСТ запрос на сервер
         result = requests.post(
            url=f"{server}/smc/test/{smc_model_name}",
            data={'corpus': smc_corpus_name,
                  'confidence': 0})
        # получаем RC запроса
         rc = result.status_code
        # переводим запрос в JSON для того, что бы вытащить данные
         result = result.json()
         if 200 == rc:
            # если получили 200 ответ - возвращаем просто ОК и ждем минуту до завршения тестирования
            print("Ложимся спать на минуту, пока модель тестируется")
            time.sleep(60)
            # после  минуты ожидания проверяем протестировалась  ли модель:
            model = requests.get(f"{server}/model/info/smc/{smc_model_name}").json()
            if model.get('status') == "testing":
                print("Модель еще тестируется, ложимся спать еще на  минуту")
                time.sleep(60)
            return f"OK"
         else:
            # в случае если ответ !=200 вовзвращаем сообщение с ошибкой
            global anyErrors
            anyErrors = True
            return f"ERROR, RC: {rc}, Message: {result.get('message')}"
        
    # применяем модель
    def apply_model(server):
        global anyErrors
        # отправляем ПОСТ запрос на сервер
        result = requests.post(url=f"{server}/model/apply/smc/{smc_model_name}")
        # получаем RC запроса
        rc = result.status_code
        # переводим запрос в JSON для того, что бы вытащить данные
        result = result.json()
        # для доп.проверки применения запрашиваем инфу о модели
        model = requests.get(f"{server}/model/info/smc/{smc_model_name}").json()
        # если код 200 и статус модели изменился на "применена" то все ОК
        if 200 == rc and model.get("current").get("status") == "applied":
            return f"OK"
        else:
            # в случае если ответ !=200 вовзвращаем сообщение с ошибкой
            anyErrors = True
            return f"ERROR, RC: {rc}, Message: {result.get('message')}"  
        
    def classify_text(server):
        params = {"text": f"{example_request}"}
        result = requests.get(f"{server}/smc/classify/{smc_model_name}",params)
        # получаем RC запроса
        rc = result.status_code
        entitie = (result.json()["calculated"])
        if 200 == rc and entitie == example_class:
            # если получили 200 ответ - возвращаем просто ОК 
            return "OK"
        else:
            # в случае если ответ !=200 вовзвращаем сообщение с ошибкой и поднимаем флаг ошибка
            global anyErrors
            anyErrors = True
            return f"ERROR, RC: {result.status_code}"
        
    def test_get_model(server):
        result = requests.get(f"{server}/model/export/smc/{smc_model_name}/current",stream = True)
        # пишем в файл пришедший ответ
        with open(f"{zipfile_to_get}",'wb') as f:
            f.write(result.content)
        # получаем RC запроса
        rc = result.status_code
        #print(result.content)
        if 200 == rc:
            # если получили 200 ответ - возвращаем просто ОК и удаляем файл
            return f"OK"
        else:
            # в случае если ответ !=200 вовзвращаем сообщение с ошибкой
            global anyErrors
            anyErrors = True
            return f"ERROR, RC: {rc}"
     # добавим модель ЗИП архивом и сразу применим её в статус "активная" на этом этапе у нас будет модель с путым черновиком, активная модель - из ЗИПА, обученная модель - а архиве   
    def add_model_by_zip(server):
        # отправляем ПОСТ запрос на сервер
         result = requests.post(
            url=f"{server}/model/import/smc/{smc_model_name}",
            files={'zip-model': (zipfile_to_get, open(zipfile_to_get, 'rb'),'application/zip')})
        # получаем RC запроса
         rc = result.status_code
         if 200 == rc:
            # если получили 200 ответ - возвращаем просто ОК и удаляем модель. Также устанавливаем и применяем модель на сервере
            os.remove(zipfile_to_get)
            result = requests.post(url=f"{server}/model/install/smc/{smc_model_name}")
            result = requests.post(url=f"{server}/model/apply/smc/{smc_model_name}")
            return f"OK"
         else:
            # в случае если ответ !=200 вовзвращаем сообщение с ошибкой
            global anyErrors
            anyErrors = True
            os.remove(zipfile_to_get)
            return f"ERROR, RC: {rc}, Messgae: {result.json().get('message')}"
    # тестируем откат модели на архивную
    def restore_model(server):
        global anyErrors
        # отправляем ПОСТ запрос на сервер
        result = requests.post(url=f"{server}/model/restore/smc/{smc_model_name}")
        # получаем RC запроса
        rc = result.status_code   
        # если код 200  то все ОК
        if 200 == rc:
            return f"OK"
        else:
            # в случае если ответ !=200 вовзвращаем сообщение с ошибкой
            anyErrors = True
            return f"ERROR, RC: {rc}, Message: {result.json().get('message')}"
    
    def delete_model(server):
        global anyErrors
        # отправляем DELETE запрос на сервер
        result = requests.delete(url=f"{server}/model/delete/smc/{smc_model_name}")
        # получаем RC запроса
        rc = result.status_code   
        # если код 200  то все ОК
        # для доп.проверки применения запрашиваем инфу о моделях для SMC
        models = requests.get(f"{server}/model/info/smc").json()
        # если код 200 и модули нет в списке то все ОК и сразу удаляем задействованный корпус
        if 200 == rc and smc_model_name not in models:
            params = {"name": smc_corpus_name}
        # отправляем ПОСТ запрос на сервер
            result = requests.delete(
            url=f"{server}/corpus/delete/smc",data=params)            
            return f"OK"
        else:
            # в случае если ответ !=200 вовзвращаем сообщение с ошибкой
            anyErrors = True
            return f"ERROR, RC: {rc}, Message: {result.json().get('message')}"
    #########################################################################
    # добавляем хендлер
    ##########################################################################
    def add_handler(server):
     # отправляем ПОСТ запрос на сервер
        result = requests.post(
            url=f"{server}/model/handler/smc/{smc_model_name}",
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
        result = requests.get(f"{server}/model/handler/smc/{smc_model_name}",None)
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
        result = requests.delete(f"{server}/model/handler/smc/{smc_model_name}")
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
    add_res = add_model(server)
    train_res = train_model(server)
    test_res = test_model(server)
    add_handler_result = add_handler(server)
    get_handler_result = get_handler(server)
    delete_handler_result = delete_handler(server)
    install_res = install_model(server)
    apply_res = apply_model(server)
    classify_res = classify_text(server)
    info_res = get_result(f"{server}/model/info/smc")
    model_info_res = get_result(f"{server}/model/info/smc/{smc_model_name}")
    log_res = get_result(f"{server}/model/log/smc/{smc_model_name}/current")
    error_res = get_result(f"{server}/model/errors/smc/{smc_model_name}/current")
    stop_res = get_result(f"{server}/smc/stop/smc/{smc_model_name}")
    export_res = test_get_model(server)
    import_res = add_model_by_zip(server)
    restore_res = restore_model(server)
    delete_res = delete_model(server)
    # форматируем итоговую строку
    promt = promt.format(add_res = add_res,
                         apply_res = apply_res,
                         delete_res = delete_res,
                         error_res = error_res,
                         export_res = export_res,
                         import_res = import_res,
                         info_res = info_res,
                         model_info_res = model_info_res,
                         install_res = install_res,
                         log_res = log_res,
                         restore_res = restore_res,
                         classify_res = classify_res,
                         stop_res = stop_res,
                         test_res = test_res,
                         train_res = train_res,
                         add_handler_res = add_handler_result,
                         get_handler_res = get_handler_result,
                         del_handler_res = delete_handler_result
                         )        
    return promt        
###############################################################################################################################################################################
#  Группа методов /model/+/smc/ КОНЕЦ!
###############################################################################################################################################################################         
###############################################################################################################################################################################
#  Группа методов SPR
############################################################################################################################################################################### 
def test_spr(server):
    promt = '''Группа методов /spr/:
<code>/stt/:        </code><b>{stt_res}</b>
    '''
    data = open(voice_file, 'rb')  
    headers = {'content-type': 'audio/wav'}
    result= requests.post(f"{server}/spr/stt/{spr_model_name}", data=data, headers=headers)
    # получаем RC запроса
    rc = result.status_code
    # переводим запрос в JSON для того, что бы вытащить данные
    result = result.json()
    recognised = result["text"]
    matcher = difflib.SequenceMatcher(None, recognised, example_string)
    if matcher.ratio() > 0.8 and rc == 200:
        # если получили 200 ответ и полученная строка совпадает с тестовой хотя бы на 80% - возвращаем просто ОК 
        promt = promt.format(stt_res="OK")
    else:
        global anyErrors
        anyErrors = True
        promt = promt.format(stt_res=f"ERROR, RC: {rc}")
    return promt 
###############################################################################################################################################################################
#  Группа методов SPR КОНЕЦ!
############################################################################################################################################################################### 
def test_sbs_group(server):
    promt = '''Группа методов /sbs/:
<code>/sbs/analyze/      : </code><b>{analyze_res}</b>
<code>/sbs/embedding/    : </code><b>{emb_res}</b>
<code>/sbs/search/       : </code><b>{search_res}</b>
<code>/sbs/speaker/  DEL : </code><b>{del_res}</b>
<code>/sbs/speaker/  POST: </code><b>{add_res}</b>
<code>/sbs/speakers/ GET : </code><b>{get_res}</b>
<code>/sbs/verify/       : </code><b>{verify_res}</b>
'''   
    #########################################################################
# тестируем создание нового слепка спикера
#########################################################################    
    def test_add_speaker(server):
        # отправляем файл на сервер для создания слепка
        result = requests.post(
                url=f"{server}/sbs/speaker/{sbs_model_name}/{speaker_name}",
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
        result = requests.get(f"{server}/sbs/speakers/{sbs_model_name}",None)
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
                url=f"{server}/sbs/verify/{sbs_model_name}/{speaker_name}",
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
                url=f"{server}/sbs/search/{sbs_model_name}",
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
                url=f"{server}/sbs/analyze/{sbs_model_name}",
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
                url=f"{server}/sbs/embedding/{sbs_model_name}",
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
        result = requests.delete(f"{server}/sbs/speaker/{sbs_model_name}/{speaker_name}")
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
    add_speker_result = test_add_speaker(server)
    get_speakers_list_result,speakers_list = get_speakers_list(server)
    verify_result = test_verify_speaker(server)
    search_result = test_search_speaker(server)
    analyze_result = test_analyze_speaker(server)
    embedding_test_result = test_embedding(server)
    del_speaker_result = test_delete_speaker(server)
    promt = promt.format(analyze_res = analyze_result,
                         emb_res = embedding_test_result,
                         search_res = search_result,
                         del_res = del_speaker_result,
                         add_res = add_speker_result,
                         get_res = get_speakers_list_result,
                         verify_res = verify_result
                         )
    return promt
###############################################################################################################################################################################
#  Группа методов SBS
############################################################################################################################################################################### 

###############################################################################################################################################################################
#  Группа методов SBS КОНЕЦ!
############################################################################################################################################################################### 

###############################################################################################################################################################################
#  Группа методов SEE КОНЕЦ!
############################################################################################################################################################################### 
def test_see_group(server):
    # тест SEE будемт немного муторный и будет использовать корпус и переменные, которыми тестировали SMC и блок модели
    promt = '''Группа методов /see/:
<code>/see/entities/     : </code><b>{entetie_res}</b>
<code>/see/stop/         : </code><b>{stop_res}</b>
<code>/see/train/        : </code><b>{train_res}</b>
'''
    def get_entitie(server):
        params = {"text": f"{example_entitie}"}
        result = requests.get(f"{server}/see/entities/{see_model_name}",params)
        # получаем RC запроса
        rc = result.status_code
        entitie = (result.json()[f"{see_model_name}"][0]["calculated"])
        print(entitie)
        if 200 == rc and entitie == example_entitie:
            # если получили 200 ответ - возвращаем просто ОК 
            return "OK"
        else:
            # в случае если ответ !=200 вовзвращаем сообщение с ошибкой и поднимаем флаг ошибка
            global anyErrors
            anyErrors = True
            return f"ERROR, RC: {result.status_code}"
    # для тесты обучения и остановки обучения будут объеденены в 1. для этого нужно еще добавить корпус
    def test_train(server):
        global anyErrors
        # добавим корпус в SEE для последующего  обучения
        add_corpus_result = requests.post(
            url=f"{server}/corpus/import/see",
            files={'csv': (csv_file, open(csv_file, 'rb'),'text/csv')},
            data={'name': smc_corpus_name})
        # сразу отправляем запрос на обучение модели, он автоматом создаст нужную модель
        train_result = requests.post(
            url=f"{server}/see/train/{smc_model_name}",
            data={'corpus': smc_corpus_name})
        rc = train_result.status_code
        # запросим у сервера список моделей СЕЕ что бы проверить появлась ли она
        models = requests.get(f"{server}/model/info/see").json()
        if 200 == rc and smc_model_name in models:
            # если код 200 и модель появилась в списке - все ок
            return "OK"
        else:
            # в случае если ответ !=200 вовзвращаем сообщение с ошибкой и поднимаем флаг ошибка
            anyErrors = True
            return f"ERROR, RC: {rc}"
    def test_stop(server):
        global anyErrors
        result = requests.post(f"{server}/see/stop/{smc_model_name}")
        rc = result.status_code
        if 200 == rc:
            # если код 200 и можно чистить "мусор"
            requests.delete(f"{server}/model/delete/see/{smc_model_name}")
            params = {"name": smc_corpus_name}
            # отправляем ПОСТ запрос на сервер
            result = requests.delete(
            url=f"{server}/corpus/delete/see",data=params)            
            return "OK"
        else:
            # в случае если ответ !=200 вовзвращаем сообщение с ошибкой и поднимаем флаг ошибка
            anyErrors = True
            return f"ERROR, RC: {rc}"
    promt = promt.format(entetie_res = get_entitie(server),
                         train_res = test_train(server),
                         stop_res = test_stop(server))
    return promt
         
        


###############################################################################################################################################################################
#  Группа методов SEE КОНЕЦ!
############################################################################################################################################################################### 

###################################
#            MAIN
###################################
message=message+test_server_group(server)
message=message+test_corpus_group(server)
message=message+test_model_group(server)
message=message+test_spr(server)
message=message+test_sbs_group(server)
message=message+test_see_group(server)
print(message)
# отправка сообщения боту
r = requests.post(f"https://api.telegram.org/{bot_params}/sendMessage?chat_id={chat_id}&text={message}&parse_mode={parse_mode}" )

# проверяем, если были какие то ошибки - завершаемся с ошибкой
if  anyErrors:
    raise SystemError("Во время тестирования были ошибки!")
else:
    raise SystemExit()