FROM ghcr.io/linuxserver/baseimage-alpine-nginx:3.14

# set version label
ARG BUILD_DATE
ARG VERSION
ARG SNIPEIT_RELEASE
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="TheLamer, sparkyballs"

RUN \
  echo "**** install build packages ****" && \
  apk add --no-cache --virtual=build-dependencies \
    composer && \
  echo "**** install runtime packages ****" && \
  apk add --no-cache \
    curl \
    libxml2 \
    mariadb-client \
    php7-bcmath \
    php7-ctype \
    php7-curl \
    php7-gd \
    php7-iconv \
    php7-ldap \
    php7-mbstring \
    php7-mcrypt \
    php7-phar \
    php7-pdo_mysql \
    php7-pdo_sqlite \
    php7-sqlite3 \
    php7-tokenizer \
    php7-xml \
    php7-xmlreader \
    php7-zip \
    tar \
    unzip && \
  echo "**** configure php-fpm to pass env vars ****" && \
  sed -i \
    's/;clear_env = no/clear_env = no/g' \
    /etc/php7/php-fpm.d/www.conf && \
  echo "env[PATH] = /usr/local/bin:/usr/bin:/bin" >> /etc/php7/php-fpm.conf && \
  echo "**** install snipe-it ****" && \
  composer install -d /app/www && \
  mkdir -p \
    /app/www/ && \
  if [ -z ${SNIPEIT_RELEASE+x} ]; then \
    SNIPEIT_RELEASE=$(curl -sX GET "https://api.github.com/repos/snipe/snipe-it/releases/latest" \
    | awk '/tag_name/{print $4;exit}' FS='[""]'); \
  fi && \
  curl -o \
    /tmp/snipeit.tar.gz -L \
    "https://github.com/snipe/snipe-it/archive/${SNIPEIT_RELEASE}.tar.gz" && \
  tar xf \
    /tmp/snipeit.tar.gz -C \
    /app/www/ --strip-components=1 && \
  cp /app/www/docker/docker.env /app/www/.env && \
  echo "**** move storage directories to defaults ****" && \
  mv \
    "/app/www/storage" \
    "/app/www/public/uploads" \
    /defaults/ && \
  echo "**** cleanup ****" && \
  apk del --purge \
    build-dependencies && \
  rm -rf \
    /root/.composer \
    /tmp/*

# copy local files
COPY root/ /

# ports and volumes
EXPOSE 80 443
VOLUME ["/config"]
