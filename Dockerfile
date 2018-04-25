FROM ubuntu:16.04

ENV DEBIAN_FRONTEND noninteractive
ENV TERM xterm

# Install base packages
RUN apt-get update  && \
    apt-get install -y software-properties-common \
    	build-essential \
    	make \
    	sudo

RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update && \
    apt-get install -y language-pack-en-base &&\
    export LC_ALL=en_US.UTF-8 && \
    export LANG=en_US.UTF-8

# Add repository PPA php 5.6
RUN DEBIAN_FRONTEND=noninteractive LC_ALL=en_US.UTF-8 add-apt-repository ppa:ondrej/php

# Install miscellaneous
RUN apt-get update && apt-get upgrade --yes && \
	apt-get install --yes nano wget curl git

# Install php and libraries
RUN apt-get update && apt-get upgrade --yes && \
 	apt-get install -y  php5.6 \
		php5.6-opcache \
		php5.6-fpm \
		php5.6-common \
		php5.6-gd \
		php5.6-mysql \
		php5.6-imap \
		php5.6-cli \
		php5.6-cgi \
		php5.6-mcrypt \
		php5.6-pgsql \
		php5.6-curl \
		php5.6-intl \
		php5.6-pspell \
		php5.6-recode \
		php5.6-sqlite3 \
		php5.6-tidy \
		php5.6-xmlrpc \
		php5.6-xsl \
		php5.6-zip \
		php5.6-mbstring\
		php-pear \
		php-auth \
		php-memcache \
		php-imagick \
		php-gettext

RUN apt-get update && apt-get upgrade --yes && \
	apt-get install --yes nginx \
		memcached \
		mcrypt \
		imagemagick \
		libruby

# Install Node.js
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
	apt-get update && \
	apt-get install -y nodejs

# Cleaning
RUN apt-get -y autoremove && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer


# Confugure php.ini
RUN sed -ri 's/^;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/5.6/fpm/php.ini && \
	sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php/5.6/fpm/php.ini && \
	sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php/5.6/fpm/php.ini && \
	sed -i -e "s/memory_limit\s*=\s*128M/memory_limit = 1024M/g" /etc/php/5.6/fpm/php.ini && \
	sed -i -e "s/max_execution_time\s*=\s*30/max_execution_time = 3000/g" /etc/php/5.6/fpm/php.ini && \
	sed -i -e "s/;extension=php_intl.dll/extension=php_intl.dll/g" /etc/php/5.6/fpm/php.ini && \
	sed -i -e "s/;extension=php_pdo_mysql.dll/extension=php_pdo_mysql.dll/g" /etc/php/5.6/fpm/php.ini && \
	sed -i -e "s/;extension=php_pdo_pgsql.dll/extension=php_pdo_pgsql.dll/g" /etc/php/5.6/fpm/php.ini && \
	sed -i -e "s/;extension=php_pdo_sqlite.dll/extension=php_pdo_sqlite.dll/g" /etc/php/5.6/fpm/php.ini && \
	sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/5.6/fpm/php-fpm.conf && \
	sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php/5.6/fpm/pool.d/www.conf && \
	sed -i -e "s/pm.max_children = 5/pm.max_children = 9/g" /etc/php/5.6/fpm/pool.d/www.conf && \
	sed -i -e "s/pm.start_servers = 2/pm.start_servers = 3/g" /etc/php/5.6/fpm/pool.d/www.conf && \
	sed -i -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" /etc/php/5.6/fpm/pool.d/www.conf && \
	sed -i -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" /etc/php/5.6/fpm/pool.d/www.conf && \
	sed -i -e "s/pm.max_requests = 500/pm.max_requests = 200/g" /etc/php/5.6/fpm/pool.d/www.conf && \
	sed -i -e "s/;request_terminate_timeout = 0/request_terminate_timeout = 3000/g" /etc/php/5.6/fpm/php-fpm.conf && \
	sed -i -e 's/apache/mceith/g' /etc/php/5.6/fpm/pool.d/www.conf

# Fix ownership of sock file for php-fpm
RUN sed -i -e "s/;listen.mode = 0660/listen.mode = 0750/g" /etc/php/5.6/fpm/pool.d/www.conf && \
	find /etc/php/5.6/cli/conf.d/ -name "*.ini" -exec sed -i -re 's/^(\s*)#(.*)/\1;\2/g' {} \; && \
	mkdir /run/php

# Nginx site conf
COPY default /etc/nginx/sites-available/default

# Set user deployer
RUN useradd -g 33 -m deployer && echo "deployer:deployer" | chpasswd && adduser deployer sudo
RUN echo "deployer ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER deployer

WORKDIR /home/deployer

EXPOSE 80 443

CMD sudo service php5.6-fpm start && \
	sudo nginx -g "daemon off;"