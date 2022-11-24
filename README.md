# CIS-CAT Pro Assessor and Dashboard in Docker

## Usage

* Clone the repo
  * `git clone https://github.com/cloud-simple/docker-ciscat.git`
* Change to the repo directory
  * `cd docker-ciscat`
* Create `.env` file defining the following variables (the provided values are used as examples, please chenge them accordingly)
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
