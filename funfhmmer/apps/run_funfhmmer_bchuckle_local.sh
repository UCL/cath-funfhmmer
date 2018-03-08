#!/bin/bash

# Set the FunFHMMer project directory
DIR=${BCHUCKLE_DIR}/funfhmmer
DATADIR=$DIR/data
APPSDIR=$DIR/apps
RESULTSDIR=$DIR/results
SFTREELISTFILE=$DATADIR/superfamilies.gemmatrees.torun.list


cat $SFTREELISTFILE | while read line
do
	#echo "$superfamilyline"
	stringarray=($line)
	superfamily=${stringarray[0]}
	superfamilytree=${stringarray[1]}
	
	time=$(date)

	echo "[$time] #Runnning  ${superfamily} with ${superfamilytree} TREE.."

	perl $APPSDIR/funfhmmer.pl --sup $superfamily --dir $DATADIR/$superfamily/$superfamilytree --groupsim_matrix id
	
	time=$(date)

	echo "[$time] #JOB COMPLETE for ${superfamily} with ${superfamilytree} TREE."
done