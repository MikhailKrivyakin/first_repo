#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import random
import requests
import json
import numpy

from collections import Counter

# request for Short phrase recognizer
def RecognizeBySPR(URL,Model,Audio):
    res = {'text': '', 'respTime': ''}
    headers = {'accept': 'application/json', 'Content-Type': 'multipart/form-data'}
    FullURL = URL+'/spr/stt/'+Model
    dirName = os.path.dirname(Audio)
    fileName = Audio.replace(dirName+'/','')
    try:
        if dirName != '':
            FilePath = os.path.join(os.path.dirname(os.path.abspath(__file__)),dirName,fileName)
            files = {'wav': (fileName, open(FilePath, 'rb'), 'audio/wav', {'accept': 'application/json', 'Content-Type': 'multipart/form-data'})}
        else:
            FilePath = os.path.join(os.path.dirname(os.path.abspath(__file__)), Audio)
            files = {'wav': (fileName, open(FilePath, 'rb'), 'audio/wav', {'accept': 'application/json', 'Content-Type': 'multipart/form-data'})}
    except:
        res['text'] = 'Record file not found: ' + fileName
        res['respTime'] = 'Unknown'
        return res
    try:
        response = requests.post(FullURL, files=files)
        resp = response.json()
        res['text'] = str(resp['text']).replace('ё','е').replace("['",'').replace("']",'')
        res['respTime'] = str(response.elapsed.total_seconds())
        return res
    except Exception:
        res['text'] = 'Recognition Error!!!'
        res['respTime'] = 'Unknown'
        return res

# Simple progress bar
def progress(count, total, status=''):
    bar_len = 80
    filled_len = int(round(bar_len * count / float(total)))

    percents = round(100.0 * count / float(total), 1)
    bar = '█' * filled_len + '-' * (bar_len - filled_len)

    sys.stdout.write('\r[%s] %s%s ...%s\r' % (bar, percents, '%', status))
    sys.stdout.flush()

def editDistance(r, h):
    '''
    This function is to calculate the edit distance of reference sentence and the hypothesis sentence.
    Main algorithm used is dynamic programming.
    Attributes:
        r -> the list of words produced by splitting reference sentence.
        h -> the list of words produced by splitting hypothesis sentence.
    '''
    d = numpy.zeros((len(r)+1)*(len(h)+1), dtype=numpy.uint8).reshape((len(r)+1, len(h)+1))
    for i in range(len(r)+1):
        d[i][0] = i
    for j in range(len(h)+1):
        d[0][j] = j
    for i in range(1, len(r)+1):
        for j in range(1, len(h)+1):
            if r[i-1] == h[j-1]:
                d[i][j] = d[i-1][j-1]
            else:
                substitute = d[i-1][j-1] + 1
                insert = d[i][j-1] + 1
                delete = d[i-1][j] + 1
                d[i][j] = min(substitute, insert, delete)
    return d

def getStepList(r, h, d):
    '''
    This function is to get the list of steps in the process of dynamic programming.
    Attributes:
        r -> the list of words produced by splitting reference sentence.
        h -> the list of words produced by splitting hypothesis sentence.
        d -> the matrix built when calulating the editting distance of h and r.
    '''
    x = len(r)
    y = len(h)
    list = []
    while True:
        if x == 0 and y == 0:
            break
        elif x >= 1 and y >= 1 and d[x][y] == d[x-1][y-1] and r[x-1] == h[y-1]:
            list.append("e")
            x = x - 1
            y = y - 1
        elif y >= 1 and d[x][y] == d[x][y-1]+1:
            list.append("i")
            x = x
            y = y - 1
        elif x >= 1 and y >= 1 and d[x][y] == d[x-1][y-1]+1:
            list.append("s")
            x = x - 1
            y = y - 1
        else:
            list.append("d")
            x = x - 1
            y = y
    return list[::-1]

def CER(ActualPrase, RecognizedPhrase1,respTime1,wavName):
    result = {'Subs': 0,
              'Dels': 0,
              'Ins': 0,
              'CER': 0
             }

    # build the matrix
    d = editDistance(ActualPrase, RecognizedPhrase1)

    # find out the manipulation steps
    list = getStepList(ActualPrase, RecognizedPhrase1, d)
    counter = dict(Counter(list))
    result['Subs'] = counter.get('s')
    result['Dels'] = counter.get('d')
    result['Ins']  = counter.get('i')

    # find the CER
    res = float(d[len(ActualPrase)][len(RecognizedPhrase1)]) / len(ActualPrase) * 100
    result['CER1'] = str("%.2f" % res)

    result['row'] = f"{ActualPrase},{RecognizedPhrase1},{respTime1},{result['CER1']},{wavName}"
    result['row'] = result['row'].replace('None','0')

    return result

try:
    DIRin = sys.argv[1]
    URL1 = sys.argv[2]
    Model1 = sys.argv[3]

except IndexError:
    print('To evaluate the quality of recognition model:')
    print('place a records in "eval" folder in the SPR model directory and use:')
    print('python3 evaluate_spr_model.py [local model folder] [SPR-server-URL] [SPR-server-model-name]')
    sys.exit()

FILEout = f'{Model1}_evaluation_report.csv'

#load and shuffle records list
print('Creating records list...')
RECS = []
RecPath = os.path.join(os.path.dirname(os.path.abspath(__file__)),DIRin,'eval')

for file in os.listdir(RecPath):
    if file.endswith(".txt"):
        with open(RecPath + '/' + file,'r', encoding='utf-8') as source:
            for line in source:
                RECS.append(os.path.basename(file).replace('.txt','.wav') + '\t' + line)

random.shuffle(RECS)

#recognize all records
print('Done.')
print('Starting to recognize...')
with open(FILEout, "w", encoding='utf-8') as file:
    file.write(f'actual,recognized by SPR-{Model1},Resp.time,CER,wav\n')
    file.close()

total = len(RECS)
audio_paths = DIRin + '/eval/'
vCER1 = 0
counter = 0
for line in RECS:
    if line !='':
        fields = line.split('\t')
        ActualPhrase = fields[1].replace('ё','е').lower()
        progress(RECS.index(line),total-1,ActualPhrase[:25].replace('\n',''))
        if len(fields) > 1:

            RecognizedSPR1Phrase = RecognizeBySPR(URL1,Model1,audio_paths+fields[0])

            res = CER(ActualPhrase, RecognizedSPR1Phrase['text'], RecognizedSPR1Phrase['respTime'], DIRin + '/eval/' + fields[0])
            try:
                vCER1 += float(res.get('CER1'))
            except:
                pass
            counter += 1
            with open(FILEout, "a") as file:
                file.write(res['row']+"\n")
                file.close()
aCER1 = vCER1/counter

with open(RecPath.replace('eval','accuracy.txt'), "w", encoding='utf-8') as file:
    file.write(f'Объем тестового корпуса: {counter}\nПоказатель символьных ошибок: {aCER1}%\n')
    file.close()

print(f'\n{Model1} average CER: {aCER1}')
print('\nDone.')


