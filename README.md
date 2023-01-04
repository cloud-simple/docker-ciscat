# CIS-CAT Pro Assessor and Dashboard in Docker

## Usage (tl;dr)

To run CIS-CAT Pro Assessor tool on Windows OS, an user should create batch file and run it as Administrator. In the following steps a file with name `ciscat.bat` is created as an example on Windows Desktop of Windows 10 Pro OS

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

* Click `File` -> Click `Save`
* Click `File` -> Click `Exit`
* Right Click on the created file `ciscat.bat` on Windows Desktop -> Click `Run as administrrator`

## Deployment

### smb - Samba shared folder to serve CIS-CAT content

* Clone the repo
  * `git clone https://github.com/cloud-simple/docker-ciscat.git`
* Change to the `smb` directory within the cloned repo directory
  * `cd docker-ciscat/smb`
* Create `.env` file defining the following variables (the provided values are used as examples, please change them accordingly)

```
SAMBA_SHARE_NAME=CIS
SAMBA_SERVER_NAME=ciscat.example.org
CCPD_URL=http://ciscat.example.org/CCPD
CCPD_TOKEN=11112222333344445555666677778888
```

* The meanings of the above variables are the following
  * `SAMBA_SERVER_NAME` - the name of the SMB server serving CIS-CAT in Centralized Workflow mode
  * `SAMBA_SHARE_NAME` - the name of the SMB share on the above SMB server for CIS-CAT content
  * `CCPD_URL` - the URL for the CIS-CAT Pro Dashboard API to which CIS-CAT reports are POST'ed
  * `CCPD_TOKEN` - the **Authentication Token** generated for an `API` user in CIS-CAT Pro Dashboard
* Create the directory `/srv/docker/samba/downloads` with the following directory structure within it
  * `./assessor/` and place here the distribution `zip` file with CIS-CAT Assessor, like: `./assessor/CIS-CAT-Assessor-v4.23.0.zip`
  * `./license/` and place here the distribution `zip` file with License Key, like: `./license/NewMember-LicenseKey-ClientConfigurationBundle.zip`
  * `./jre/` and place here the distribution `zip` file with Java Runtime Env bundle for Windows x86-32 Architecture, like: `./jre/OpenJDK11U-jre_x86-32_windows_hotspot_11.0.17_8.zip`
  * `./jre64/` and place here the distribution `zip` file with Java Runtime Env bundle for Windows x64 Architecture, like: `./jre64/OpenJDK11U-jre_x64_windows_hotspot_11.0.17_8.zip`
* The following is an exemplary content of possible directory structure (more details on how the container processes the directory structure are available in the section **Deployment details - smb** below)

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

## Deployment details

### `smb`

* The container runs `smbd` service which serves CIS-CAT content in **Centralized Workflow** mode
* According to `docker-compose.yaml` file the container is starting with the host path `/srv/docker/smb` mounted as the container volume with path `/data`
* To serve CIS-CAT the container ENTRYPOINT script (`entrypoint.sh`) creates (and fills with approprate content) the directory structure for SMB share folder available within container file system at `/data/shares/${SAMBA_SHARE_NAME}` path
* All the required content of CIS-CAT shared folder direcory structure (below the `/data/shares/${SAMBA_SHARE_NAME}` directory) is based on the **downloads** directory structure (available within container file system at `/data/downloads` path, and provided via the mentioned above container volume) and formed in the following way
  * If a component of CIS-CAT shared folder direcory structure exists (available via the mentioned above container volume) the component content is not recreated and is left as is
  * If a component of CIS-CAT shared folder direcory structure doesn't exist, the component content is created from the corresponding `.zip` file provided via the mentioned above container volume
  * The ENTRYPOINT script expects the following direcory structure present within container file system at `/data/downloads` path with the corresponding distribution `.zip` files, where one directory contains only one `.zip` file
    * `./assessor/`  # CIS-CAT Assessor                                  like: `./assessor/CIS-CAT-Assessor-v4.23.0.zip`
    * `./license/`   # License Key                                       like: `./license/NewMember-LicenseKey-ClientConfigurationBundle.zip`
    * `./jre/`       # Java Runtime Env for Windows x86-32 Architecture  like: `./jre/OpenJDK11U-jre_x86-32_windows_hotspot_11.0.17_8.zip`
    * `./jre64/`     # Java Runtime Env for Windows x64 Architecture     like: `./jre64/OpenJDK11U-jre_x64_windows_hotspot_11.0.17_8.zip`

### mysql

* Clone the repo
  * `git clone https://github.com/cloud-simple/docker-ciscat.git`
* Change to the cloned repo directory
  * `cd docker-ciscat`
* Create `.env` file defining the following variables (the provided values are used as examples, please change them accordingly)
```
MYSQL_USER=ciscat
MYSQL_PASSWORD=ciscat-password
MYSQL_DATABASE=ccdp
MYSQL_ROOT_PASSWORD=root-password
```
* Run the following command
  * `docker compose up -d`
* See the applications log with the following command
  * `docker compose logs`

### ccpd

We are waiting the following FS structure is present in `/data/downloads` with necessary distributions (`*.zip` files), where one directory contains only one corresponding file.

* `./dashboard/` # CIS-CAT Pro Dashboard                             like: `./dashboard/'CIS-CAT Pro Dashboard v2.3.2-unix.zip'`

The corresponding directory, like e.g.: `/srv/docker/samba/downloads`, has to be prepared on host OS and mounted to the `ccpd` container as part of its `/data` volume (like: -v "/srv/docker/ccpd:/data")
