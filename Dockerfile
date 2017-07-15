FROM php:7.1-fpm-alpine

LABEL maintainer "alihan93.93@gmail.com"

ENV PHPIZE_DEPS \
    autoconf \
    cmake \
    file \
    g++ \
    gcc \
    libc-dev \
    pcre-dev \
    make \
    freetype-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    libpng \
    libjpeg-turbo

ENV MEMCACHED_DEPS zlib-dev libmemcached-dev cyrus-sasl-dev

RUN apk add --no-cache --virtual .persistent-deps \
    # for mcrypt extension
    libmcrypt-dev \
    freetype \
    libpng \
    libjpeg-turbo 

RUN set -xe \
    && apk add --no-cache --update libmemcached-libs zlib \
    && apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
    && apk add --no-cache --update --virtual .memcached-deps $MEMCACHED_DEPS \
    && pecl install memcached xdebug\
    && echo "extension=memcached.so" > /usr/local/etc/php/conf.d/20_memcached.ini \
    && docker-php-ext-configure pdo_mysql --with-pdo-mysql \
    && docker-php-ext-configure mbstring --enable-mbstring \
    && docker-php-ext-configure gd \
            --with-gd \
            --with-freetype-dir=/usr/include/ \
            --with-png-dir=/usr/include/ \
            --with-jpeg-dir=/usr/include/ \
    && NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) \
    && docker-php-ext-enable xdebug \
    && docker-php-ext-install \
        mcrypt \
        mysqli \
        pdo_mysql \
        mbstring \
        sockets \
        opcache \
        -j${NPROC} gd \
    && apk del .build-deps .memcached-deps \
    && rm -rf /tmp/*

RUN set -xe \
    && sed -i '1 a xdebug.remote_mode=req' /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && sed -i '1 a xdebug.remote_handler=dbgp' /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && sed -i '1 a xdebug.remote_connect_back=0' /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && sed -i '1 a xdebug.remote_host=10.254.254.254' /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && sed -i '1 a xdebug.remote_port=9001' /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && sed -i '1 a xdebug.remote_enable=1' /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && sed -i '1 a xdebug.remote_autostart=0' /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && sed -i '1 a xdebug.idekey=PHPSTORM' /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && sed -i '1 a xdebug.profiler_enable_trigger=1' /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && sed -i '1 a xdebug.profiler_output_dir = /var/www/html/xdebug-traces/' /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && sed -i '1 a xdebug.trace_output_dir=/var/www/html/xdebug-traces/' /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && sed -i '1 a xdebug.remote_log="/tmp/xdebug.log"' /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
