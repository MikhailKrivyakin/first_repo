import telebot
import requests
import subprocess
import boto3
import time
import logging
from datetime import datetime

city = "Большое Грызлово"
params = {"access_key": "233d59c0b92f9454415e860be49790b7", "query": f"{city}"}
api_result = requests.get('http://api.weatherstack.com/current', params)
api_response = api_result.json()
print(api_result.content)
#print(f"Сейчас в {api_response['location']['name']} {api_response['current']['temperature']} градусов")
wind_speed= int(api_response['current']['wind_speed']/3.6)
#print(f"{api_response['current']['weather_descriptions']}\nВетер: {wind_speed}м\с направление: {api_response['current']['wind_dir']}")
#bot.send_message(message.chat.id, f"Сейчас в {api_response['request']['query']} {api_response['current']['temperature']} градусов")