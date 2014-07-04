#! /bin/bash
#====== functions ========================================

#----- check everything ready to run ---------------------

check_list(){

## check if root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

## check if config-xenvmsuite.txt cofiguration file exists and readable
if [ ! -r ./config-xenvmsuite.txt ]; then
  echo "-- The config-xenvmsuite.txt file is missing or not readable ABORT --" >> $LOGFILE.log 2>&1
  exit 1
fi

## check if buxenvm.sh exists and executable
if [ ! -x ./buxenvm.sh ]; then
  echo "-- The buxenvm.sh file is missing or not executable ABORT --" >> $LOGFILE.log 2>&1
  exit 1
fi

} # end checklist()

#-- get the things needed from the config file ----------------

get_config(){

# get the logfile name or set default
LOGFILE=$(egrep ^LOGFILE=.* ./config-xenvmsuite.txt | cut -c 9- )
if [[ -z "$LOGFILE" ]]; then
  LOGFILE=/var/log/xenvmsuite
fi


# set the signature and form of uuid
UUIDSIG="[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"
UUIDFORM="........-....-....-....-............"

# get the uuid from config file
VMUUID=$(egrep ^UUID-TO-BU=$UUIDSIG ./config-xenvmsuite.txt | egrep -o $UUIDFORM)
if [[ -z "$VMUUID" ]]; then
  echo "-- The config-xenvmsuite.txt file has no UUID or incorrect format ABORT --" >> $LOGFILE.log 2>&1
  exit 1
fi

# get the directory to store all backups
NFS=$(egrep ^EXPORT-DIR=.*./ ./config-xenvmsuite.txt | cut -c 12- )
if [[ -z "$NFS" ]]; then
  echo "-- config-xenvmsuite.txt has no directory to backup files  or incorrect format ABORT --" >> $LOGFILE.log 2>&1
  exit 1
fi

# get the number of backup files to keep
LIMIT=$(egrep ^BU-LIMIT=[0-9]* ./config-xenvmsuite.txt | cut -c 10-)
if [[ -z "$LIMIT" ]]; then
  echo "-- config-xenvmsuite.txt BU-LIMIT not set or incorrect format ABORT --" >> $LOGFILE.log 2>&1
  exit 1
fi

# get the date form for file names
NONOW=$($(egrep ^DATE-CMD=.* ./config-xenvmsuite.txt | cut -c 10-))
NOW=$(echo $NONOW | sed s/\"//g )

if [[ -z "$NOW" ]]; then
  NOW=$(date +"%F-at-%H-%M")
fi

} # end get_config()


#-------- set up the log file ---------------------------

setup_logs(){


if [ ! -e "$LOGFILE.log" ]; then
  echo $MONTH > $LOGFILE.log
fi

# Retrieving month from log file
MONTH=$(date +%b)
LOGFILEMONTH=$(head -n 1 $LOGFILE.log)

if [ "$LOGFILEMONTH" != "$MONTH" ]; then
  gzip -c $LOGFILE.log > $LOGFILE-$NOW.log.gz 2>&1
  echo $MONTH > $LOGFILE.log
fi

} # end setup_logs()

#----- do the backup -------------------------------------

do_backup(){


for UUID in ${VMUUID[@]}; do
  # do the backup
  ./buxenvm.sh $UUID $NFS >> $LOGFILE.log 2>&1
done

} # end do_backup()

#==== end functions ===================================
#==== run =============================================

## do some checks before we actually do anything
check_list

## get the settings from the config file
get_config

## setup the log files
setup_logs

## do the backup
do_backup

#==== end run ==========================================
exit 0
