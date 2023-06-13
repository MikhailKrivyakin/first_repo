import requests
server = "http://10.2.0.190:6182"
# параметры ТГ бота для отправки оповещения:
bot_params = "bot5919117739:AAEE44LXoWDuTy8L_ZdgIt95D_-HhOOJ3VU"
chat_id = "-1001630087101"
parse_mode="HTML"
# имя тестовой модели
model_name = "minsoc_na_24korp" # имя основной модели для тестов
model_name1 = "very-new-model-b-zip" # имя модели, которую будем добавлять архивом, что бы не мешались друг другу
# корпус для обучения
csv_file =  '/root/files_for_auto-tests/trud5.csv'
# имя под которым будем скачивать обученную модель
zipfile_to_get = '/root/files_for_auto-tests/test_model_smc.zip'
# строки по которым будет идти сравнение
example_entitie = "schedule_work"
example_request = "режим работы"
handler = 'handler.py'

def add_handler(server):
     # отправляем ПОСТ запрос на сервер
         result = requests.post(
            url=f"{server}/model/handler/smc/{model_name}",
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


add_handler(server)
get_handler(server)
delete_handler(server)
get_handler(server)