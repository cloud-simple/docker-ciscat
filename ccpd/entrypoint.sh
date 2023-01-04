#!/usr/bin/env bash
set -e

MYSQL_USER=${MYSQL_USER:-ciscat}
MYSQL_DATABASE=${MYSQL_DATABASE:-ccpd}
MYSQL_SERVER=${MYSQL_SERVER:-mysql}
MYSQL_PORT=${MYSQL_PORT:-3306}
CCPD_TOKEN=${CCPD_TOKEN:-11112222333344445555666677778888} # not used now; TODO: try to init token in DB via this script

SMTP_HOST=${SMTP_HOST:-localhost}
SMTP_PORT=${SMTP_PORT:-25}
SMTP_USER=${SMTP_USER:-}
SMTP_PASS=${SMTP_PASS:-}
DEFAULT_SENDER_EMAIL_ADDRESS=${DEFAULT_SENDER_EMAIL_ADDRESS:-}

test -n "${MYSQL_PASSWORD}" || { echo "== err: MYSQL_PASSWORD env is empty; exiting" ; exit -1 ; }
test -n "${CCPD_URL}" || { echo "== err: CCPD_URL: env is empty; exiting" ; exit -1 ; }

# TZ is inherited from Dockerfile, can be changed in run time
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

touch ${CATALINA_HOME}/conf/server.xml
cp ${CATALINA_HOME}/conf/server.xml ${CATALINA_HOME}/conf/server.xml~
sed -i -e 's#redirectPort="8443".*#redirectPort="8443" maxPostSize="35728640" />#' \
          ${CATALINA_HOME}/conf/server.xml

touch ${CATALINA_HOME}/bin/catalina.sh
cp ${CATALINA_HOME}/bin/catalina.sh ${CATALINA_HOME}/bin/catalina.sh~
sed -i -e "/^#!.*/a export CCPD_CONFIG_FILE=\"${CATALINA_HOME}/ccpd-config.yml\"" \
       -e "/^#!.*/a export CCPD_LOG_DIR=\"${CATALINA_HOME}/logs\"" \
          ${CATALINA_HOME}/bin/catalina.sh

touch ${CATALINA_HOME}/bin/setenv.sh
cp ${CATALINA_HOME}/bin/setenv.sh ${CATALINA_HOME}/bin/setenv.sh~
cat >> ${CATALINA_HOME}/bin/setenv.sh << _EOF
export CATALINA_OPTS="-Xms1024M -Xmx2048M -Dfile.encoding=UTF-8"
_EOF

touch ${CATALINA_HOME}/conf/catalina.properties
cp ${CATALINA_HOME}/conf/catalina.properties ${CATALINA_HOME}/conf/catalina.properties~
sed -i -e '/^tomcat.util.scan.StandardJarScanFilter.jarsToSkip.*/a bcprov*.jar,\\' \
          ${CATALINA_HOME}/conf/catalina.properties

touch ${CATALINA_HOME}/conf/context.xml
cp ${CATALINA_HOME}/conf/context.xml ${CATALINA_HOME}/conf/context.xml~
sed -i -e '/^<Context>.*/a    <Resources cacheMaxSize="51200" />' \
          ${CATALINA_HOME}/conf/context.xml

mkdir -p ${CATALINA_HOME}/legacy/{source,processed,error}

echo "Created 'tomcat' configuration"

cat > ${CATALINA_HOME}/ccpd-config.yml << _EOF
legacy:
    sourceDir: "${CATALINA_HOME}/legacy/source"
    processedDir: "${CATALINA_HOME}/legacy/processed"
    errorDir: "${CATALINA_HOME}/legacy/error"

grails:
    serverURL: "${CCPD_URL}"
    mail:
        host: "${SMTP_HOST}"
        port: "${SMTP_PORT}"
        username: "${SMTP_USER}"
        password: "${SMTP_PASS}"
        props:
            mail.smtp.auth: ""
            mail.smtp.socketFactory.port: ""
            mail.smtp.socketFactory.class: ""
            mail.smtp.socketFactory.fallback: ""
            mail.smtp.starttls.enable: ""

    plugin:
        springsecurity:
            ui:
                forgotPassword:
                    emailFrom: "${DEFAULT_SENDER_EMAIL_ADDRESS}"
    assessorService:
        active: false
        url: ""
        ignoreSslCertErrors: false
server:
    contextPath: "/CCPD"
    servlet:
        context-path: "/CCPD"
dataSource:
    dbCreate: update

    #DB Settings

    driverClassName: org.mariadb.jdbc.Driver
    dialect: org.hibernate.dialect.MySQL5InnoDBDialect
    url: "jdbc:mysql://${MYSQL_SERVER}:${MYSQL_PORT}/${MYSQL_DATABASE}"
    username: "${MYSQL_USER}"
    password: "${MYSQL_PASSWORD}"

    properties:
          jmxEnabled: true
          initialSize: 5
          maxActive: 50
          minIdle: 5
          maxIdle: 25
          maxWait: 10000
          maxAge: 600000
          validationQuery: SELECT 1
          validationQueryTimeout: 3
          validationInterval: 15000
          defaultTransactionIsolation: 2
          dbProperties:
                autoReconnect: true

database: MySQL.5.7
key: ''
_EOF

echo "Created '${CATALINA_HOME}/ccpd-config.yml' file"
echo "Everything is ready, proceed with 'exec'uting the following command: [$@]"

exec "$@"
