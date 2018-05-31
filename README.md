# Oracle Database 12c Release 2 on Ubuntu Linux 16.04
Scripts for preparing Ubuntu Linux to support Oracle12c installation

Scripts have been tested with Ubuntu Linux 16.04 64-bit and Oracle 12c Release 2 (12.2.0.1)

The Oracle database is installed as user 'oracle' at:

```shell
/home/oracle/database
```
The script defines the following environment variables for the database and its utilities to function correctly:

```shell
ORACLE_BASE=/home/oracle/database
ORACLE_HOME=$ORACLE_BASE/product/$ORAVER/dbhome_1
ORACLE_SID=oracledb
ORACLE_UNQNAME=oracledb
```

## Steps
1. Download the scripts and database
* Oracle12cR2_Ubuntu_16.04_pre-install.sh
* Oracle12cR2_Ubuntu_16.04_fixup.sh
* oracledb
* linux\*122*_database.zip (see :  http://www.oracle.com/technetwork/database/enterprise-edition/downloads/index.html# - (free) login required to accept license)

2. Prepare environment
> user@oracledb-1:~$ sudo ./Oracle12cR2_Ubuntu_16.04_pre-install.sh

Note: Be sure to reboot the Operating system for all the system configurations to take effect

3. Install Oracle database
Add the user 'oracle' to the sudoers group
> user@oracledb-1:~$ sudo usermod -aG sudo username

Switch to 'oracle' user
> user@oracledb-1:~$ sudo su - oracle

Start the Oracle database installer
> oracle@oracledb-1:~$ ./runInstaller

4. Fix installation
The Oracle database installation will throw an error around the linking stage. Run the fixup script and continue the installation.
> oracle@oracledb-1:~$ ./Oracle12cR2_Ubuntu_16.04_fixup.sh

5. Install Autostart script
> oracle@oracledb-1:~$ sudo cp oracledb /etc/init.d/

Note: Ensure that an entry ending in 'Y' exists in the /etc/oratab file
```shell
oracledb:/home/oracle/database/product/12.2.0/dbhome_1:Y
```
