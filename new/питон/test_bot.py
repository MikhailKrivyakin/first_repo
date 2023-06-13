

text = 'оповести о модели common для spr'


model = text.replace("оповести о модели","").split()[0]
service = text.replace("оповести о модели","").split()[-1]
print(model)
print(service)