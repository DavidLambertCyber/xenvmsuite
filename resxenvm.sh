
#! /bin/bash
#====== functions ====================================

#------ check if root, and parameters -----------------

check_list(){

# check if root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# test if parameters passed in are blank
if [[ -z "$VMUUID" ]]; then
  echo " first parameter blank"
  echo " USEAGE"
  echo " resxenvm.sh [uuid-of-vm] [full-path-to-xva-file]"
  exit 1
fi

if [[ -z "$XVAFILE" ]]; then
  echo " second parameter blank"
  echo " USEAGE"
  echo " resxenvm.sh [uuid-of-vm] [full-path-to-xva-file]"
  exit 1
fi

# test the parameters being passed in
UUIDSIG="[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"
VMUUIDTEST=$(echo $VMUUID | egrep  $UUIDSIG)

if [[ -z "$VMUUIDTEST" ]]; then
  echo " uuid incorrect form"
  echo " resxenvm.sh [uuid-of-vm] [full-path-to-xva-file]"
  echo " EXAMPLE"
  echo " resxenvm.sh abcd1234-abcd-abcd-abcd-abcdef123456 /full/path/to/file.xva"
  exit 1
fi

# test if second parameter has file extension xva
XVATEST=$( echo $XVAFILE | egrep /.*\.xva)
if [[ -z "$XVATEST" ]]; then
  echo " path to file missing extension .xva"
  echo " resxenvm.sh [uuid-of-vm] [full-path-to-xva-file]"
  echo " EXAMPLE"
  echo " resxenvm.sh abcd1234-abcd-abcd-abcd-abcdef123456 /full/path/to/file.xva"
  exit 1
fi

# test if second parameter is readable
if [[ ! -r $XVAFILE ]]; then
  echo " $XVAFILE not readable"
  exit 1
fi

# test if uuid exists
UUIDEXIST=$(xe vm-list uuid=$VMUUID)
if [[ -z "$UUIDEXIST" ]]; then
  echo " the uuid $VMUUID not exist"
  exit 1
fi

} # end check_list()

#----- get the name and descritption ----------------

get_name_des(){

# store the label or name of vm
VMNAME=$( xe vm-list uuid=$VMUUID params=name-label | grep name | cut -c 23- )

# store the description of vm
xe vm-list uuid=$VMUUID params=name-description	> des.txt

} # end get_name_des()

#----- delete the vm to be replaced -----------------

del_vm(){

# shutdown uuid of vm to uninstall
xe vm-shutdown uuid=$VMUUID force=true

# uninstall the vm
xe vm-uninstall uuid=$VMUUID force=true

} # end del_vm()

#------- update the vm name, description ----------------

update_vm(){

# update the description of the vm
echo " | This vm restored from $XVAFILE on $(date) | " >> des.txt

# set the description
# xen can't have newlines in description
xe vm-param-set uuid=$NEWVMUUID name-description="$(tr '\n' ' ' < des.txt)"

# change the name of vm
xe vm-param-set uuid=$NEWVMUUID name-label=$VMNAME

} # end update_vm()

#----- clean up some temp files --------------------

clean_up(){

rm -f ./des.txt

} # end clean_up

#----- check config-xenvmsuite.txt -----------------

check_config(){

# check for config-xenvmsuite.txt
if [[ -r ./config-xenvmsuite.txt ]]; then
  TESTUUID=$(egrep ^UUID-TO-BU=$VMUUID ./config-xenvmsuite.txt)

  if [[ -z "$TESTUUID" ]]; then
    UPDATECONFIG=false
    echo "config-xenvmsuite.txt cannot be updated"
  fi
else
 UPDATECONFIG=false
fi

} # end check_config()

#----- fix config-xenvmsuite.txt -------------------

update_config(){

if [[ ! -w ./config-xenvmsuite.txt ]]; then
  echo "Could not update the config-xenvmesuite.txt"
  echo "file not exist or not writeable"
  clean_up
  exit 1
fi

# change the config 
sed -i s/"$VMUUID"/"$NEWVMUUID"/g ./config-xenvmsuite.txt

} # end update_config()

#=========================== end functions ==========
#==== run ==========================================

VMUUID=$1     # pass in uuid of vm to destroy and restore from file
XVAFILE=$2    # pass in the path/file.xva to restore to
UPDATECONFIG=true

# check parameters and if root
check_list

# get name and descritption
get_name_des

# uninstall the vm to be replaced
del_vm

# import the vm to restore (preserve will keep MAC address)
NEWVMUUID=$( xe vm-import filename=$XVAFILE preserve=true ) 
sleep 1

# update the vm name and description
update_vm

# update the config-xenvmsuite.txt
check_config
if [[ $UPDATECONFIG == "true" ]]; then
  update_config
fi

# start the vm
xe vm-start uuid=$NEWVMUUID

# remove temp stufff
clean_up

exit 0
