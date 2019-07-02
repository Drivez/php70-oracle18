FROM php:7.0-apache

RUN apt-get update \
    && apt-get install -yqq apt-utils curl unzip libaio1 libpng-dev libzip-dev libxml2-dev vim  \
    && a2enmod rewrite negotiation

# Copy over Oracle Instantclient .zip files
COPY instantclient-basic-linux.x64-18.3.0.0.0dbru.zip /src/app/docker/oracle/instantclient-basic-linux.x64-18.3.0.0.0dbru.zip
COPY instantclient-sdk-linux.x64-18.3.0.0.0dbru.zip /src/app/docker/oracle/instantclient-sdk-linux.x64-18.3.0.0.0dbru.zip

# Install Oracle Instantclient
RUN mkdir -p /opt/oracle/ \
    && unzip /src/app/docker/oracle/instantclient-basic-linux.x64-18.3.0.0.0dbru.zip -d /opt/oracle \
    && unzip /src/app/docker/oracle/instantclient-sdk-linux.x64-18.3.0.0.0dbru.zip -d /opt/oracle \
    && echo /opt/oracle/instantclient_18_3 > /etc/ld.so.conf.d/oracle-instantclient.conf \
    && ldconfig

ENV LD_LIBRARY_PATH /opt/oracle/instantclient_18_3:${LD_LIBRARY_PATH}
ENV NLS_LANG=NORWEGIAN_NORWAY.WE8ISO8859P15

# Install PHP & Oracle extensions
RUN echo 'instantclient,/opt/oracle/instantclient_18_3/' | pecl install oci8 \
      && docker-php-ext-configure pdo_oci --with-pdo-oci=instantclient,/opt/oracle/instantclient_18_3 \
      && docker-php-ext-install \
              pdo_oci \
              gd \
              zip \
              soap \
      && docker-php-ext-enable \
              oci8
# Install Composer
RUN curl -sS https://getcomposer.org/installer | \
    php -- --install-dir=/usr/bin/ --filename=composer

# Install Xdebug
RUN pecl install xdebug-2.7.0beta1 && docker-php-ext-enable xdebug \
    && echo 'zend_extension="xdebug.so"' >> /usr/local/etc/php/php.ini \
    && echo 'xdebug.remote_port=9000' >> /usr/local/etc/php/php.ini \
    && echo 'xdebug.remote_enable=1' >> /usr/local/etc/php/php.ini \
    && echo 'xdebug.idekey=PHPSTORM' >> /usr/local/etc/php/php.ini \
    && echo 'xdebug.remote_connect_back=0' >> /usr/local/etc/php/php.ini

WORKDIR /srv/app

COPY . ./

RUN composer install --no-interaction -o
