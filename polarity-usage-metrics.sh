#!/bin/bash

#####
#
# Copyright (c) 2023 - Polarity.IO
#
#####



###### MAKE SURE SCRIPT IS RUNNING AS ROOT USER ######
if [[ $EUID -ne 0 ]]
then
  echo -e "\n\tYou MUST run this script with SuperUser privileges . . . EXITING\n"
  exit 1
fi




##### GLOBAL VARIABLES #####
WORK_DIR=/app/polarity-server/logs
MAX_FILES=21
WORKING_FILE=polarity-server.log
ROTATED_FILE=polarity-server.log-[[:digit:]]{8}.gz


##### WORKING VARIABLES #####
numHasResult=0
maxRotFiles=$(($MAX_FILES-1))
hrTRUE=0
hrFALSE=0


##### FUNCTIONS #####
function parseFile ()         # Parse the current file
{
  grep "hasResult" $1 | jq -r '. | {hasResult,userId} | join(" ")' | while read -a HRL
  do
    if [[ ${HRL[0]} -eq "true" ]]
    then
      ((hrTRUE+=1))
    else
      ((hrFALSE+=1))
    fi

  done
  HRcount=$(grep "hasResult" $1|wc -l)
  #echo $HRcount
  numHasResult=$(($numHasResult+$HRcount))
}

function unPack ()          # Unpack the current file
{
  gunzip $1
}

function rePack ()          # Repack the current file
{
  gzip $1
}

function summaryOutput ()
{
  echo -e "\tRESULTS:\n\tNumber of hasResults lines:  $numHasResult\n\n"
}


##### MAIN #####


## Get number of rotated files
count_rot=$(ls $WORK_DIR | grep -E $ROTATED_FILE | wc -l)


## Execute based on number of rotated files
if (( $count_rot > $maxRotFiles ))
then                    # Rotated files is GREATER THAN MAX_FILES-1
  echo "Parsing $MAX_FILES of $(($count_rot+1)) Files . . ."
  for nm in $(ls -t $WORK_DIR | grep -E $ROTATED_FILE | head -n $maxRotFiles)
  do
    echo "Processing $nm . . ."
    unPack $WORK_DIR/$nm

    baseNm=$(echo $nm |cut -d. -f1,2)         # Get filename without .gz extension

    #echo "Parsing $baseNm . . ."
    parseFile $WORK_DIR/$baseNm

    #echo "Repackaging $baseNm . . ."
    rePack $WORK_DIR/$baseNm
  done
else                    # Rotated files is LESS THAN OR EQUAL TO MAX_FILES-1
  echo "Parsing $(($count_rot+1)) Files . . ."
  for nm in $(ls -t $WORK_DIR | grep -E $ROTATED_FILE)
  do
    echo "Processing $nm . . ."
    unPack $WORK_DIR/$nm

    baseNm=$(echo $nm |cut -d. -f1,2)         # Get filename without .gz extension

    #echo "Parsing $baseNm . . ."
    parseFile $WORK_DIR/$baseNm

    #echo "Repackaging $baseNm . . ."
    rePack $WORK_DIR/$baseNm
  done
fi

## Finishing stats collection with Working log file
echo "Processing $WORKING_FILE . . ."
parseFile $WORK_DIR/$WORKING_FILE

## Reset Permissions
chown polarityd: $WORK_DIR/*

## Print Results
summaryOutput

