# CIS-CAT Pro Assessor and Dashboard in Docker

> **Note**
>
> Here we will use `Assessor App` for **CIS-CAT Pro Assessor** Application and `CCPD App` for **CIS-CAT Pro Dashboard**  Application

## Installation

### Samba server and shared folder to serve Assessor App content

* Clone the repo
  * `git clone https://github.com/cloud-simple/docker-ciscat.git`
* Change to the `smb` directory within the cloned repo directory
  * `cd docker-ciscat/smb`
* Create `.env` file defining the following variables (the provided values are used as examples, please change them accordingly)

```
SAMBA_SHARE_NAME=CIS
SAMBA_SERVER_NAME=samba.example.org
CCPD_URL=http://ciscat.example.org/CCPD
CCPD_TOKEN=11112222333344445555666677778888
```

* The meanings of the above variables are the following
  * `SAMBA_SERVER_NAME` - the name of the SMB server serving Assessor App in **Centralized Workflow** mode
  * `SAMBA_SHARE_NAME` - the name of the SMB share on the above SMB server for Assessor App content
  * `CCPD_URL` - the URL for the CCPD App API to which Assessor App reports are POST'ed
  * `CCPD_TOKEN` - the **Authentication Token** generated for an `API` user in CCPD App
    * Currently this token have to be created via CCPD App Web Interface and used here
* Create the directory `/srv/docker/smb/downloads` with the following directory structure within it and add there the corresponding content
  * `./assessor/` place here the distribution `zip` file with Assessor App, like: `./assessor/CIS-CAT-Assessor-v4.23.0.zip`
  * `./license/` place here `zip` file with License Key, like: `./license/NewMember-LicenseKey-ClientConfigurationBundle.zip`
  * `./jre/` place here the distribution `zip` file with Java Runtime Env bundle for Windows x86-32 Architecture, like: `./jre/OpenJDK11U-jre_x86-32_windows_hotspot_11.0.17_8.zip`
  * `./jre64/` place here the distribution `zip` file with Java Runtime Env bundle for Windows x64 Architecture, like: `./jre64/OpenJDK11U-jre_x64_windows_hotspot_11.0.17_8.zip`
* The following is an exemplary content of possible directory structure - more details on how the container processes the directory structure are available in the section **Deployment details - smb** below

```
$ tree /srv/docker/smb/downloads
/srv/docker/smb/downloads
├── assessor
│   └── CIS-CAT-Assessor-v4.23.0.zip
├── jre
│   └── OpenJDK11U-jre_x86-32_windows_hotspot_11.0.17_8.zip
├── jre64
│   └── OpenJDK11U-jre_x64_windows_hotspot_11.0.17_8.zip
└── license
    └── NewMember-LicenseKey-ClientConfigurationBundle.zip
```

* Run the following command
  * `docker compose up -d`
* See the applications log with the following command
  * `docker compose logs`

### CCPD App and DB

* Clone the repo - this is the same repo which is used for **Samba server and shared folder to serve Assessor App content** above
  * `git clone https://github.com/cloud-simple/docker-ciscat.git`
* Change to the `ccpd` directory within the cloned repo directory
  * `cd docker-ciscat/ccpd`
* Create `.env` file defining the following variables (the provided values are used as examples, please change them accordingly)

```
MYSQL_USER=my-ccpd-user
MYSQL_PASSWORD=my-ccpd-pass
MYSQL_DATABASE=ccpd
MYSQL_ROOT_PASSWORD=my-root-pass
CCPD_URL=http://ciscat.example.org/CCPD
CCPD_TOKEN=11112222333344445555666677778888
SMTP_HOST=smtp.example.org
SMTP_PORT=25
SMTP_USER=smtp-ccpd-user
SMTP_PASS=smtp-ccpd-pass
DEFAULT_SENDER_EMAIL_ADDRESS=noreply@smtp.example.org
```

* The meanings of the above variables are the following
  * `MYSQL_USER` - CCPD DB container MySQL user name, also used by CCPD App container to connect to the mentioned DB
  * `MYSQL_PASSWORD` - CCPD DB container MySQL password, also used by CCPD App container to connect to the mentioned DB
  * `MYSQL_DATABASE` - CCPD DB container MySQL DB name, also used by CCPD App container to connect to the mentioned DB
  * `MYSQL_ROOT_PASSWORD` - CCPD DB container MySQL server root user password
  * `CCPD_URL` - Server URL the CCPD App to be configured to listen to
  * `CCPD_TOKEN` - :exclamation: this is not used for CCPD App container deployment now :exclamation:
     * Assessor App uses this CCPD TOKEN to authenticate to CCPD App when it posts assessment reports to CCPD App
     * Currently this token is created via CCPD App Web Interface and passed to `smb` container for Assessor App during deployment as a variable
       - [ ] TODO: try to initialize CCPD TOKEN in CCPD DB via `entrypoint.sh` script
  * `SMTP_HOST` - SMTP HOST parameter of CCPD App 
  * `SMTP_PORT` - SMTP PORT parameter of CCPD App
  * `SMTP_USER` - SMTP USER parameter of CCPD App
  * `SMTP_PASS` - SMTP PASS parameter of CCPD App
  * `DEFAULT_SENDER_EMAIL_ADDRESS` - default address for `forgot password` email messages
* Create the directory `/srv/docker/ccpd/downloads` with the following directory structure within it and add there corresponding content
  * `./dashboard/` place here the distribution `zip` file with CCPD App, like: `./dashboard/CIS-CAT-Pro-Dashboard-v2.3.2-unix.zip`
* The following is an exemplary content of possible directory structure - more details on how the container processes the directory structure are available in the section **Deployment details - ccpd** below

```
$ tree /srv/docker/ccpd/downloads
/srv/docker/ccpd/downloads
└── dashboard
    └── CIS-CAT-Pro-Dashboard-v2.3.2-unix.zip
```

* Create the directory `/srv/docker/my4ccpd` which will be used as a persistent storage for CCPD App data managed by MySQL DB container - this will be bound to MySQL container's `MySQL Data Directory` directory - more details on `my4ccpd` container are available in the section **Deployment details - my4ccpd** below
* Run the following command
  * `docker compose up -d`
* See the applications log with the following command
  * `docker compose logs`
* Now you should be able to access CCPD App Web Interface via the provided `CCPD_URL`

## Deployment details

### `smb`

* The container runs `samba (smbd)` service which serves Assessor App content in **Centralized Workflow** mode
* According to `docker-compose.yaml` file the container is starting with the host path `/srv/docker/smb` mounted as the container volume with path `/data`
* To serve Assessor App the container ENTRYPOINT script (`entrypoint.sh`) creates (and fills with approprate content) the directory structure for SMB share folder (available within container file system at `/data/shares/${SAMBA_SHARE_NAME}` path) and make all necessary changes for `smbd` configuration
* All the required content of Assessor App shared folder direcory structure (below the `/data/shares/${SAMBA_SHARE_NAME}` directory) is based on the structure and content of **downloads** directory (available within container file system at `/data/downloads` path, and provided via the mentioned above container volume) and formed in the following way
  * If a component of Assessor App shared folder direcory structure exists (available via the mentioned above container volume on `/data/shares/${SAMBA_SHARE_NAME}` path) the component content is not recreated and is left as is
  * If a component of Assessor App shared folder direcory structure doesn't exist, the component content is created from the corresponding `.zip` file provided via the mentioned above container volume on `/data/downloads` path
  * The ENTRYPOINT script expects the following direcory structure present within container file system at `/data/downloads` path with the corresponding distribution `.zip` files, where one directory contains only one `.zip` file
    * `./assessor/*.zip` -  distribution for Assessor App
    * `./license/*.zip` -  distribution for License Key 
    * `./jre/*.zip` -  distribution for Java Runtime Env for Windows x86-32 Architecture
    * `./jre64/*.zip` -  distribution for Java Runtime Env for Windows x64 Architecture
* The corresponding directory `/srv/docker/smb/downloads` has to be prepared on host OS and mounted to the `smb` container as part of its `/data` volume
  * It can be done the way provided in `docker-compose.yaml` file or using corresponding `docker` command  with `-v` flag, like: `-v "/srv/docker/smb:/data"`

### `ccpd`

* The container is `tomcat` service which runs Java application with CCPD App
* According to `docker-compose.yaml` file the container is started with the host path `/srv/docker/ccpd` mounted as the container volume with path `/data`
* To run Java application with help of `tomcat` the container ENTRYPOINT script (`entrypoint.sh`) does the following
  * Copies the application `.war` file into corresponding location according to `tomcat` configuration (`${CATALINA_HOME}/webapps/`)
  * Make all necessary changes to `tomcat` configuration files
* The application `.war` file is extracted from CCPD App `.zip` distribution file provided to the container from the **downloads** directory available within container file system at `/data/downloads` path (provided there via the mentioned above container volume)
* If the application `.war` file exists in the corresponding location (`${CATALINA_HOME}/webapps/CCPD.war`) it is not recreated and is left as is
* If the application `.war` file doesn't exist, it is created from the provided `.zip` file
* The ENTRYPOINT script expects the distribution file for CCPD App present as `/data/downloads/dashboard/*.zip` 
* The corresponding directory `/srv/docker/ccpd/downloads` has to be prepared on host OS and mounted to the `ccpd` container as part of its `/data` volume
  * It can be done the way provided in `docker-compose.yaml` file or using corresponding `docker` command  with `-v` flag, like: `-v "/srv/docker/ccpd:/data"

### `my4ccpd`

* The container is `mysql` DB service which stores data for CCPD App
* According to `docker-compose.yaml` file the container is started with the host path `/srv/docker/my4ccpd` mounted as the container volume with path `/var/lib/mysql`
  * This volume is used as `MySQL Data Directory` where information managed by the MySQL server is stored
  * If `mysql` container instance starts with empty `Data Directory` all the necessary data in the `Data Directory` will be created and initialized 
  * If `mysql` container instance starts with a data directory that already contains a database, the pre-existing database will not be changed in any way
  * Binding a directory on the host into a container in the described way provides the persistent storage for the application data managed by MySQL
* The corresponding directory `/srv/docker/my4ccpd` has to be prepared on host OS and mounted to the `my4ccpd` container as `/var/lib/mysql` volume
  * It can be done the way provided in `docker-compose.yaml` file or using corresponding `docker` command  with `-v` flag, like: `-v "/srv/docker/my4ccpd:/var/lib/mysql"`

## End User Usage

To run Assessor App tool on Windows OS, an user should create batch file and run it as Administrator. In the following steps a file with name `ciscat.bat` is created as an example on Windows Desktop of Windows 10 Pro OS

* Right Click on Windows Desktop -> Click `New` -> Click `Text Document`
* Provide `ciscat.bat` as the name for the file -> Press `Enter` -> Click `Yes` in the `Rename` confirmation window
* Right Click on the created file -> Click `Edit`
* Copy the following commands and Paste them to the file as the content

```
net use /delete s:
net use s: \\ciscat.example.org\CIS /user:ciscat ciscat
\\ciscat.example.org\CIS\cis-cat-centralized-ccpd.bat
net use /delete s:
```
