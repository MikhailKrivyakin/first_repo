FROM alpine:3.16.2
ENV TZ=Europe/Moscow
RUN apk update
RUN apk upgrade
RUN apk add bash \
    git \
    supervisor \
    curl 
COPY ./supervisord.conf /etc/supervisord.conf
COPY ./script.sh /opt/script.sh
RUN chmod +x /opt/script.sh 
CMD supervisord



