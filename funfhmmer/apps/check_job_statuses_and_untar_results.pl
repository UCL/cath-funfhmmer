#!/bin/bash

# Set the FunFHMMer project directories
RESULTS=${PROJECTHOME}/results/
JOB_STATUS=${PROJECTHOME}/job_status/
#SCRIPTNAME="run_funfhmmer_in_bchuckle_cluster-SFs."

echo ""
echo "Untarring the result folders:"
echo ""

# Untar result directories and look for empty files
for file in `find $RESULTS -name "*.tar.gz"`
do
	SF=`basename $file .tar.gz`
	echo "Checking $SF results:"
	tar -xvzf $file -C $RESULTS
  for f in $RESULTS/$SF/* $RESULTS/$SF/funfam_alignments/* $RESULTS/$SF/funfam_alignments/analysis_data/* ;
  do
    if [ -s $f ] ; then
      x=$f #dummy line, does nothing
    else
      echo " - ERROR: $f is EMPTY!"
    fi
  done
  logfile=$RESULTS/$SF/$SF.LOG
  if [ -s $logfile ] ; then
    loglastline=`tail -n 1 $logfile`
    array1=($loglastline)
    check_lastline=${array1[-1]}
    hours=${array1[-2]}
    #echo "$array1, $check_lastline, $hours"
    if [ $check_lastline == "hours" ] ; then
      echo " - $SF was completed in $hours hours"
    fi
  fi
done

echo ""
echo "Here are the job status files:"
echo ""

# Check whether the jobstatus have any errors
for file in `find $JOB_STATUS -name "*.stdout"`
do
  filename=`basename $file .stdout`
  #filename_short=${filename/$SCRIPTNAME/}
  searchline1=`grep "#JOB COMPLETE for " $file`
  array1=${searchline1}
  SF=${array1[-1]}
  searchline2=`grep -i "error" $file`
  if [ -z "$searchline2" ]; then
    echo "$filename: $SF has no errors."
  else
    echo "$filename: $SF has ERRORS!"
  fi
done
