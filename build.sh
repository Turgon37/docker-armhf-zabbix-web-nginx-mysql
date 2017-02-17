#!/usr/bin/env bash

ZABBIX_VERSION="3.2"
ZABBIX_URL="https://github.com/zabbix/zabbix-docker.git"
ZABBIX_TYPE="web"
ZABBIX_DB_TYPE="mysql"
ZABBIX_WEBSERVER_TYPE="nginx"

DOCKER_IMAGE=turgon37/armhf-zabbix-${ZABBIX_TYPE}-${ZABBIX_WEBSERVER_TYPE}-${ZABBIX_DB_TYPE}
#BUILD_TIME=$(date --rfc-2822)
BUILD_TIME="not set"

echo "[[ Build ${DOCKER_IMAGE} docker image ]]"
echo '...Downloading Official x86 project'
git clone --branch "${ZABBIX_VERSION}" --single-branch "${ZABBIX_URL}" zabbix-docker

echo '...prepare the build'
echo '...copying files'
directory="zabbix-docker/${ZABBIX_TYPE}-${ZABBIX_WEBSERVER_TYPE}-${ZABBIX_DB_TYPE}/alpine"
for f in `ls -1 $directory`; do
  ignore=false
  case $f in
    README*|LICENSE|build.sh|Dockerfile_armhf)
      ignore=true
      ;;
  esac
  if [ "$ignore" == 'false' ]; then
    cp --recursive $directory/$f ./
  fi
done

echo '...make Dockerfile'
# remove base image
sed -i -e 's|^FROM\s*.*$||g' Dockerfile
# remove declared maintainer
sed -i -e 's|^MAINTAINER\s*.*$||g' Dockerfile

# create fina ldockerfile
cat Dockerfile_armhf Dockerfile > Dockerfile_tmp

echo '...Build the images'
docker build --build-arg ZABBIX_VERSION="$ZABBIX_VERSION" \
             --build-arg ZABBIX_TYPE="$ZABBIX_TYPE" \
             --build-arg ZABBIX_DB_TYPE="$ZABBIX_DB_TYPE" \
             --build-arg ZABBIX_WEBSERVER_TYPE="$ZABBIX_WEBSERVER_TYPE" \
             --build-arg BUILD_TIME="$BUILD_TIME" \
             --build-arg APK_FLAGS_COMMON="" \
             --tag ${DOCKER_IMAGE}:${ZABBIX_VERSION} \
             --tag ${DOCKER_IMAGE}:latest \
             --file Dockerfile_tmp \
             .

docker push ${DOCKER_IMAGE}:latest ${DOCKER_IMAGE}:${ZABBIX_VERSION}

echo '...Clean the directory'
for f in `ls`; do
  remove=true
  case $f in
    README*|LICENSE|build.sh|Dockerfile_armhf)
      remove=false
      ;;
  esac
  if [ "$remove" == 'true' ]; then
    rm --recursive --force "./$f"
  fi
done
