#! /bin/bash

# Fixup script to be run after the Oracle installer throws an error usually around the linking process 

ORAVER=12.2.0
ORAPATH=/home/oracle/database/product/$ORAVER
export ORACLE_HOME=$ORAPATH/dbhome_1

sudo ln -s $ORACLE_HOME/lib/libclntshcore.so.12.1 /usr/lib
sudo ln -s $ORACLE_HOME/lib/libclntsh.so.12.1 /usr/lib

cp $ORACLE_HOME/rdbms/lib/ins_rdbms.mk $ORACLE_HOME/rdbms/lib/ins_rdbms.bkp
cp $ORACLE_HOME/rdbms/lib/env_rdbms.mk $ORACLE_HOME/rdbms/lib/env_rdbms.bkp

sed -i 's/$(ORAPWD_LINKLINE)/$(ORAPWD_LINKLINE) -lnnz12/' $ORACLE_HOME/rdbms/lib/ins_rdbms.mk
sed -i 's/$(HSOTS_LINKLINE)/$(HSOTS_LINKLINE) -lagtsh/' $ORACLE_HOME/rdbms/lib/ins_rdbms.mk
sed -i 's/$(EXTPROC_LINKLINE)/$(EXTPROC_LINKLINE) -lagtsh/' $ORACLE_HOME/rdbms/lib/ins_rdbms.mk
sed -i 's/$(OPT) $(HSOTSMAI)/$(OPT) -Wl,--no-as-needed $(HSOTSMAI)/' $ORACLE_HOME/rdbms/lib/env_rdbms.mk
sed -i 's/$(OPT) $(HSDEPMAI)/$(OPT) -Wl,--no-as-needed $(HSDEPMAI)/' $ORACLE_HOME/rdbms/lib/env_rdbms.mk
sed -i 's/$(OPT) $(EXTPMAI)/$(OPT) -Wl,--no-as-needed $(EXTPMAI)/' $ORACLE_HOME/rdbms/lib/env_rdbms.mk
sed -i 's/^\(TNSLSNR_LINKLINE.*$(TNSLSNR_OFILES)\) \($(LINKTTLIBS)\)/\1 -Wl,--no-as-needed \2/g' $ORACLE_HOME/network/lib/env_network.mk
sed -i 's/$(SPOBJS) $(LLIBSERVER)/$(SPOBJS) -Wl,--no-as-needed $(LLIBSERVER)/' $ORACLE_HOME/rdbms/lib/env_rdbms.mk
sed -i 's/$(S0MAIN) $(SSKFEDED)/$(S0MAIN) -Wl,--no-as-needed $(SSKFEDED)/' $ORACLE_HOME/rdbms/lib/env_rdbms.mk
sed -i 's/$(S0MAIN) $(SSKFODED)/$(S0MAIN) -Wl,--no-as-needed $(SSKFODED)/' $ORACLE_HOME/rdbms/lib/env_rdbms.mk
sed -i 's/$(S0MAIN) $(SSKFNDGED)/$(S0MAIN) -Wl,--no-as-needed $(SSKFNDGED)/' $ORACLE_HOME/rdbms/lib/env_rdbms.mk
sed -i 's/$(S0MAIN) $(SSKFMUED)/$(S0MAIN) -Wl,--no-as-needed $(SSKFMUED)/' $ORACLE_HOME/rdbms/lib/env_rdbms.mk
sed -i 's/^\(ORACLE_LINKLINE.*$(ORACLE_LINKER)\) \($(PL_FLAGS)\)/\1 -Wl,--no-as-needed \2/g' $ORACLE_HOME/rdbms/lib/env_rdbms.mk
sed -i 's/$LD $LD_RUNTIME/$LD -Wl,--no-as-needed $LD_RUNTIME/' $ORACLE_HOME/bin/genorasdksh
sed -i 's/$(GETCRSHOME_OBJ1) $(OCRLIBS_DEFAULT)/$(GETCRSHOME_OBJ1) -Wl,--no-as-needed $(OCRLIBS_DEFAULT)/' $ORACLE_HOME/srvm/lib/env_srvm.mk
sed -i 's/$(LINK) $(WRAP_MAIN)/$(LINK) $(WRAP_MAIN) -Wl,--no-as-needed/' $ORACLE_HOME/plsql/lib/env_plsql.mk
sed -i 's/$(OPT) $(PWDMAI)/$(OPT) -Wl,--no-as-needed $(PWDMAI)/' $ORACLE_HOME/rdbms/lib/env_rdbms.mk
sed -i 's/$(OPT) $(TKPMAI)/$(OPT) -Wl,--no-as-needed $(TKPMAI)/' $ORACLE_HOME/rdbms/lib/env_rdbms.mk
sed -i 's/$(OPT) $(PLSTMAI)/$(OPT) -Wl,--no-as-needed $(PLSTMAI)/' $ORACLE_HOME/rdbms/lib/env_rdbms.mk
sed -i 's/$(OPT) $(ORIONMAI)/$(OPT) -Wl,--no-as-needed $(ORIONMAI)/' $ORACLE_HOME/rdbms/lib/env_rdbms.mk
sed -i 's/$(LINK) $(SQLPLUSLIBS)/$(LINK) -Wl,--no-as-needed $(SQLPLUSLIBS)/' $ORACLE_HOME/sqlplus/lib/env_sqlplus.mk
sed -i 's/$(LINK) $(LSNRCTL_OFILES)/$(LINK) -Wl,--no-as-needed $(LSNRCTL_OFILES)/' $ORACLE_HOME/network/lib/env_network.mk

zenity --info --title "Fix-up Script Applied" --text="Click OK to return to the Oracle Installer, \nthen click the [Retry] option."

exit 0
