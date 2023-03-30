from flask import Flask, request
import requests
import telebot

app = Flask(__name__)

token = '5934768430:AAE5o4ccmUsis0-LCl3BNLSk9AdKcI7ocBQ'
bot = telebot.TeleBot(token)

def get_weather(city):
    params = {"access_key": "233d59c0b92f9454415e860be49790b7", "query": f"{city}"}
    print(city)
    print(params)
    api_result = requests.get('http://api.weatherstack.com/current', params)
    api_response = api_result.json()
    return f"Сейчас в {city} {api_response['current']['temperature']} градусов"

def send_message(chat_id, text):
    method = "sendMessage"
    token = "5934768430:AAE5o4ccmUsis0-LCl3BNLSk9AdKcI7ocBQ"
    url = f"https://api.telegram.org/bot{token}/{method}"
    data = {"chat_id": chat_id, "text": text}
    requests.post(url, data=data)


@app.route("/", methods=["GET", "POST"])
def receive_update():
    if request.method == "POST":
        print(request.json)
        chat_id = request.json["message"]["chat"]["id"]
        city = request.json["message"]["text"]
        weather = get_weather(city)
        send_message(chat_id, weather)
    return {"ok": True}
    
# app.route("/", methods=["GET", "POST"])
#def receive_update():
##    if request.method == "POST":\
#       print(request.json["message"]["text"])
#        message = request.json["message"]["text"]
#        chat_id = request.json["message"]["chat"]["id"]
#        if message == "Привет!":
#         send_message(chat_id, "и тебе привет")
#        elif message == "Пока":
#         send_message(chat_id, "и тебе пока")
#        
#    return {"ok": True}