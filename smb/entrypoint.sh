#!/usr/bin/env bash
set -e

USER_ID=${USER_ID:-20001}
GROUP_ID=${GROUP_ID:-20001}
USER_NAME=${USER_NAME:-ciscat}
GROUP_NAME=${GROUP_NAME:-ciscat}
PASSWORD=${PASSWORD:-ciscat}

SAMBA_WORKGROUP=${SAMBA_WORKGROUP:-WORKGROUP}
SAMBA_SERVER_STRING=${SAMBA_SERVER_STRING:-CIS-CAT}
SAMBA_LOG_LEVEL=${SAMBA_LOG_LEVEL:-0}
SAMBA_HOSTS_ALLOW=${SAMBA_HOSTS_ALLOW:-127.0.0.0/8 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16}

SAMBA_SHARE_NAME=${SAMBA_SHARE_NAME:-ciscat}

test -n "${SAMBA_SERVER_NAME}" || { echo "== err: SAMBA_SERVER_NAME env is empty; exiting" ; exit -1 ; }
test -n "${CCPD_URL}" || { echo "== err: CCPD_URL env is empty; exiting" ; exit -1 ; }
test -n "${CCPD_TOKEN}" || { echo "== err: CCPD_TOKEN env is empty; exiting" ; exit -1 ; }

# TZ is inherited from Dockerfile, can be changed in run time
ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime
echo ${TZ} > /etc/timezone
echo "Set timezone to ${TZ}"

# possible option to add user/group is with groupadd/useradd
#test -n "$(getent group  ciscat)" || groupadd -g 20001 ciscat
#test -n "$(getent passwd ciscat)" || useradd  -u 20001 -g 20001 -N -M  -d /nonexistent -s /usr/sbin/nologin ciscat

getent group  | grep "${GROUP_NAME}:x:${GROUP_ID}"           &>/dev/null || addgroup -g "${GROUP_ID}" -S "${GROUP_NAME}"
getent passwd | grep "${USER_NAME}:x:${USER_ID}:${GROUP_ID}" &>/dev/null || adduser  -u "${USER_ID}"  -G "${GROUP_NAME}" "${USER_NAME}" -SHD
echo -e "${PASSWORD}\n${PASSWORD}" | smbpasswd -a -s "${USER_NAME}"

if [ ! -d /data/shares/${SAMBA_SHARE_NAME} ] ; then
  mkdir -p /data/shares/${SAMBA_SHARE_NAME}
fi

chown ${USER_NAME}:${GROUP_NAME} /data/shares/${SAMBA_SHARE_NAME}
chmod 770                        /data/shares/${SAMBA_SHARE_NAME}

if [ ! -d /data/shares/${SAMBA_SHARE_NAME}/Assessor ] ; then
  test -e /data/downloads/assessor/*.zip || { echo "== err: folder 'Assessor' is empty and no distributive is provided; exiting" ; exit -1 ; }
  unzip -q -d /data/shares/${SAMBA_SHARE_NAME}/ "$(ls -A1 /data/downloads/assessor/*.zip | head -1)"
  echo "Extracted 'Assessor' folder to '/data/shares/${SAMBA_SHARE_NAME}/'"
fi

if [ -z "$(ls -A1 /data/shares/${SAMBA_SHARE_NAME}/Assessor/license)" ] ; then
  test -e /data/downloads/license/*.zip || { echo "== err: folder 'Assessor/license' is empty and no license is provided; exiting" ; exit -1 ; }
  unzip -q -d /data/shares/${SAMBA_SHARE_NAME}/Assessor/license/ "$(ls -A1 /data/downloads/license/*.zip | head -1)"
  echo "Extracted 'Assessor/license' files to '/data/shares/${SAMBA_SHARE_NAME}/Assessor/license/'"
fi

chown -R ${USER_NAME}:${GROUP_NAME} /data/shares/${SAMBA_SHARE_NAME}/Assessor
chmod -R 550                        /data/shares/${SAMBA_SHARE_NAME}/Assessor

if [ ! -e /data/shares/${SAMBA_SHARE_NAME}/cis-cat-centralized-ccpd.bat ] ; then
  cp /data/shares/${SAMBA_SHARE_NAME}/Assessor/misc/Windows/cis-cat-centralized-ccpd.bat /data/shares/${SAMBA_SHARE_NAME}/

  sed -i -e '1 i\DATE /T\nTIME /T\n' \
         -e '/^@ECHO OFF/d' \
         -e "s#^SET DEBUG=.*#SET DEBUG=1#" \
         -e "s#^SET NetworkShare=.*#SET NetworkShare=\\\\\\\\${SAMBA_SERVER_NAME}\\\\${SAMBA_SHARE_NAME}#" \
         -e "s#^SET CCPDUrl=.*#SET CCPDUrl=${CCPD_URL}/api/reports/upload#" \
         -e "s#^SET AUTHENTICATION_TOKEN=.*#SET AUTHENTICATION_TOKEN=${CCPD_TOKEN}#" \
         -e '$ a\DATE /T\nTIME /T\nnet use /delete s:\nPAUSE\n' \
            /data/shares/${SAMBA_SHARE_NAME}/cis-cat-centralized-ccpd.bat
  echo "Created '/data/shares/${SAMBA_SHARE_NAME}/cis-cat-centralized-ccpd.bat' file"
fi

chown ${USER_NAME}:${GROUP_NAME} /data/shares/${SAMBA_SHARE_NAME}/cis-cat-centralized-ccpd.bat
chmod 550                        /data/shares/${SAMBA_SHARE_NAME}/cis-cat-centralized-ccpd.bat

if [ ! -e /data/shares/${SAMBA_SHARE_NAME}/cis-cat-centralized.bat ] ; then
  cp /data/shares/${SAMBA_SHARE_NAME}/Assessor/misc/Windows/cis-cat-centralized.bat /data/shares/${SAMBA_SHARE_NAME}/

  sed -i -e '1 i\DATE /T\nTIME /T\n' \
         -e '/^@ECHO OFF/d' \
         -e "s#^SET DEBUG=.*#SET DEBUG=1#" \
         -e "s#^SET NetworkShare=.*#SET NetworkShare=\\\\\\\\${SAMBA_SERVER_NAME}\\\\${SAMBA_SHARE_NAME}#" \
         -e '$ a\DATE /T\nTIME /T\nnet use /delete s:\nPAUSE\n' \
            /data/shares/${SAMBA_SHARE_NAME}/cis-cat-centralized.bat
  echo "Created '/data/shares/${SAMBA_SHARE_NAME}/cis-cat-centralized.bat' file"
fi

chown ${USER_NAME}:${GROUP_NAME} /data/shares/${SAMBA_SHARE_NAME}/cis-cat-centralized.bat
chmod 550                        /data/shares/${SAMBA_SHARE_NAME}/cis-cat-centralized.bat

cat > /data/shares/${SAMBA_SHARE_NAME}/Assessor/config/sessions.properties << _EOF
session.default.type=local
session.default.tmp=C:\\\\Windows\\\\Temp
_EOF
echo "Updated '/data/shares/${SAMBA_SHARE_NAME}/Assessor/config/sessions.properties' file"

if [ ! -d /data/shares/${SAMBA_SHARE_NAME}/Java ] ; then
  test -e /data/downloads/jre/*.zip || { echo "== err: folder 'Java' is empty and no distributive is provided; exiting" ; exit -1 ; }
  mkdir -p /data/shares/${SAMBA_SHARE_NAME}/Java
  unzip -q -d /data/shares/${SAMBA_SHARE_NAME}/Java/ "$(ls -A1 /data/downloads/jre/*.zip | head -1)"
  mv "$(ls -A1d /data/shares/${SAMBA_SHARE_NAME}/Java/* | head -1)" /data/shares/${SAMBA_SHARE_NAME}/Java/jre
  echo "Extracted 'Java' to '/data/shares/${SAMBA_SHARE_NAME}/Java/jre' folder"
fi

chown -R ${USER_NAME}:${GROUP_NAME} /data/shares/${SAMBA_SHARE_NAME}/Java
chmod -R 550                        /data/shares/${SAMBA_SHARE_NAME}/Java

if [ ! -d /data/shares/${SAMBA_SHARE_NAME}/Java64 ] ; then
  test -e /data/downloads/jre64/*.zip || { echo "== err: folder 'Java64' is empty and no distributive is provided; exiting" ; exit -1 ; }
  mkdir -p /data/shares/${SAMBA_SHARE_NAME}/Java64
  unzip -q -d /data/shares/${SAMBA_SHARE_NAME}/Java64/ "$(ls -A1 /data/downloads/jre64/*.zip | head -1)"
  mv "$(ls -A1d /data/shares/${SAMBA_SHARE_NAME}/Java64/* | head -1)" /data/shares/${SAMBA_SHARE_NAME}/Java64/jre
  echo "Extracted 'Java64' to '/data/shares/${SAMBA_SHARE_NAME}/Java64/jre' folder"
fi

chown -R ${USER_NAME}:${GROUP_NAME} /data/shares/${SAMBA_SHARE_NAME}/Java64
chmod -R 550                        /data/shares/${SAMBA_SHARE_NAME}/Java64

if [ ! -d /data/shares/${SAMBA_SHARE_NAME}/Reports ] ; then
  mkdir -p /data/shares/${SAMBA_SHARE_NAME}/Reports
  echo "Created '/data/shares/${SAMBA_SHARE_NAME}/Reports' folder"
fi

chown ${USER_NAME}:${GROUP_NAME} /data/shares/${SAMBA_SHARE_NAME}/Reports
chmod 770                        /data/shares/${SAMBA_SHARE_NAME}/Reports

test ! -f /etc/samba/smb.conf || mv /etc/samba/smb.conf /etc/samba/smb.conf.orig
cat > /etc/samba/smb.conf << _EOF
[global]
  workgroup = ${SAMBA_WORKGROUP}
  server string = ${SAMBA_SERVER_STRING}
  server role = standalone server
  # server services = -dns, -nbt
  # server signing = default
  # server multi channel support = yes

  log file = /usr/local/samba/var/log.%m
  log level = ${SAMBA_LOG_LEVEL}
  max log size = 500

  # hosts allow = ${SAMBA_HOSTS_ALLOW}
  # hosts deny = 0.0.0.0/0

  # smb ports = 445
  dns proxy = no

[${SAMBA_SHARE_NAME}]
  path = /data/shares/${SAMBA_SHARE_NAME}
  read only = no
  writable = yes
  valid users = ${USER_NAME}
  write list = ${GROUP_NAME}
_EOF

echo "Created '/etc/samba/smb.conf' file"

# directory for samba log files
mkdir -p /usr/local/samba/var/

echo "Everything is ready, will proceed with 'exec'uting the following command: [$@]"

exec "$@"
