#! /bin/bash

# Script for performing preparing the environment to install 
# Oracle Database 12c Release 2 (12.2.0.1.0) 
# on Ubuntu Linux 16.04 64-bit
#
# Script is to be run with 'root' privileges  

# -----------------------------------------------------------------------------------------------------------------------------
#  A small function to indicate the passage of time
# -----------------------------------------------------------------------------------------------------------------------------

spinner() {
	pid=$!    # Process Id of the previous running command
	
	spin[0]="-";spin[1]="\\";spin[2]="|";spin[3]="/"
	
	tput cup 28 82;tput setaf 4;echo -n "[Working...] ${spin[0]}"
	
	while kill -0 $pid 2>/dev/null; do
	  
	  for i in "${spin[@]}"; do
		tput cup 28 96;tput setaf 4;echo -ne "\b$i"
		sleep 0.1
	  done
	done
}

# -----------------------------------------------------------------------------------------------------------------------------
#  Let's initialise  the default values for some of the variables we'll be using later on
# -----------------------------------------------------------------------------------------------------------------------------
$ORACLEUSER=oracle
ORAVER=12.2.0
ORAPATH=/home/oracle/database/product/$ORAVER

# -----------------------------------------------------------------------------------------------------------------------------
#  The IP address of the machine needs to be recorded in the /etc/hosts file. So we will first get the IP address of the machine. 
#  Then we'll check if that address is listed in /etc/hosts ...and if it isn't, we'll add it to it. Note the original hosts
#  file is copied to a uniquely-named file first, so the edit is manually reversible if needed.
# -----------------------------------------------------------------------------------------------------------------------------

IPADD=$(ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}')
if [ -z "$IPADD" ]; then
  IPADD=$(ip addr | grep 'inet' | grep -v '127.' | grep -v inet6 | awk '{print $2}' | cut -d/ -f1)
fi
IPCHECK=$(awk '/$IPADD/{print $1}' /etc/hosts)

if [ "$IPCHECK" ] ; then
  tput cup 1 1 #file already contains the 'correct' IP address
else
  curDate=`date '+%m-%d-%y-%s'`
  cp /etc/hosts /etc/hosts.$curDate
  echo "$IPADD `hostname`"|cat - /etc/hosts > /tmp/out && mv -f /tmp/out /etc/hosts
  echo "# Next line added for fresh Oracle Installation" | cat - /etc/hosts > /tmp/out && mv -f /tmp/out /etc/hosts
  sed -i 's/127.0.1.1/#127.0.1.1/' /etc/hosts
fi

# -----------------------------------------------------------------------------------------------------------------------------
#  A user has to own the Oracle installation. By default, we'll assume the user 'oracle' will be the currently-logged in user; 
# -----------------------------------------------------------------------------------------------------------------------------

clear
USREXISTS=$(grep $ORACLEUSER /etc/passwd | wc -l)

# -----------------------------------------------------------------------------------------------------------------------------
#  For any Oracle DB installation, some groups need to exist. Usually these are 'dba' and 'oinstall', plus 'nobody'.
#  We need to check if they already exist, and if they don't, we need to create them.
# -----------------------------------------------------------------------------------------------------------------------------

DBAEXISTS=$(grep "^dba" /etc/group | wc -l)
OINEXISTS=$(grep "^oinstall" /etc/group | wc -l)
NOBEXISTS=$(grep "^nobody" /etc/group | wc -l)

# -----------------------------------------------------------------------------------------------------------------------------
#  We have to prompt for a password for the Oracle User, too, if it's a new user
# -----------------------------------------------------------------------------------------------------------------------------

if [ "$USREXISTS" -eq 0 ]; then
  clear
  tput cup 23 82;tput setaf 4;echo "You've chosen to create a new user to own"
  tput cup 24 82;tput setaf 4;echo "the Oracle software installation."
  tput cup 25 82;tput setaf 4;echo "That account needs a new password, too."
  tput cup 26 82;tput setaf 4;echo "Press Enter to accept the default, or type"
  tput cup 27 82;tput setaf 4;echo "your own choice of password now."
  tput cup 29 82;tput setaf 4;echo "Type the new user's password"
  tput cup 30 82;read -p "[default=oracle]: " ORAPASSWD
  if [ "$ORAPASSWD" == "" ]; then
    ORAPASSWD=oracle
  fi
fi  

# -----------------------------------------------------------------------------------------------------------------------------
#  We now need to prompt for a name for the default database that will eventually get created. It can be up to nine
#  characters long, not null, and cannot start with a number. Other than that, we can accept pretty much any name
#  that is typed in.
# -----------------------------------------------------------------------------------------------------------------------------

clear
tput cup 23 82;tput setaf 4;echo "When you install Oracle, you'll be"
tput cup 24 82;tput setaf 4;echo "prompted to create a starter database."
tput cup 26 82;tput setaf 4;echo "That will need a name."
tput cup 28 82;tput setaf 4;echo "By default, we'll call it 'oracledb',"
tput cup 29 82;tput setaf 4;echo "but you can propose your own name instead."
tput cup 31 82;tput setaf 4;echo "Type in a database name"
tput cup 32 82;tput setaf 4;read -p "[default=oracledb]: " DBNAME

NAMEGOOD=0;

while [ "$NAMEGOOD" != 1 ]; do

	if [ "$DBNAME" == "" ]; then
	  DBNAME=oracledb
	fi
	
	LENGTHDBNAME=`echo -n $DBNAME | wc -m | sed -e s/^\s+//`
	NUMCHECK=`echo $DBNAME | sed -e s/^[0-9]//`
	
	if [ "$LENGTHDBNAME" -gt 8 ]; then
	  tput setaf 1;tput cup 17 5;tput bold;tput rev
	  echo "That name is too long. 8 or fewer characters please!"
	  NAMEGOOD=0
	fi
	
	if [ "$LENGTHDBNAME" -gt 0 ]; then
	  if [ "$DBNAME" != "$NUMCHECK" ]; then    
	    tput setaf 1;tput cup 17 5;tput bold;tput rev  
	    echo "That name starts with a number, which isn't allowed!"
	    NAMEGOOD=0
	  fi
	fi
	
	if [ "$LENGTHDBNAME" -gt 0 ]; then
	  if [ "$LENGTHDBNAME" -lt 9 ]; then
	     if [ "$DBNAME" = "$NUMCHECK" ]; then
	       NAMEGOOD=1
	     fi
	  fi
	fi
done

# -----------------------------------------------------------------------------------------------------------------------------
#  That's the interactive part over with (almost!). So now it's time to make some changes to the system. 
#  Let's begin by creating the oracle user and setting his password to whatever was supplied earlier
# -----------------------------------------------------------------------------------------------------------------------------

if [ "$USREXISTS" -eq 0 ]; then

  if [ "$DBAEXISTS" -eq 0 ]; then
    /usr/sbin/groupadd dba
  fi
  
  if [ "$OINEXISTS" -eq 0 ]; then
    /usr/sbin/groupadd oinstall
  fi
  /usr/sbin/useradd -m $ORACLEUSER -g oinstall -G dba -s /bin/bash
  echo $ORACLEUSER:$ORAPASSWD | chpasswd
  history -c
fi

if [ "$USREXISTS" -eq 1 ]; then
# -----------------------------------------------------------------------------------------------------------------------------
# We have to preserve the groups the user already has -which means working
# out what those groups are to start with!
# -----------------------------------------------------------------------------------------------------------------------------

  GROUPLIST=`id -Gn $ORACLEUSER`
  for group in $GROUPLIST; do

    if [ "$group" != 'dba' ] && [ "$group" != 'oinstall' ] ; then
      groupstring=$groupstring,$group
    fi
  done

  if [ "$DBAEXISTS" -eq 0 ]; then
    /usr/sbin/groupadd dba
  fi
  
  if [ "$OINEXISTS" -eq 0 ]; then
    /usr/sbin/groupadd oinstall
  fi

  /usr/sbin/usermod -g oinstall -G dba$groupstring $ORACLEUSER
fi

# -----------------------------------------------------------------------------------------------------------------------------
#  We need some symbolic links to make Ubuntu look more Red Hattish
# -----------------------------------------------------------------------------------------------------------------------------

if [ ! -e "/bin/awk" ]; then 
  ln -s /usr/bin/awk /bin/awk >/dev/null 2>&1
fi

if [ ! -e "/bin/rpm" ]; then 
  ln -s /usr/bin/rpm /bin/rpm >/dev/null 2>&1
fi

if [ ! -e "/lib/x86_64-linux-gnu/libgcc_s.so.1" ]; then 
  ln -s /lib/x86_64-linux-gnu/libgcc_s.so.1 /lib64/libgcc_s.so.1 >/dev/null 2>&1
fi

if [ ! -e "/lib/libgcc_s.so" ]; then 
  ln -s /lib/libgcc_s.so.1 /lib/libgcc_s.so >/dev/null 2>&1
fi

if [ ! -e "/bin/basename" ]; then 
  ln -s /usr/bin/basename /bin/basename >/dev/null 2>&1
fi

if [ ! -e "/usr/lib64" ]; then 
  ln -s /usr/lib/x86_64-linux-gnu /usr/lib64 >/dev/null 2>&1
fi

if [ ! -e "/bin/sh" ]; then 
  ln -sf /bin/bash /bin/sh >/dev/null 2>&1
fi

if [ "$NOBEXISTS" -eq 0 ]; then
  /usr/sbin/groupadd nobody >/dev/null 2>&1
fi

# -----------------------------------------------------------------------------------------------------------------------------
#  Now create the directory structure for the final Oracle
#  installation. Additionally, we create an /osource directory where the
#  Oracle software can be copied to disk, avoiding an off-DVD installation.
# -----------------------------------------------------------------------------------------------------------------------------

if [ ! -e "$ORAPATH/dbhome_1" ]; then 
  mkdir -p $ORAPATH/dbhome_1
fi

if [ ! -e "/osource" ]; then 
  mkdir /osource
fi

chown -R $ORACLEUSER:oinstall /u01/app
chmod -R 775 /u01/app
chown -R $ORACLEUSER:oinstall /osource
chmod -R 775 /osource

# -----------------------------------------------------------------------------------------------------------------------------
#  Now set the kernel parameters to values that Oracle likes
# ----------------------------------------------------------------------------------------------------------------------------- 

cat >> /etc/sysctl.conf << EOF

#Added for fresh Oracle 12cR2 Installation 
kernel.sem = 250 32000 100 128
# Assumes all of a 5120MB RAM is allocated, using 4K pages
kernel.shmall = 1310720
# Assumes half of a 5120MB RAM is allocated, in bytes
kernel.shmmax = 2684354560
kernel.shmmni = 4096
kernel.panic_on_oops = 1
fs.file-max = 6815744
net.ipv4.ip_local_port_range = 9000 65500
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048576
fs.aio-max-nr = 1048576
EOF

# -----------------------------------------------------------------------------------------------------------------------------
#  Now we have to set security limits.
# -----------------------------------------------------------------------------------------------------------------------------

cat /etc/security/limits.conf | sed /'# End of file'/d > /tmp/limits.wrk
cat >> /tmp/limits.wrk << EOF
$ORACLEUSER        soft    nproc    2047
$ORACLEUSER        hard    nproc   16384
$ORACLEUSER        soft    nofile   1024
$ORACLEUSER        hard    nofile  65536
$ORACLEUSER        soft    stack   10240
$ORACLEUSER        hard    stack   32768
# End of file
EOF

rm /etc/security/limits.conf
mv /tmp/limits.wrk /etc/security/limits.conf

cat >> /etc/pam.d/login << EOF
session    required     pam_limits.so
EOF

# -----------------------------------------------------------------------------------------------------------------------------
#  Now the Oracle User's environment variables are set
# -----------------------------------------------------------------------------------------------------------------------------

ENVFILE="/home/$ORACLEUSER/.bashrc"
cat >> $ENVFILE << EOF

#Added for fresh Oracle 12cR2 Installation
#export ORACLE_HOSTNAME=$HSTNM
export ORACLE_BASE=/home/oracle/database
export ORACLE_HOME=$ORACLE_BASE/product/$ORAVER/dbhome_1
export ORACLE_SID=$DBNAME
export ORACLE_UNQNAME=$DBNAME
export PATH=\$ORACLE_HOME/bin:\$PATH:.
export LD_LIBRARY_PATH=\$ORACLE_HOME/lib:/lib:/usr/lib
export CLASSPATH=\$ORACLE_HOME/JRE:\$ORACLE_HOME/jlib:\$ORACLE_HOME/rdbms/jlib

alias sql="rlwrap -r sqlplus / as sysdba"
alias diag="cd \$ORACLE_BASE/diag/rdbms/\$ORACLE_UNQNAME/\$ORACLE_SID/trace"

EOF

#  ---------------------------------------------------------------------------------
#  Now we create a systemd-compatible dboraz service, which we then enable to 
#  allow for the Oracle database to be automatically started and shutdown at every
#  server reboot. Note that *no* editing of /etc/oratab is required to get this to 
#  work -but it also means you're limited to auto-starting just one database.
#  ---------------------------------------------------------------------------------
if [ -f /etc/systemd/system/dboraz.service ]; then
  mv /etc/systemd/system/dboraz.service /etc/systemd/system/dboraz.service.original
fi

SYSFILE="/etc/systemd/system/dboraz.service"
cat >> $SYSFILE << EOF
[Unit]
Description=Autostart Oracle Databases
After=syslog.target network.target

[Service]
LimitMEMLOCK=infinity
LimitNOFILE=65536

Type=simple
RemainAfterExit=yes
User=$ORACLEUSER
Group=oinstall
ExecStart=/etc/dboraz-start.sh >> /home/$ORACLEUSER/dbstart.log 2>&1 &
ExecStop=/etc/dboraz-stop.sh >> /home/$ORACLEUSER/dbstop.log 2>&1

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload >/dev/null 2>&1
systemctl enable dboraz >/dev/null 2>&1

#  ---------------------------------------------------------------------------------
#  And now for the two scripts which the service calls
#  ---------------------------------------------------------------------------------
if [ -f /etc/dboraz-start.sh ]; then
  mv /etc/dboraz-start.sh /etc/dboraz-start.sh.original
fi

STARTFILE="/etc/dboraz-start.sh"
cat >> $STARTFILE << XXX
#! /bin/bash
export TMP=/tmp
export TMPDIR=$TMP
export PATH=/usr/sbin:/usr/local/bin:$PATH
export ORACLE_HOSTNAME=$HOSTNM
export ORACLE_UNQNAME=$DBNAME
export ORACLE_SID=$DBNAME
ORAENV_ASK=NO
. oraenv
ORAENV_ASK=YES

lsnrctl start
sqlplus / as sysdba << EOF
startup;
exit;
EOF
XXX

chmod 775 /etc/dboraz-start.sh

if [ -f /etc/dboraz-stop.sh ]; then
  mv /etc/dboraz-stop.sh /etc/dboraz-stop.sh.original
fi

STOPFILE="/etc/dboraz-stop.sh"
cat >> $STOPFILE << XXX
#! /bin/bash
export TMP=/tmp
export TMPDIR=$TMP
export PATH=/usr/sbin:/usr/local/bin:$PATH
export ORACLE_HOSTNAME=$HOSTNM
export ORACLE_UNQNAME=$DBNAME
export ORACLE_SID=$DBNAME 
ORAENV_ASK=NO
. oraenv
ORAENV_ASK=YES

sqlplus / as sysdba << EOF
shutdown abort;
exit;
EOF
XXX

chmod 775 /etc/dboraz-stop.sh

# -----------------------------------------------------------------------------------------------------------------------------
#  Time to get some software prerequisites installed.
# -----------------------------------------------------------------------------------------------------------------------------

clear
tput cup 23 82;tput setaf 4;echo "Software Repositories will now be updated."
tput cup 24 82;tput setaf 4;echo "This can take a long time."
tput cup 26 82;tput setaf 4;echo "Be patient!"

sed -i 's/deb cdrom:/#deb cdrom:/' /etc/apt/sources.list
apt-get -qq update 1>/dev/null 2>&1 &
tput cup 26 95;spinner $!

# -----------------------------------------------------------------------------------------------------------------------------
#  Now for the main prerequisite package installation loop
# -----------------------------------------------------------------------------------------------------------------------------

clear
tput cup 23 82;tput setaf 4;echo "Software Packages now being fetched and"
tput cup 24 82;tput setaf 4;echo "installed. This can take a long time, too!"
tput cup 26 82;tput setaf 4;echo "Be even more patient!"
    
for pkg in unixodbc unixodbc-dev g++-4.9 rlwrap make libaio1 libaio-dev zenity; do 	
  apt-get -qq install $pkg 1>/dev/null 2>&1 & 
  tput cup 30 82;tput setaf 4;echo "                                                     "
  tput cup 30 82;tput setaf 4;echo "Installing: "$pkg
  tput cup 26 105;spinner $!
done

update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.9 50 >/dev/null 2>&1
update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.9 50 >/dev/null 2>&1
update-alternatives --install /usr/bin/cpp cpp-bin /usr/bin/cpp-4.9 50 >/dev/null 2>&1
update-alternatives --set g++ /usr/bin/g++-4.9 >/dev/null 2>&1
update-alternatives --set gcc /usr/bin/gcc-4.9 >/dev/null 2>&1
update-alternatives --set cpp-bin /usr/bin/cpp-4.9 >/dev/null 2>&1

#  ---------------------------------------------------------------------------------
#  Ubuntu may produce a compilation error once the Oracle 12cR2 software 
#  installation is underway (depending on version). This part of the script creates 
#  another shell script in the oracle user's Documents directory which, if run, will 
#  add appropriate compiler switches to the various makefiles that will fix 
#  the problems, once a 'Retry' has been selected. 
#  ---------------------------------------------------------------------------------

cat >> /home/$ORACLEUSER/ubuntu-fixup.sh << EOF
#! /bin/bash
export ORACLE_HOME=$ORAPATH/dbhome_1

sudo ln -s \$ORACLE_HOME/lib/libclntshcore.so.12.1 /usr/lib
sudo ln -s \$ORACLE_HOME/lib/libclntsh.so.12.1 /usr/lib

cp \$ORACLE_HOME/rdbms/lib/ins_rdbms.mk \$ORACLE_HOME/rdbms/lib/ins_rdbms.bkp
cp \$ORACLE_HOME/rdbms/lib/env_rdbms.mk \$ORACLE_HOME/rdbms/lib/env_rdbms.bkp

sed -i 's/\$(ORAPWD_LINKLINE)/\$(ORAPWD_LINKLINE) -lnnz12/' \$ORACLE_HOME/rdbms/lib/ins_rdbms.mk
sed -i 's/\$(HSOTS_LINKLINE)/\$(HSOTS_LINKLINE) -lagtsh/' \$ORACLE_HOME/rdbms/lib/ins_rdbms.mk
sed -i 's/\$(EXTPROC_LINKLINE)/\$(EXTPROC_LINKLINE) -lagtsh/' \$ORACLE_HOME/rdbms/lib/ins_rdbms.mk
sed -i 's/\$(OPT) \$(HSOTSMAI)/\$(OPT) -Wl,--no-as-needed \$(HSOTSMAI)/' \$ORACLE_HOME/rdbms/lib/env_rdbms.mk
sed -i 's/\$(OPT) \$(HSDEPMAI)/\$(OPT) -Wl,--no-as-needed \$(HSDEPMAI)/' \$ORACLE_HOME/rdbms/lib/env_rdbms.mk
sed -i 's/\$(OPT) \$(EXTPMAI)/\$(OPT) -Wl,--no-as-needed \$(EXTPMAI)/' \$ORACLE_HOME/rdbms/lib/env_rdbms.mk
sed -i 's/^\(TNSLSNR_LINKLINE.*\$(TNSLSNR_OFILES)\) \(\$(LINKTTLIBS)\)/\1 -Wl,--no-as-needed \2/g' \$ORACLE_HOME/network/lib/env_network.mk
sed -i 's/\$(SPOBJS) \$(LLIBSERVER)/\$(SPOBJS) -Wl,--no-as-needed \$(LLIBSERVER)/' \$ORACLE_HOME/rdbms/lib/env_rdbms.mk
sed -i 's/\$(S0MAIN) \$(SSKFEDED)/\$(S0MAIN) -Wl,--no-as-needed \$(SSKFEDED)/' \$ORACLE_HOME/rdbms/lib/env_rdbms.mk
sed -i 's/\$(S0MAIN) \$(SSKFODED)/\$(S0MAIN) -Wl,--no-as-needed \$(SSKFODED)/' \$ORACLE_HOME/rdbms/lib/env_rdbms.mk
sed -i 's/\$(S0MAIN) \$(SSKFNDGED)/\$(S0MAIN) -Wl,--no-as-needed \$(SSKFNDGED)/' \$ORACLE_HOME/rdbms/lib/env_rdbms.mk
sed -i 's/\$(S0MAIN) \$(SSKFMUED)/\$(S0MAIN) -Wl,--no-as-needed \$(SSKFMUED)/' \$ORACLE_HOME/rdbms/lib/env_rdbms.mk
sed -i 's/^\(ORACLE_LINKLINE.*\$(ORACLE_LINKER)\) \($(PL_FLAGS)\)/\1 -Wl,--no-as-needed \2/g' \$ORACLE_HOME/rdbms/lib/env_rdbms.mk
sed -i 's/\$LD \$LD_RUNTIME/$LD -Wl,--no-as-needed \$LD_RUNTIME/' \$ORACLE_HOME/bin/genorasdksh
sed -i 's/\$(GETCRSHOME_OBJ1) \$(OCRLIBS_DEFAULT)/\$(GETCRSHOME_OBJ1) -Wl,--no-as-needed \$(OCRLIBS_DEFAULT)/' \$ORACLE_HOME/srvm/lib/env_srvm.mk
sed -i 's/\$(LINK) \$(WRAP_MAIN)/\$(LINK) \$(WRAP_MAIN) -Wl,--no-as-needed/' \$ORACLE_HOME/plsql/lib/env_plsql.mk
sed -i 's/\$(OPT) \$(PWDMAI)/\$(OPT) -Wl,--no-as-needed \$(PWDMAI)/' \$ORACLE_HOME/rdbms/lib/env_rdbms.mk
sed -i 's/\$(OPT) \$(TKPMAI)/\$(OPT) -Wl,--no-as-needed \$(TKPMAI)/' \$ORACLE_HOME/rdbms/lib/env_rdbms.mk
sed -i 's/\$(OPT) \$(PLSTMAI)/\$(OPT) -Wl,--no-as-needed \$(PLSTMAI)/' \$ORACLE_HOME/rdbms/lib/env_rdbms.mk
sed -i 's/\$(OPT) \$(ORIONMAI)/\$(OPT) -Wl,--no-as-needed \$(ORIONMAI)/' \$ORACLE_HOME/rdbms/lib/env_rdbms.mk
sed -i 's/\$(LINK) \$(SQLPLUSLIBS)/\$(LINK) -Wl,--no-as-needed \$(SQLPLUSLIBS)/' \$ORACLE_HOME/sqlplus/lib/env_sqlplus.mk
sed -i 's/\$(LINK) \$(LSNRCTL_OFILES)/\$(LINK) -Wl,--no-as-needed \$(LSNRCTL_OFILES)/' \$ORACLE_HOME/network/lib/env_network.mk

zenity --info --title "Fix-up Script Applied" --text="Click OK to return to the Oracle Installer, \nthen click the [Retry] option."

exit 0
EOF

chmod 775 /home/$ORACLEUSER/ubuntu-fixup.sh

# -----------------------------------------------------------------------------------------------------------------------------
#  Finally, prompt for downloading the Oracle software from a Home Server (optional!)
#  Please note this functionality requires the use of a web server configured correctly
#  and for that server to be hosting the 12cR2 software ZIP files in their compressed state.
#  For example, you might have two ZIP files called "linuxamd64_12102_database_1of2.zip"
#  and "linuxamd64_12102_database_2of2.zip' (those being the file names you get when you)
#  download the 12.1.0.2 software from OTN). In that case, if both files reside in your 
#  web server's document root, you'd type in:
#  http://<websever-IP-or-name>/linuxamd64_12102_database_1of2.zip;http://<websever-IP-or-name>/linuxamd64_12102_database_2of2.zip;
#  ...when prompted. The URL will probably wrap on your screen: it doesn't matter.
#  But note: no spaces in any of that lot, and each part of the string (either side of the)
#  semi-colon should be completely resolvable in its own right.
# -----------------------------------------------------------------------------------------------------------------------------

tput cup 23 82;tput setaf 4;echo "If you have a home server able to"
tput cup 24 82;tput setaf 4;echo "provide the Oracle 12cR2 software,"
tput cup 25 82;tput setaf 4;echo "Atlas can acquire that software now."
tput cup 27 82;tput setaf 4;echo "Do you wish to do this?"
tput cup 29 82;tput setaf 4;echo "Type y or n:"
tput cup 30 82;read -p "[default=n]: " FETCH 
		
if [ "$FETCH" == "" ]; then
  FETCH=n
fi

if [ "$FETCH" == "y" ]; then
  tput cup 23 82;tput setaf 4;echo "You now need to type in the URLs to the"
  tput cup 24 82;tput setaf 4;echo "zipped Oracle database software files."
  tput cup 26 82;tput setaf 4;echo "Separate each URL with a semi-colon."
  tput cup 28 82;tput setaf 4;echo "Type your URLs: " 
  tput cup 30 82;read -p "" FETCHURL 

  url=$FETCHURL
  fileno=1

  tput cup 23 82;tput setaf 4;echo "Fetching database installation files."
  tput cup 25 82;tput setaf 4;echo "Depending on your network speed, this"
  tput cup 26 82;tput setaf 4;echo "could take a *very* long time!"
  fileurl=$(echo $url | tr ";" "\n")
  for addr in $fileurl
  do
    wget "$addr" -O /osource/db12$fileno.zip > /dev/null 2>&1 &
    tput cup 29 95;spinner $!
    ((fileno++))
  done

  cd /osource
  
  tput cup 23 82;tput setaf 4;echo "Database installation files fetched. "
  tput cup 25 82;tput setaf 4;echo "Now unpacking them to make them usable."
  tput cup 26 82;tput setaf 4;echo "Please be patient!"
  for file in *.zip; do
    unzip $file > /dev/null 2>&1 &
    tput cup 29 95;spinner $!
  done

  rm *.zip
  chmod -R 777 database
  chown -R $ORACLEUSER database
fi

# -----------------------------------------------------------------------------------------------------------------------------
#  All done. We need to trigger a reboot for the new settings etc. to be picked up.
# -----------------------------------------------------------------------------------------------------------------------------

clear
tput cup 23 82;tput setaf 4;echo "All Done!"
tput cup 25 82;tput setaf 4;echo "We need to reboot to ensure the new"
tput cup 26 82;tput setaf 4;echo "settings are applied completely."
tput cup 28 82;tput setaf 4;echo "When the server comes back up, log on"
tput cup 29 82;tput setaf 4;echo "as '$ORACLEUSER' and perform an"
tput cup 30 82;tput setaf 4;echo "Oracle 12cR2 install as normal."
tput cup 32 82;read -n 1 -s -p "Press a key to reboot..."
reboot
exit 0
