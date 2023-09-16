FROM php:7.4-apache-buster


WORKDIR /root
ENV GLPI_CONFIG_DIR=/etc/glpi
ENV GLPI_VAR_DIR=/var/lib/glpi
ENV GLPI_LOG_DIR=/var/log/glpi
ENV GLPI_VERSION=10.0.6
ENV FUSIONINVENTORY_VERSION=10.0.6+1.1

RUN \
apt-get update && \
apt-get install --no-install-recommends -y \
   runit \
   cron \
   libbz2-dev \
   libzip-dev \
   libxml2-dev \
   libldap2-dev \
   libicu-dev \
   libpng-dev \
   zlib1g-dev \
   default-mysql-client \
   && \
pecl install apcu && docker-php-ext-enable apcu && \
docker-php-ext-configure mysqli && docker-php-ext-install mysqli && \
docker-php-ext-configure gd && docker-php-ext-install gd && \
docker-php-ext-configure intl && docker-php-ext-install intl && \
docker-php-ext-configure ldap && docker-php-ext-install ldap && \
docker-php-ext-configure xmlrpc && docker-php-ext-install xmlrpc && \
docker-php-ext-configure exif && docker-php-ext-install exif && \
docker-php-ext-configure zip && docker-php-ext-install zip && \
docker-php-ext-configure bz2 && docker-php-ext-install bz2 && \
docker-php-ext-configure opcache && docker-php-ext-install opcache

COPY CAS-1.3.8.tgz /root/
RUN pear install /root/CAS-1.3.8.tgz
COPY service/ /etc/service/
COPY glpi_init.sh /root/glpi_init.sh
COPY glpi.cron /etc/cron.d/glpi
ADD https://github.com/glpi-project/glpi/releases/download/${GLPI_VERSION}/glpi-${GLPI_VERSION}.tgz /root/glpi-${GLPI_VERSION}.tgz
ADD https://github.com/fusioninventory/fusioninventory-for-glpi/releases/download/glpi${FUSIONINVENTORY_VERSION}/fusioninventory-${FUSIONINVENTORY_VERSION}.tar.bz2 /root/fusioninventory-${FUSIONINVENTORY_VERSION}.tar.bz2

RUN \
chmod a+x /root/glpi_init.sh && \
rm -f /var/www/html/* /root/CAS-1.3.8.tgz && \
apt-get clean && \
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENTRYPOINT ["/usr/bin/runsvdir", "-P", "/etc/service"]
