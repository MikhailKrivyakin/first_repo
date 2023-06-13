#! /usr/bin/env python
# -*- coding: utf-8 -*-

from flask import Flask, request, Response, jsonify
from datetime import datetime

import json, hashlib, os, requests, subprocess

APIKey = "5186207563:AAHtoAx4bi8C6FNmOr-bHy1tBVpiBdio4dk"
chats = [ -1001669151578, -457749350 ]
application = Flask(__name__)
lexicom_team_chat_id = "-457749350"

# Генерация корпуса
def generateCorpus(config={}):

    errors = []
    result = []
    classes = config.get("classes",{})

    if classes == {}:
        errors.append("в конфигурационном файле отсутствуют классы")
        return None, errors

    for cls in classes:
        file = "../"+cls
        # Если нет нужного файла для класса
        if not os.path.isfile(file):
            errors.append("отсутствует файл "+cls)
            continue
        with open(file) as f:
            for line in f.readlines():
                result.append(classes[cls]+"\t"+line)

    if not len(result):
        result = None
    if not len(errors):
        errors = None
    else:
        errors = "\n".join(errors)

    return result, errors

def sendMessage(chatID=None,message=None,file=None):

    if message != None:
        try:
            reply = requests.post(
                url="https://api.telegram.org/bot"+APIKey+"/sendMessage",
                json={
                    "chat_id": chatID,
                    "text": message,
                    "parse_mode": "HTML"
                }
            ).content
        except:
            print("Ошибка отправки сообщения в "+str(chatID))
            print("Сообщение "+message)

    if file != None:
        if not type(file) is list:
            return
        tmp = '/tmp/'+hashlib.md5(str(datetime.now()).encode('utf-8')).hexdigest()+'.csv'
        with open(tmp,'w') as t:
            for line in file:
                t.write(line)
            t.close
        with open(tmp, "rb") as t:
            r = requests.post(
                url='https://api.telegram.org/bot'+APIKey+'/sendDocument',
                data={
                    "chat_id": chatID,
                    "filename": "/tmp/corpus.csv"
                }, files={"document": t})
            if r.status_code != 200:
                print("Ошибка отправки файла в "+str(chatID))


def corpusGenerator(message=None,text=""):
    # Проверим наличие указания ветки
    text = text.split()
    if "ветка" in text:
        try:
            branch = text[text.index("ветка")+1]
        except:
            branch = "master"
    else:
        branch = "master"

    # Если во вложении файл, то используем в первую очередь его
    if message['message'].get('document',None) != None:
        message['message']['document']

        # Пробуем получить параметры файла
        try:
            file_params = requests.post(
                url='https://api.telegram.org/bot'+APIKey+'/getFile',
                json={ 'file_id': message['message']['document']['file_id'] }
            ).json()

            if not file_params.get("ok", False):
                return "Ошибка приема файла", None
        except:
            return "Ошибка приема файла", None


        # Пробуем получить сам файл конфига
        try:
            content = requests.get(url="https://api.telegram.org/file/bot"+APIKey+"/"+file_params["result"]["file_path"]).content
            config = json.loads(content)
        except:
            return "Ошибка формата JSON", None

    # Если во вложении конфиг
    else:
        try:
            # Отсекаем текст до JSON-массива
            text = "{"+"{".join( message['message']['text'].split("{")[1:] )
            # Отсекаем текст после JSON-массива
            text = "}".join( text.split("}")[:-1] )+"}"
            config = json.loads(text)
        except:
            return "Ошибка формата JSON", None

    # Переключаемся на нужную ветку
    os.system("git fetch")
    os.system("git checkout "+branch)
    os.system("git fetch")

    # Запрашиваем обновления
    os.system("git pull")

    # Генерируем корпус
    corpus, errors = generateCorpus(config=config)

    # Возвращаемся в основную ветку
    os.system("git checkout master")

    return errors, corpus


# Обработка входящих сообщений робота
@application.route('/klqwrnm234sdmb', methods = ['POST'])
def recieveMessage():

    message = request.json

    try:
        chatID = message['message']['chat']['id']
    except:
        print("Нет chat_id в сообщении")
        return jsonify({"error":0})

    # Если это сообщение неизвестно откуда
    if not chatID in chats:
        sendMessage(chatID=chatID,message="На личные сообщения я не отвечаю. Только в чате.")
        return jsonify({"error":0})

    if "text" in message['message']:
        text = message['message']['text']
    elif "document" in message['message']:
        text = message['message'].get('caption',"")
    else:
        text = ""

    if text == "":
        print("Пустое сообщение")
        print(message)
        return jsonify({"error":0})

    print(message)
    # Если это сообщение не боту
    if "@Konstantin_Shapovalov_bot" not in text:
        return jsonify({"error":0})

    # Если это генерация корпуса
    if "корпус" in text or "classes" in text:
        message, file = corpusGenerator(message,text=text)
        sendMessage(chatID=chatID,message=message,file=file)
    elif "оповести о модели" in text:
        model = text.replace("@Konstantin_Shapovalov_bot","").replace("оповести о модели","").split()[0]
        service = text.replace("@Konstantin_Shapovalov_bot","").replace("оповести о модели","").split()[-1]
        message = f'''<b>--------------------------------------------------------------------------</b>
На <a href="https://194.55.245.17:8183">демостенде</a> <b>/</b> доступна новая версия модели {model} для сервиса распознавания <b>{service}</b>

<a href="https://cloud.connect2ai.net/index.php/apps/files/?dir=/spr/models/{model}">Ссылка</a>    
<b>--------------------------------------------------------------------------</b>
    '''
        sendMessage(chatID=lexicom_team_chat_id,message=message)
    else:
        sendMessage(chatID=chatID,message="Это вопрос не ко мне, идите к живому человеку.")

    return jsonify({"error":0})


if __name__ == '__main__':
    application.run(host='0.0.0.0', port='6179', debug=False)
