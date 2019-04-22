FROM ubuntu:18.04

ENV TERM=xterm \
	TZ=America/Bogota \
    DEBIAN_FRONTEND=noninteractive

# variebles nginx
ENV SERVER_NAME=localhost \
	ROOT_PATH=/var/www/html

# Install basic
RUN apt-get update && apt-get upgrade --yes && \
	apt-get install --yes nano wget curl git sudo nginx gettext-base memcached 

# Install php and libraries
RUN apt-get update && apt-get upgrade --yes && \
 	apt-get install -y  php \
		php-fpm \
		php-cli \
		php-gd \
		php-opcache \
		php-curl \
		php-intl \
		php-date \
		php-dom \
		php-json \
		php-pdo \
		php-xml \
		php-tokenizer \
		php-zip \
		php-mbstring\
		php-mysql \
		php-pgsql \
		php-sqlite3 \
		php-memcached \
		php-uploadprogress \
		php-xdebug

# Cleaning
RUN apt-get -y autoremove && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Confugure php.ini and www.conf
RUN sed -ri 's/^;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/7.2/fpm/php.ini && \ 
	sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php/7.2/fpm/php.ini && \
	sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php/7.2/fpm/php.ini && \
	sed -i -e "s/memory_limit\s*=\s*128M/memory_limit = 1024M/g" /etc/php/7.2/fpm/php.ini && \
	sed -i -e "s/max_execution_time\s*=\s*30/max_execution_time = 3000/g" /etc/php/7.2/fpm/php.ini && \
	sed -i -e "s/;extension=php_intl.dll/extension=php_intl.dll/g" /etc/php/7.2/fpm/php.ini && \
	sed -i -e "s/;extension=php_pdo_mysql.dll/extension=php_pdo_mysql.dll/g" /etc/php/7.2/fpm/php.ini && \
	sed -i -e "s/;extension=php_pdo_pgsql.dll/extension=php_pdo_pgsql.dll/g" /etc/php/7.2/fpm/php.ini && \
	sed -i -e "s/;extension=php_pdo_sqlite.dll/extension=php_pdo_sqlite.dll/g" /etc/php/7.2/fpm/php.ini && \	
	sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.2/fpm/php-fpm.conf && \
	sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php/7.2/fpm/pool.d/www.conf && \
	sed -i -e "s/pm.max_children = 5/pm.max_children = 9/g" /etc/php/7.2/fpm/pool.d/www.conf && \
	sed -i -e "s/pm.start_servers = 2/pm.start_servers = 3/g" /etc/php/7.2/fpm/pool.d/www.conf && \
	sed -i -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" /etc/php/7.2/fpm/pool.d/www.conf && \
	sed -i -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" /etc/php/7.2/fpm/pool.d/www.conf && \
	sed -i -e "s/pm.max_requests = 500/pm.max_requests = 200/g" /etc/php/7.2/fpm/pool.d/www.conf && \
	sed -i -e "s/;request_terminate_timeout = 0/request_terminate_timeout = 3000/g" /etc/php/7.2/fpm/php-fpm.conf && \
	sed -i -e 's/apache/mceith/g' /etc/php/7.2/fpm/pool.d/www.conf

# config Xdebug
RUN sed -i '$ a\xdebug.var_display_max_depth=4' /etc/php/7.2/mods-available/xdebug.ini && \
    sed -i '$ a\xdebug.max_nesting_level=500' /etc/php/7.2/mods-available/xdebug.ini && \
    sed -i '$ a\xdebug.var_display_max_data=-1' /etc/php/7.2/mods-available/xdebug.ini && \
    sed -i '$ a\xdebug.remote_enable=1' /etc/php/7.2/mods-available/xdebug.ini && \
    sed -i '$ a\xdebug.remote_port="9000"' /etc/php/7.2/mods-available/xdebug.ini

# Fix ownership of sock file for php-fpm
RUN sed -i -e "s/;listen.mode = 0660/listen.mode = 0750/g" /etc/php/7.2/fpm/pool.d/www.conf && \
	find /etc/php/7.2/cli/conf.d/ -name "*.ini" -exec sed -i -re 's/^(\s*)#(.*)/\1;\2/g' {} \; && \
	mkdir /run/php

# Nginx site conf
COPY default /etc/nginx/sites-available/default

WORKDIR ${ROOT_PATH}

EXPOSE 80 

CMD sed -i -e "s|root /www|root $ROOT_PATH|g" /etc/nginx/sites-available/default &&\
	sed -i -e "s|server_name _;|server_name $SERVER_NAME;|g" /etc/nginx/sites-available/default &&\
	service php7.2-fpm start && \
	nginx -g 'daemon off;' 
