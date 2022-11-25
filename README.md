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
