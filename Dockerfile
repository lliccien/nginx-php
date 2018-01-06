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

# Add repository PPA php 7.1
RUN DEBIAN_FRONTEND=noninteractive LC_ALL=en_US.UTF-8 add-apt-repository ppa:ondrej/php

# Install miscellaneous
RUN apt-get update && apt-get upgrade --yes && \
	apt-get install --yes nano wget curl git 

# Install php and libraries
RUN apt-get update && apt-get upgrade --yes && \
 	apt-get install -y  php7.1 \
		php7.1-opcache \
		php7.1-fpm \
		php7.1-common \
		php7.1-gd \
		php7.1-mysql \
		php7.1-imap \
		php7.1-cli \
		php7.1-cgi \
		php7.1-mcrypt \
		php7.1-curl \
		php7.1-intl \
		php7.1-pspell \
		php7.1-recode \
		php7.1-sqlite3 \
		php7.1-tidy \
		php7.1-xmlrpc \
		php7.1-xsl \
		php7.1-zip \
		php7.1-mbstring\
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

# Cleaning
RUN apt-get -y autoremove && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer


# Confugure php.ini
RUN sed -ri 's/^;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/7.1/fpm/php.ini && \ 
	sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php/7.1/fpm/php.ini && \
	sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php/7.1/fpm/php.ini && \
	sed -i -e "s/memory_limit\s*=\s*128M/memory_limit = 1024M/g" /etc/php/7.1/fpm/php.ini && \
	sed -i -e "s/max_execution_time\s*=\s*30/max_execution_time = 3000/g" /etc/php/7.1/fpm/php.ini && \
	sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.1/fpm/php-fpm.conf && \
	sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php/7.1/fpm/pool.d/www.conf && \
	sed -i -e "s/pm.max_children = 5/pm.max_children = 9/g" /etc/php/7.1/fpm/pool.d/www.conf && \
	sed -i -e "s/pm.start_servers = 2/pm.start_servers = 3/g" /etc/php/7.1/fpm/pool.d/www.conf && \
	sed -i -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" /etc/php/7.1/fpm/pool.d/www.conf && \
	sed -i -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" /etc/php/7.1/fpm/pool.d/www.conf && \
	sed -i -e "s/pm.max_requests = 500/pm.max_requests = 200/g" /etc/php/7.1/fpm/pool.d/www.conf && \
	sed -i -e "s/;request_terminate_timeout = 0/request_terminate_timeout = 3000/g" /etc/php/7.1/fpm/php-fpm.conf && \
	sed -i -e 's/apache/mceith/g' /etc/php/7.1/fpm/pool.d/www.conf

# Fix ownership of sock file for php-fpm
RUN sed -i -e "s/;listen.mode = 0660/listen.mode = 0750/g" /etc/php/7.1/fpm/pool.d/www.conf && \
	find /etc/php/7.1/cli/conf.d/ -name "*.ini" -exec sed -i -re 's/^(\s*)#(.*)/\1;\2/g' {} \; && \
	mkdir /run/php

# Nginx site conf
COPY default /etc/nginx/sites-available/default

# Set user deployer
RUN useradd -g 33 -m deployer && echo "deployer:deployer" | chpasswd && adduser deployer sudo
RUN echo "deployer ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER deployer

WORKDIR /home/deployer

EXPOSE 80 443

CMD sudo service php7.1-fpm start && \
	sudo nginx -g "daemon off;" 