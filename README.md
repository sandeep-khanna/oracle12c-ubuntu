# oracle12c-ubuntu
Scripts for preparing Ubuntu Linux to support Oracle12c installation

Scripts have been tested with Ubuntu Linux 16.04 64-bit and Oracle 12c Release 2 (12.2.0.1)

The Oracle database is installed as user 'oracle' at /home/oracle/database

The script defines the following environment variables for the database and its utilities to function correctly:

ORACLE_BASE=/home/oracle/database
ORACLE_HOME=$ORACLE_BASE/product/$ORAVER/dbhome_1
ORACLE_SID=oracledb
ORACLE_UNQNAME=oracledb
