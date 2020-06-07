# from https://www.drupal.org/docs/8/system-requirements/drupal-8-php-requirements
FROM php:7.4-fpm-alpine

# install the PHP extensions we need
# postgresql-dev is needed for https://bugs.alpinelinux.org/issues/3642
RUN set -eux; \
  \
  apk add --no-cache --virtual .build-deps \
  coreutils \
  freetype-dev \
  libjpeg-turbo-dev \
  libpng-dev \
  libzip-dev \
  postgresql-dev \
  unzip \
  ; \
  \
  docker-php-ext-configure gd --with-freetype --with-jpeg \
  ; \
  \
  docker-php-ext-install -j "$(nproc)" \
  gd \
  opcache \
  pdo_mysql \
  pdo_pgsql \
  zip \
  ; \
  \
  runDeps="$( \
  scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
  | tr ',' '\n' \
  | sort -u \
  | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
  )"; \
  apk add --virtual .drupal-phpexts-rundeps $runDeps; \
  apk del .build-deps

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
# https://getcomposer.org/doc/03-cli.md#composer-allow-superuser
ENV COMPOSER_ALLOW_SUPERUSER=1

#Install drush launcher
ADD https://github.com/drush-ops/drush-launcher/releases/download/0.6.0/drush.phar drush.phar
RUN chmod +x drush.phar \
    && mv drush.phar /usr/local/bin/drush

COPY .docker/php/opcache.ini /usr/local/etc/php/conf.d/opcache-recommended.ini

WORKDIR /srv/drupal
