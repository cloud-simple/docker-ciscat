#!/usr/bin/env bash
set -e

TZ=${TZ:-UTC}

ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime
echo ${TZ} > /etc/timezone
echo "Set timezone to ${TZ}"

if [ ! -e ${CATALINA_HOME}/webapps/CCPD.war ] ; then
  test -e /data/downloads/dashboard/*.zip || {
    echo "== err: no '{CATALINA_HOME}/webapps/CCPD.war' file is present and no distributive is provided; exiting"
    exit -1
    }
  mkdir -p /tmp/downloads-ccdp
  unzip -q -d /tmp/downloads-ccdp "$(ls -A1 /data/downloads/dashboard/*.zip | head -1)"
  mv "$(ls -A1 /tmp/downloads-ccdp/*/CCPD.war | head -1)" ${CATALINA_HOME}/webapps/
  rm -fr /tmp/downloads-ccdp
  echo "Extracted 'CCPD.war' file"
fi

### TODO
### - prepare tomcat
### - extract WAR
### - ...

echo "Everything is ready, proceed with 'exec'uting the following command: [$@]"

exec "$@"
