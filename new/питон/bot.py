import telebot
import requests
import subprocess
import boto3
import time
import logging
from datetime import datetime
################################## Блок настройки логирования
logfile = "bot.log"
log = logging.getLogger("my_log")
log.setLevel(logging.INFO)
FH = logging.FileHandler(logfile)
basic_formater = logging.Formatter('%(asctime)s : [%(levelname)s] : %(message)s')
FH.setFormatter(basic_formater)
log.addHandler(FH)

token = '5934768430:AAE5o4ccmUsis0-LCl3BNLSk9AdKcI7ocBQ'
bot = telebot.TeleBot(token)

src_filename = 'voice.ogg'
dest_filename = 'voice.wav'
# Cоздание переменных ec2
ec2=boto3.resource("ec2")
instanceID="i-03ada09daa44b0641"
server=ec2.Instance(instanceID)
# Листы с подтверждение/отказом от операции
agree=["ДА","да","Да","дА"]
decline=["НЕТ","нет","Нет"]
fuck_yous=["пошел нахуй","иди нахуй","Бот пошёл нахуй"]

############################# Проверка на то что пишет хозяин    #############################
def check_owner(message):
  if message.from_user.username == "KrivyakinM" and message.chat.id == 871812811:
    log.info("Проверка на авторизацию пройдена")
    return 1
  else:
    log.info("Проверка на авторизацию не пройдена")
    return 0

#############################  Проверка статуса сервера ##########################
@bot.message_handler(commands=['status'])
def check_server_state(message):
  log.info(f"Запрос о статусе сервера. Отправитель: {message.from_user.username}")
  if check_owner(message) == 0:
    bot.send_message(message.chat.id,f"-----------------\nSorry, you either don`t have permissions to run this command, or it`s the wrong chat to do it.\n-----------------")
  else:
    state=server.state["Name"]
    bot.send_message(message.chat.id,f"-----------------\nСтатус сервера:  {state}\n-----------------")
    log.info(f"Сообщение от сервера: {state}")

#############################  Выполнение команды на сервере ##########################
@bot.message_handler(commands=['sendcommand'])
def ask_for_command(message):
  if check_owner(message) == 0:
      bot.send_message(message.chat.id,f"-----------------\nSorry, you either don`t have permissions to run this command, or it`s the wrong chat to do it.\n-----------------")
  else:
    bot.send_message(message.chat.id,f"-----------------\nКакую команду отправить на сервер?\nСписок доступных команд:\n1.Reboot\n2.Shutdown.\n3.Start\n-----------------")
    bot.register_next_step_handler(message, execute_command)

def execute_command(message):
  command = message.text.lower()
  if command in ["1","Перезагрузка","Reboot","reboot","ребут"]:
    bot.send_message(message.chat.id,f"-----------------\nВыполняю перезагрузку сервера\n-----------------") 
    result=server.reboot()
    bot.send_message(message.chat.id,f"-----------------\nКоманда отправлена, код ответа: {result['ResponseMetadata']['HTTPStatusCode']}\n-----------------") 
    time.sleep(10)
    check_server_state(message)
  elif command in ["2","Выключи","выключи","shutdown","Shutdown"]:
    bot.send_message(message.chat.id,f"-----------------\nВыключаю сервер\n-----------------") 
    result=server.stop()
    bot.send_message(message.chat.id,f"-----------------\nКоманда отправлена, код ответа: {result['ResponseMetadata']['HTTPStatusCode']}\n-----------------") 
    time.sleep(10)
    check_server_state(message)
  elif command in ["3","Старт","включи","Включи","Start", "run", "Run"]:
    bot.send_message(message.chat.id,f"-----------------\nВключаю сервер\n-----------------") 
    result=server.start()
    bot.send_message(message.chat.id,f"-----------------\nКоманда отправлена, код ответа: {result['ResponseMetadata']['HTTPStatusCode']}\n-----------------") 
    time.sleep(10)
    check_server_state(message)
  else:
    bot.send_message(message.chat.id,"Вы выбрали неверную команду. Пожалуйста запустите /sendcommand еще раз")

def final_check(message, command):
  text = message.text
  if text in agree:
    eval(command)
    

#############################  Распознование голосовых сообщений ##########################
def recognize_by_curl():
    params = {"accept: application/json", "Content-Type: multipart/form-data"}
    file = {'upload_file': open('voice.wav')}
    url = "http://10.100.50.98:6183/spr/stt/calls?long=0"
    data = open(r'voice.wav', 'rb')  
    headers = {'content-type': 'audio/wav'}
    response= requests.post(url, data=data, headers=headers)
    result=response.json()
    return result["text"]

@bot.message_handler(content_types=['voice'])
def repeat_all_message(message):
  message_info = message
  sender = message.from_user.first_name
  file_info = bot.get_file(message_info.voice.file_id)
  file = requests.get('https://api.telegram.org/file/bot{0}/{1}'.format(token, file_info.file_path))
  with open('voice.ogg','wb') as f:
   f.write(file.content)
  process = subprocess.run(['ffmpeg', '-y', '-i', src_filename, dest_filename], stderr=subprocess.DEVNULL)
  recognized = recognize_by_curl()
  bot.send_message(message.chat.id,f"-----------------\n{sender} сказал:\n{recognized}\n-----------------")  
  log.info(f"Распознано сообщение от  {message.from_user.username}. Текст: {recognized}")


############################ Получение информации о погоде ##########################
@bot.message_handler(commands=['weather'])
def show_help_message(message):
  bot.send_message(message.chat.id,f"В каком городе вы хотите узнать погоду?")
  bot.register_next_step_handler(message, get_weather)


def get_weather(message):
    city = message.text
    params = {"access_key": "233d59c0b92f9454415e860be49790b7", "query": f"{city}"}
    api_result = requests.get('http://api.weatherstack.com/current', params)
    api_response = api_result.json()
    bot.send_message(message.chat.id, f"Сейчас в {api_response['request']['query']} {api_response['current']['temperature']} градусов")




######################### Вывод описания ##########################
@bot.message_handler(commands=['help'])
def show_help_message(message):
  bot.send_message(message.chat.id,f"Я маленький бот, я почти ничего не умею.\nУмею только распознавать голосовые сообщения и сообщить тебе о погоде в нужном городе\nСкажи мне что-нибудь")
  log.info(f"отправлено информационное сообщение в чат: {message.chat.id} инициатор: {message.from_user.username}")

########################## Обработчик текстовых сообщений ##########################
@bot.message_handler(content_types=['text'])
def reply_to_maks(message):
  if message.from_user.username == "Maks_s_73" and message.text.lower() in fuck_yous:
   bot.send_message(message.chat.id,f"Макс, сам пошёл нахуй")
   log("Послал Макса нахер")


##########################
  
if __name__ == '__main__':
  log.info("Бот запущен")
  bot.polling(none_stop=True)
 