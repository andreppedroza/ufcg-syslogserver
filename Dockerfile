FROM ubuntu:14.04
#Change timezone.
RUN ln -snf /usr/share/zoneinfo/America/Recife /etc/localtime && echo "America/Recife" > /etc/timezone

RUN apt-get update \
    && apt-get install -y git net-tools vim nginx rsyslog supervisor php5-fpm php5-cli apache2-utils wget\
    && rm -rf /var/lib/apt/lists/*

RUN sed -i -e 's/listen\ =\ 127.0.0.1:9000/listen\ =\ \/var\/run\/php5-fpm.sock/' /etc/php5/fpm/pool.d/www.conf
RUN sed -i '1idaemon off;' /etc/nginx/nginx.conf

RUN rm -rf /var/www && git clone https://github.com/potsky/PimpMyLog.git /var/www
RUN sed -i -e 's/;daemonize\ =\ yes/daemonize\ =\ no/' /etc/php5/fpm/php-fpm.conf
RUN sed -i 's/^variables_order\ =.*/variables_order\ =\ \"GPCSE\"'/ /etc/php5/cli/php.ini

RUN sed -i -e 's/#$ModLoad\ imudp/$ModLoad\ imudp/' -e 's/#$UDPServerRun\ 514/$UDPServerRun\ 514/' /etc/rsyslog.conf
RUN sed -i -e 's/$ActionFileDefaultTemplate\ RSYSLOG_TraditionalFileFormat/$ActionFileDefaultTemplate\ RSYSLOG_SyslogProtocol23Format/' /etc/rsyslog.conf

RUN adduser www-data adm

#Add cron job to cleanup logs every half month.
RUN mkdir -p /etc/cleanup && echo "* * * * * root /bin/echo '' > /var/log/net/syslog.log" > /etc/cleanup/cron
RUN wget -O /usr/bin/go-crond https://github.com/webdevops/go-crond/releases/download/0.6.1/go-crond-64-linux && chmod +x /usr/bin/go-crond

COPY nginx-default /etc/nginx/sites-enabled/default
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY config.user.php /var/www/
COPY rsyslog.conf /etc/rsyslog.conf
COPY create-user.php /var/www/
COPY run.sh /

EXPOSE 80 514/udp

CMD ["/run.sh"]
