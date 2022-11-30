#!/usr/bin/env bash
set -e

TZ=${TZ:-UTC}

USER_ID=${USER_ID:-20001}
GROUP_ID=${GROUP_ID:-20001}
USER_NAME=${USER_NAME:-ciscat}
GROUP_NAME=${GROUP_NAME:-ciscat}
PASSWORD=${PASSWORD:-ciscat}

SAMBA_WORKGROUP=${SAMBA_WORKGROUP:-WORKGROUP}
SAMBA_SERVER_STRING=${SAMBA_SERVER_STRING:-CIS-CAT}
SAMBA_LOG_LEVEL=${SAMBA_LOG_LEVEL:-0}
SAMBA_HOSTS_ALLOW=${SAMBA_HOSTS_ALLOW:-127.0.0.0/8 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16}

CISCAT_SMB_SHARE=${CISCAT_SMB_SHARE:-ciscat}

test -n "${CISCAT_SMB_SERVER}" || { echo "== err: CISCAT_SMB_SERVER env is empty; exiting" ; exit -1 ; }
test -n "${CCPD_URL}" || { echo "== err: CCPD_URL env is empty; exiting" ; exit -1 ; }
test -n "${CCPD_TOKEN}" || { echo "== err: CCPD_TOKEN env is empty; exiting" ; exit -1 ; }

echo "Setting timezone to ${TZ}"
ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime
echo ${TZ} > /etc/timezone

getent group  | grep "${GROUP_NAME}:x:${GROUP_ID}"           &>/dev/null || addgroup -g "${GROUP_ID}" -S "${GROUP_NAME}"
getent passwd | grep "${USER_NAME}:x:${USER_ID}:${GROUP_ID}" &>/dev/null || adduser  -u "${USER_ID}"  -G "${GROUP_NAME}" "${USER_NAME}" -SHD
echo -e "${PASSWORD}\n${PASSWORD}" | smbpasswd -a -s "${USER_NAME}"

#test -n "$(getent group  ciscat)" || groupadd -g 20001 ciscat
#test -n "$(getent passwd ciscat)" || useradd  -u 20001 -g 20001 -N -M  -d /nonexistent -s /usr/sbin/nologin ciscat

# We are waiting the following FS structure is present in `/data/downloads` with necessary
#   distributions (`*.zip` files), where one directory contains only one corresponding file.
#   The `/data/downloads` directory has to be prepared on host OS and mounted to the `samba`
#   container as part of its `/data` volume (like: -v "/srv/docker/samba:/data")
# * ./assessor/  # CIS-CAT Assessor,                                 like: ./assessor/CIS-CAT-Assessor-v4.23.0.zip
# * ./license/   # License Key,                                      like: ./license/NewMember-LicenseKey-ClientConfigurationBundle.zip
# * ./jre/       # Java Runtime Env for Windows x86-32 Architecture, like: ./jre/OpenJDK11U-jre_x86-32_windows_hotspot_11.0.17_8.zip
# * ./jre64/     # Java Runtime Env for Windows x64 Architecture,    like: ./jre64/OpenJDK11U-jre_x64_windows_hotspot_11.0.17_8.zip

# We are waiting the following FS structure is present in `/data/downloads` with necessary
#   distributions (`*.zip` files), where one directory contains only one corresponding file.
#   The `/data/downloads` directory has to be prepared on host OS and mounted to the `ccpd`
#   container as part of its `/data` volume (like: -v "/srv/docker/ccpd:/data")
# * ./dashboard/ # CIS-CAT Pro Dashboard,                            like: ./dashboard/'CIS-CAT Pro Dashboard v2.3.2-unix.zip'

if [ ! -d /data/shares/${CISCAT_SMB_SHARE} ] ; then
  mkdir -p /data/shares/${CISCAT_SMB_SHARE}
fi

chown ${USER_NAME}:${GROUP_NAME} /data/shares/${CISCAT_SMB_SHARE}
chmod 770                        /data/shares/${CISCAT_SMB_SHARE}

if [ ! -d /data/shares/${CISCAT_SMB_SHARE}/Assessor ] ; then
  test -e /data/downloads/assessor/*.zip || { echo "== err: folder 'Assessor' is empty and no distributive is provided; exiting" ; exit -1 ; }
  echo "Extract 'Assessor' folder"
  unzip -q -d /data/shares/${CISCAT_SMB_SHARE}/ $(ls -A1 /data/downloads/assessor/*.zip | head -1)
fi

if [ -z "$(ls -A1 /data/shares/${CISCAT_SMB_SHARE}/Assessor/license)" ] ; then
  test -e /data/downloads/license/*.zip || { echo "== err: folder 'Assessor/license' is empty and no license is provided; exiting" ; exit -1 ; }
  echo "Extract 'license' files"
  unzip -q -d /data/shares/${CISCAT_SMB_SHARE}/Assessor/license/ $(ls -A1 /data/downloads/license/*.zip | head -1)
fi

chown -R ${USER_NAME}:${GROUP_NAME} /data/shares/${CISCAT_SMB_SHARE}/Assessor
chmod -R 550                        /data/shares/${CISCAT_SMB_SHARE}/Assessor

if [ ! -e /data/shares/${CISCAT_SMB_SHARE}/cis-cat-centralized-ccpd.bat ] ; then
  echo "Prepare 'cis-cat-centralized-ccpd.bat' file"
  cp /data/shares/${CISCAT_SMB_SHARE}/Assessor/misc/Windows/cis-cat-centralized-ccpd.bat /data/shares/${CISCAT_SMB_SHARE}/

  sed -i -e "s#^SET NetworkShare=.*#SET NetworkShare=\\\\\\\\${CISCAT_SMB_SERVER}\\\\${CISCAT_SMB_SHARE}#" \
         -e "s#^SET CCPDUrl=.*#SET CCPDUrl=${CCPD_URL}#" \
         -e "s#^SET AUTHENTICATION_TOKEN=.*#SET AUTHENTICATION_TOKEN=${CCPD_TOKEN}#" \
         -e "s#^SET DEBUG=.*#SET DEBUG=1#" \
         -e '1 i\DATE /T\nTIME /T\n' \
         /data/shares/${CISCAT_SMB_SHARE}/cis-cat-centralized-ccpd.bat
  echo -e "\nDATE /T\nTIME /T\nPAUSE\n" >> /data/shares/${CISCAT_SMB_SHARE}/cis-cat-centralized-ccpd.bat
fi

chown ${USER_NAME}:${GROUP_NAME} /data/shares/${CISCAT_SMB_SHARE}/cis-cat-centralized-ccpd.bat
chmod 550                        /data/shares/${CISCAT_SMB_SHARE}/cis-cat-centralized-ccpd.bat

if [ ! -e /data/shares/${CISCAT_SMB_SHARE}/cis-cat-centralized.bat ] ; then
  echo "Prepare 'cis-cat-centralized.bat' file"
  cp /data/shares/${CISCAT_SMB_SHARE}/Assessor/misc/Windows/cis-cat-centralized.bat /data/shares/${CISCAT_SMB_SHARE}/

  sed -i -e "s#^SET NetworkShare=.*#SET NetworkShare=\\\\\\\\${CISCAT_SMB_SERVER}\\\\${CISCAT_SMB_SHARE}#" \
         -e "s#^SET DEBUG=.*#SET DEBUG=1#" \
         -e '1 i\DATE /T\nTIME /T\n' \
         /data/shares/${CISCAT_SMB_SHARE}/cis-cat-centralized.bat
  echo -e "\nDATE /T\nTIME /T\nPAUSE\n" >> /data/shares/${CISCAT_SMB_SHARE}/cis-cat-centralized.bat
fi

chown ${USER_NAME}:${GROUP_NAME} /data/shares/${CISCAT_SMB_SHARE}/cis-cat-centralized.bat
chmod 550                        /data/shares/${CISCAT_SMB_SHARE}/cis-cat-centralized.bat

echo "Update 'Assessor/config/sessions.properties' file"
cat > /data/shares/${CISCAT_SMB_SHARE}/Assessor/config/sessions.properties << _EOF
session.default.type=local
session.default.tmp=C:\\\\Windows\\\\Temp
_EOF

if [ ! -d /data/shares/${CISCAT_SMB_SHARE}/Java ] ; then
  test -e /data/downloads/jre/*.zip || { echo "== err: folder 'Java' is empty and no distributive is provided; exiting" ; exit -1 ; }
  echo "Extract 'Java' folder"
  mkdir -p /data/shares/${CISCAT_SMB_SHARE}/Java
  unzip -q -d /data/shares/${CISCAT_SMB_SHARE}/Java/ $(ls -A1 /data/downloads/jre/*.zip | head -1)
  mv $(ls -A1d /data/shares/${CISCAT_SMB_SHARE}/Java/* | head -1) /data/shares/${CISCAT_SMB_SHARE}/Java/jre
fi

chown -R ${USER_NAME}:${GROUP_NAME} /data/shares/${CISCAT_SMB_SHARE}/Java
chmod -R 550                        /data/shares/${CISCAT_SMB_SHARE}/Java

if [ ! -d /data/shares/${CISCAT_SMB_SHARE}/Java64 ] ; then
  test -e /data/downloads/jre64/*.zip || { echo "== err: folder 'Java64' is empty and no distributive is provided; exiting" ; exit -1 ; }
  echo "Extract 'Java64' folder"
  mkdir -p /data/shares/${CISCAT_SMB_SHARE}/Java64
  unzip -q -d /data/shares/${CISCAT_SMB_SHARE}/Java64/ $(ls -A1 /data/downloads/jre64/*.zip | head -1)
  mv $(ls -A1d /data/shares/${CISCAT_SMB_SHARE}/Java64/* | head -1) /data/shares/${CISCAT_SMB_SHARE}/Java64/jre
fi

chown -R ${USER_NAME}:${GROUP_NAME} /data/shares/${CISCAT_SMB_SHARE}/Java64
chmod -R 550                        /data/shares/${CISCAT_SMB_SHARE}/Java64

if [ ! -d /data/shares/${CISCAT_SMB_SHARE}/Reports ] ; then
  echo "Create 'Reports' folder"
  mkdir -p /data/shares/${CISCAT_SMB_SHARE}/Reports
fi

chown ${USER_NAME}:${GROUP_NAME} /data/shares/${CISCAT_SMB_SHARE}/Reports
chmod 770                        /data/shares/${CISCAT_SMB_SHARE}/Reports

echo "Prepare '/etc/samba/smb.conf' file"

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

[${CISCAT_SMB_SHARE}]
  path = /data/shares/${CISCAT_SMB_SHARE}
  read only = no
  writable = yes
  valid users = ${USER_NAME}
  write list = ${GROUP_NAME}
_EOF

# directory for samba log files
mkdir -p /usr/local/samba/var/

exec "$@"
