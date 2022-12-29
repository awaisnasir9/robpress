FROM php:7-apache

# Install OS requirements
RUN apt-get update && apt-get install git curl mariadb-client -y

# Apache requirements
RUN a2enmod rewrite

# PHP requirements
RUN docker-php-ext-install pdo_mysql

# Environment configuration
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"
RUN sed -ri -e 's!short_open_tag = Off!short_open_tag = On!g' "$PHP_INI_DIR/php.ini"

# Get and start RobPress
ARG ROBPRESS_USER
ARG ROBPRESS_PASSWORD
RUN mkdir ~/.ssh/
COPY wait-for-it.sh /
COPY getrob.sh /
CMD ["/getrob.sh"]
