import logging

logfile = 'log_1.log'

log = logging.getLogger("my_log")
log.setLevel(logging.INFO)
FH = logging.FileHandler(logfile)
basic_formater = logging.Formatter('%(asctime)s : [%(levelname)s] : %(message)s')
FH.setFormatter(basic_formater)
log.addHandler(FH)

A = [i for i in range(5)]
log.info("start program")
try:
    for i in range(6):
        print (A[i]**2)
        log.info("program calculate square " + str(A[i]))
except:
	log.error("произошла ошибка")
log.info("end program")