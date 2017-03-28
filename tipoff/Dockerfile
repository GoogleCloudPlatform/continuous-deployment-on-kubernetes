# Copyright 2015 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Pull from the ubuntu:14.04 image
FROM ubuntu:14.04

# Set the author
MAINTAINER Denis Bogdan <denis.bogdan@example.com>

ENV DEBIAN_FRONTEND noninteractive

# Update cache and install base package
RUN apt-get update && apt-get -y install \
            nginx \
            php5-fpm \
            php5-cli \
            php5-mcrypt \
            git \
            mc \
            curl

# Turn off daemon mode
RUN echo "\ndaemon off;" >> /etc/nginx/nginx.conf

# --- Modify PHP Configuration
# Backup default configuaration
RUN cp /etc/php5/fpm/php.ini /etc/php5/fpm/php.ini.org

# Configure PHP Settings
RUN perl -pi -e 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php5/fpm/php.ini

# Enable the MCrypt extension
#RUN php5enmod mycrypt

# --- Get web app source from git
RUN mkdir -p /var/www/tipoff

# --- Please modify the username/password for gitub to your own
RUN git clone https://source.developers.google.com/p/tipoffwebsite/r/tipoff /var/www/tipoff

# --- Modify nginx Configuration
# Backup default configuration
RUN cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.org

# Configure nginx Settings
COPY default.conf /etc/nginx/sites-available/default

# Install Laravel Framework
WORKDIR cd ~
RUN curl -sS https://getcomposer.org/installer -o composer-setup.php
RUN php composer-setup.php --install-dir-/usr/local/bin --filename=composer
WORKDIR /var/www/tipoff
RUN composer install

RUN chown -R :www-data /var/www/tipoff
RUN chmod -R 775 /var/www/tipoff/storage

WORKDIR /var/www/tipoff

RUN cp .env.example .env
RUN php artisan key:generate

CMD service php5-fpm start && nginx

EXPOSE 80
EXPOSE 443
