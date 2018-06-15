#!/bin/bash

# Set the FunFHMMer project directories
RESULTS=${PROJECTHOME}/results/
JOB_STATUS=${PROJECTHOME}/job_status/
#SCRIPTNAME="run_funfhmmer_in_bchuckle_cluster-SFs."

# Check whether the jobs are all completed
for file in `find $JOB_STATUS -name "*.stdout"`
do
  filename=`basename $file .stdout`
  #filename_short=${filename/$SCRIPTNAME/}
  searchline1=`grep "#JOB COMPLETE for " $file`
  array1=${searchline1}
  SF=${array1[-1]}
  searchline2=`grep "hours" $file`
  array2=($searchline2)
  hours=${array2[-2]}
  echo "$filename: $SF completed in $hours hours"
done

# Untar result directories
for file in `find $RESULTS -name "*.tar.gz"`
do
	sf=`basename $file .tar.gz`
	echo $sf
	mkdir $DIR/$sf
	echo "$DIR/$sf"
	echo $file
	tar -xvzf $file -C $DIR/$sf
done
