#! /bin/bash
#======= functions ========================================================

#------ check parameters passed in ------------------------------------

check_list(){

# check if root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# test if parameters passed in are blank
if [[ -z "$VMUUID" ]]; then
  echo " incorrect first parameter"
  echo " USEAGE"
  echo " buxenvm.sh [uuid-of-vm] [export-directory-full-path-WITH-trailing-slash]"
  exit 1
fi

if [[ -z "$BASEDIR" ]]; then
  echo " incorrect second parameter"
  echo " USEAGE"
  echo " buxenvm.sh [uuid-of-vm] [export-directory-full-path-WITH-trailing-slash]"
  exit 1
fi

# test the parameters being passed in
UUIDSIG="[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"
VMUUIDTEST=$(echo $VMUUID | egrep  $UUIDSIG)

if [[ -z "$VMUUIDTEST" ]]; then
  echo " USEAGE"
  echo " buxenvm.sh [uuid-of-vm] [export-directory-full-path-WITH-trailing-slash]"
  echo " EXAMPLE"
  echo " buxenvm.sh abcd1234-abcd-abcd-abcd-abcdef123456 /full/path/slash/"
  exit 1
fi

} # end check_list()

#------- get configurations ------------------------------

get_config(){

# get the date command for file names
NONOW=$($(egrep ^DATE-CMD=.* ./config-xenvmsuite.txt | cut -c 10-))
NOW=$(echo $NONOW | sed s/\"//g )

if [[ -z "$NOW" ]]; then
  NOW=$(date +"%F-at-%H-%M")
fi

# get the limit of backup files to hold 
LIMIT=$(egrep ^BU-LIMIT=.* ./config-xenvmsuite.txt | cut -c 10- )

} # end get_config()

#-------- setup backup directory and names ---------------

set_dir_names(){

# name of vm
VMNAME=$( xe vm-list uuid=$VMUUID params=name-label | grep name | cut -c 23- )

# create the name of backupfile
BACKUPNAME="$NOW"_"$VMNAME"_"$VMUUID"

# create backup name with extension
BACKUPFILE="$BACKUPNAME.xva"

# full directory path to export to
EXPORTDIR="$BASEDIR$VMNAME"

} # end set_dir_names

#------- do the snapshot ----------------------------------

do_snapshot(){

# make the dir to export to
#echo "makeing dir $EXPORTDIR"
mkdir -p $EXPORTDIR

# change to dir to export to
cd $EXPORTDIR
 
echo "doing snapshot"
SNAPSHOTUUID=$(xe vm-snapshot vm=$VMUUID new-name-label=$VMNAME)
sleep 1

} # end do_snapshot()

#------ do export ---------------------------------------

export_snapshot(){

if [[ -z "$SNAPSHOTUUID" ]]; then
  echo "there was an error during the snapshot --ABORT"
  exit 1
fi

# turn off template for exporting
xe template-param-set is-a-template=false uuid=$SNAPSHOTUUID

# do the export in working directory
echo "export snapshot with filename $BACKUPFILE"
xe vm-export uuid=$SNAPSHOTUUID filename=$BACKUPFILE

# flush the filesystem
sync
sleep 1

# remove the local snapshot
echo "uninstall snapshot from Xen Server"
xe vm-uninstall uuid=$SNAPSHOTUUID force=true

# flush the filesystem
sync
sleep 1

} # end export_snapshot()

#----- enforec the limit set in config -------------------

enforce_limit(){

# check if limit  in get_config()
if [[ ! -z "$LIMIT" ]]; then

  # get the number of backup files in directory
  NUMOFBU=$(ls | wc -l)

  # if more than LIMIT files in directory  then delete the oldest
  if [[ $NUMOFBU -ge $LIMIT ]]; then
     FILETODEL=$(ls | head -n 1)
     echo "buxenvm.sh deleting $FILETODEL BU-LIMIT reached" >> $LOGFILE.log 2>&1
     rm -f $FILETODEL
  fi

else
  echo "LIMIT not set in config-xenvmsuite.txt"
fi

} # end enforce_limit()

#============================ end functions ==============
#======== run =============================================
#== functions need to be called in order
#== all varibles global so functions coupled 

# get parameters passed in
VMUUID=$1   # uuid of the vm to be snapshot
BASEDIR=$2  # pass in the dir to export the snapshot to

# do some checks before run
check_list

# get our working directory
HERE=$(pwd)

# get config, parameters, and vm name
get_config

# setup the directory and names
set_dir_names

##### now have everything to start backup

# intro log
echo "--"
echo "$(date) :buxenvm.sh [$VMNAME]"

# do the snapshot
do_snapshot

# export the snapshot
export_snapshot

# enforce limit
enforce_limit

# go back to previous dir, must be after enforce_limit
cd $HERE

# done success
echo "done buxenvm.sh [$VMNAME] as [$BACKUPFILE]"

exit 0

#=================================== end run ====================
