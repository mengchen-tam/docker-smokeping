# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/baseimage-alpine:3.22

# set version label
ARG BUILD_DATE
ARG VERSION
ARG SMOKEPING_VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="notdriz"

RUN \
  echo "**** install packages ****" && \
  if [ -z ${SMOKEPING_VERSION+x} ]; then \
    SMOKEPING_VERSION=$(curl -sL "http://dl-cdn.alpinelinux.org/alpine/v3.22/main/x86_64/APKINDEX.tar.gz" | tar -xz -C /tmp \
    && awk '/^P:smokeping$/,/V:/' /tmp/APKINDEX | sed -n 2p | sed 's/^V://'); \
  fi && \
  apk add --no-cache --virtual=build-dependencies \
    build-base \
    perl-app-cpanminus \
    perl-dev && \
  apk add --no-cache \
    apache2 \
    apache2-ctl \
    apache2-utils \
    apache-mod-fcgid \
    bc \
    bind-tools \
    font-noto-cjk \
    irtt \
    openssh-client \
    perl-authen-radius \
    perl-json-maybexs \
    perl-lwp-protocol-https \
    perl-path-tiny \
    smokeping==${SMOKEPING_VERSION} \
    ssmtp \
    sudo \
    python3 \
    py3-pip \
    py3-boto3 \
    py3-requests \
    tcptraceroute && \
  echo "**** Build perl TacacsPlus module ****" && \
  cpanm Authen::TacacsPlus && \
  echo "**** Build perl InfluxDB modules ****" && \
  cpanm InfluxDB::HTTP && \
  cpanm Method::Signatures --force && \
  cpanm Object::Result && \
  cpanm InfluxDB::LineProtocol && \
  echo "**** give setuid access to traceroute & tcptraceroute ****" && \
  chmod a+s /usr/bin/traceroute && \
  chmod a+s /usr/bin/tcptraceroute && \
  echo "**** fix path to cropper.js ****" && \
  sed -i 's#src="/cropper/#/src="cropper/#' /etc/smokeping/basepage.html && \
  printf "Linuxserver.io version: ${VERSION}\nBuild-date: ${BUILD_DATE}" > /build_version && \
  echo "**** Cleanup ****" && \
  apk del --purge \
    build-dependencies && \
  rm -rf \
    /tmp/* \
    /root/.cpanm \
    /etc/apache2/httpd.conf

# add local files
COPY root/ /

# ports and volumes
EXPOSE 80

VOLUME /config /data
