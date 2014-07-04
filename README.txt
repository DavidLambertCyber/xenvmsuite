############################################################################

BEFORE dobuxenvm.sh FIRST RUN

YOU MUST SET THE CONFIGURATIONS IN config-xenvmsuite.txt

All scritps should run from the same directory.

All scritps require to run as root.

############################################################################


xenvmsuite includes dobuxenvm.sh, config-dobuxenvm.txt, buxenvm.sh, 
and resxenvm.sh. 

Copy these file to /root/ directory, on the host Citrix Xen machine
running Citrix Xen Server. Configure the config-xenvmsuite.txt. Set 
cronjob to run the dobuxenvm.sh on a regular basis. It is best to setup
Network File System for the export directory becasue each backup is a full
export of a snapshot and can consume disk space quickly. Be sure to set limit
of backups in config-xenvmsuite.txt to a reasonable amount.

AUTHORS

  David A. Lambert, MCSE, BSCS, University of Southern Maine
  2013-December-15

  Alex M. Weeman, BCE, University of Southern Maine

----------------------------------------------------------------------------
NAME

  buxenvm.sh (Backup Xen Virtual Machine)

USEAGE

  buxenvm.sh [uuid-of-vm] [export-directory-full-path-WITH-trailing-slash]

DISCRIPTION

  Will take a snapshot of a Citrix Xen virtual machine and export it to
  a directory. A new directory of the snapshot vm name is updated or
  created to store the xva file. buxenvm.sh is verbose.
   
  1. Check if running as root, parameters are blank, uuid is correct form
      and path has trailing slash.
  
  2. Get the date command and limit of backup files to keep from
      config-xenvmsuite.txt.
  
  3. Create the names of export directory and backup file as
      export directory = name of virtual machine
      export file = date-time_vm-name_vm-uuid.xva

  4. Snapshot the virtual machine. 

  5. Export the snapshot and remove the snapshot.

  6. Check the export directory if have more than the limit set in
      config-xenvmsuite.txt. If ls gives more than limit the first file ls
      gives is deleted.

---------------------------------------------------------------------------
NAME

   dobuxenvm.sh (Do Backup Xen Virtual Machine)

USEAGE

   dobuxenvm.sh

DISCRIPTION

   BEFORE FIRST RUN YOU MUST SET THE CONFIGURATIONS IN config-xenvmsuite.txt

   Will grab uuids from config-xenvmsuite.txt to call buxenvm.sh on uuids.
   All output will goto a log file set in config-xenvmsuite.txt.

   Requires buxenvm.sh and config-xenvmsuite.txt in same directory.

   Example cronjob run every weekday at 1am
     00 01 * * 1-5 /root/dobuxenvm.sh

Updates
  
  Alex Weeman	
  
  Modified dobuxenvm.sh script to gzip the log files by month instead of by
  the most 30 recent files. As well as erased the old MAX LIMIT code from
  the script.

----------------------------------------------------------------------------
NAME

  resxenvm.sh (Restore Xen Virtual Machine)

USEAGE

  resxenvm.sh [uuid-of-vm] [full-path-to-xva-file]

DISCRIPTION

  Is intended to restore a virtual machine from a prevous exported xva file. The
  MAC address, and name is preserved. The description is preserved and updated.
  
  In config-xenvmsuite.txt file the corrisponding uuid will be replaced with
  the new uuid created from the import of the xva file.

  Requires config-xenvmsuite.txt in same working directory.
  
  Requires run as root.

---------------------------------------------------------------------------

