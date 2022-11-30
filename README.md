# CIS-CAT Pro Assessor and Dashboard in Docker

## tl;dr

## Usage

To run CIS-CAT Pro Assessor tool on Windows user should create batch file and run it as Administrator.
In the following steps a file with name `ciscat.bat` is created as an example on Windows Desktop of Windows 10 Pro OS.

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

### samba

We are waiting the following FS structure is present in `/data/downloads` with necessary distributions (`*.zip` files), where one directory contains only one corresponding file.

* `./assessor/`  # CIS-CAT Assessor                                  like: `./assessor/CIS-CAT-Assessor-v4.23.0.zip`
* `./license/`   # License Key                                       like: `./license/NewMember-LicenseKey-ClientConfigurationBundle.zip`
* `./jre/`       # Java Runtime Env for Windows x86-32 Architecture  like: `./jre/OpenJDK11U-jre_x86-32_windows_hotspot_11.0.17_8.zip`
* `./jre64/`     # Java Runtime Env for Windows x64 Architecture     like: `./jre64/OpenJDK11U-jre_x64_windows_hotspot_11.0.17_8.zip`

The corresponding directory, like e.g.: `/srv/docker/samba/downloads`, has to be prepared on host OS and mounted to the `samba` container as part of its `/data` volume (like: -v "/srv/docker/samba:/data")

### ccpd

We are waiting the following FS structure is present in `/data/downloads` with necessary distributions (`*.zip` files), where one directory contains only one corresponding file.

* `./dashboard/` # CIS-CAT Pro Dashboard                             like: `./dashboard/'CIS-CAT Pro Dashboard v2.3.2-unix.zip'`

The corresponding directory, like e.g.: `/srv/docker/samba/downloads`, has to be prepared on host OS and mounted to the `ccpd` container as part of its `/data` volume (like: -v "/srv/docker/ccpd:/data")
