import json


dictionary = "dictionary.txt"
debug_sentence = "меня. покусали. яблоки."
alphabet = [ " ", "ɐ", "a", "b", "bʲ", "t͡s", "t͡ɕ", "d", "dʲ", "ɛ", "e", "f", "fʲ", "g", 
            "gʲ", "h", "hʲ", "ɪ", "i", "j", "k", "kʲ", "l", "lʲ", "m", "mʲ", "n", "nʲ", 
            "ɵ", "o", "p", "pʲ", "r", "rʲ", "s", "ɕː", "ʂ", "sʲ", "t", "tʲ", "ʊ", "u", "v", 
            "vʲ", "ɨ", "ɨ", "z", "ʐ", "zʲ", ",", ".", "!", "?", "-", ":", ";", "+" ]
# дополнительный спсиок со знаками препинания, нужен для проверки
punctuation = [",", ".", "!", "?", "-", ":", ";", "+"]
dict = json.load(open(dictionary))

def convert(sentence):
    list = []
    for word in sentence.split():
        # т.к. в словаре нет слов со знаками препинания вводим доп. проверку, что слово заканчиваетася на них. 
        # если да, то отрезаем знак от слова, получаем слово из словаря и дополняем знаком
        if word[-1] in punctuation:
            mark = word[-1]
            word = word[:-1]
            # получаем массив индексов для слова из словаря
            list = list + dict.get(word)
            # добавляем индекс знака препинания
            list.append(alphabet.index(mark))
            # добавляем пробел, так как слова разделены пробелом
            list.append(alphabet.index(" "))
        else:
            # получаем массив индексов для слова из словаря
            list = list + dict.get(word)
            # добавляем пробел, так как слова разделены пробелом
            list.append(alphabet.index(" "))
    # маленький костыль для удаления лишнего пробела в конце
    list.pop()
    return(list)