import json
dictionary = "new_output.txt"
alphabet = [ " ", "ɐ", "a", "b", "bʲ", "t͡s", "t͡ɕ", "d", "dʲ", "ɛ", "e", "f", "fʲ", "g", 
            "gʲ", "h", "hʲ", "ɪ", "i", "j", "k", "kʲ", "l", "lʲ", "m", "mʲ", "n", "nʲ", 
            "ɵ", "o", "p", "pʲ", "r", "rʲ", "s", "ɕː", "ʂ", "sʲ", "t", "tʲ", "ʊ", "u", "v", 
            "vʲ", "ɨ", "ɨ", "z", "ʐ", "zʲ", ",", ".", "!", "?", "-", ":", ";", "+" ]



d = {}
file = open("text.txt")
for line in file:
    text, transcribe = line.split(maxsplit=1)
    list = []
    for letter in transcribe.split():
        list.append(alphabet.index(letter))
    d[text.replace('"',"")]=list
    
print(d)

#out_file = open("output.txt",'w')
#out_file.write(json.dumps(d))
#out_file.close()