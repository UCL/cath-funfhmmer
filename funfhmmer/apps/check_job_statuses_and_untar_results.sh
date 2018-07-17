#!/bin/bash

# Set the FunFHMMer project directories
RESULTS=${PROJECTHOME}/results
JOB_STATUS=${PROJECTHOME}/job_status
#SCRIPTNAME="run_funfhmmer_in_bchuckle_cluster-SFs."

if [ "$#" -ne 1 ]; then
	echo "ERROR: No script log name has not been passed, received $# arguments";
	exit;
fi

CHECK_TARS_LOG=$1

echo ""
echo "Untarring and checking the result folders:"
echo ""

# Untar result directories and look for empty files
for file in $RESULTS/*.tar.gz ;
do

	SF=`basename $file .tar.gz`
	
	echo "Checking $SF:"
    
	tar -xzf $file -C $RESULTS/
	echo "- Finished extracting $SF"
	 
	for f in $RESULTS/$SF/* $RESULTS/$SF/funfam_alignments/* $RESULTS/$SF/funfam_alignments/analysis_data/* ;
  	do
		
    		if [ ! -s $f ] ; then
			#echo "$f"
   			if [[ ! $f =~ \.stderr$ ]]; then
    				echo "- ERROR in $SF: $f is EMPTY!"
                    echo "$SF: ERROR - $f is EMPTY " >> $CHECK_TARS_LOG
    			fi
		fi
  	done

  	logfile=$RESULTS/$SF/$SF.LOG
  
	if [ -s $logfile ] ; then
		loglastline=`tail -n 1 $logfile`
		array1=($loglastline)
		check_lastline=${array1[-1]}
 		hours=${array1[-2]}
    		
    		if [ $check_lastline == "hours" ] ; then
      			echo "- $SF was COMPLETE ($hours hours)"
                echo "$SF: COMPLETE - $hours hours " >> $CHECK_TARS_LOG
		else
			echo "- ERROR in $SF: $SF is INCOMPLETE"
            echo "$SF: ERROR - $SF is INCOMPLETE " >> $CHECK_TARS_LOG
    		fi
  	fi
done

exit

echo ""
echo "Here are the job status files:"
echo ""

