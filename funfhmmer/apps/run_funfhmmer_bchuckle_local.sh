#!/bin/bash

# Set the FunFHMMer project directory
DIR=${BCHUCKLE_DIR}/funfhmmer
DATADIR=$DIR/data
APPSDIR=$DIR/apps
RESULTSDIR=$DIR/results
SFTREELISTFILE=$DATADIR/superfamilies.list


cat $SFTREELISTFILE | while read superfamily
do
	#echo "$superfamily"
	
	time=$(date)
	
	#Copy the folder to FFer working dir

	rsync -rav $DATADIR/$superfamily/starting_cluster_alignments/ $DATADIR/$superfamily/funfam_alignments/

	echo "[$time] #Processing  ${superfamily}.."

	perl $APPSDIR/funfhmmer.pl --sup $superfamily --dir $DATADIR/$superfamily --groupsim_matrix id
	
	# funfhmmer.pl Usage:

	#funfhmmer.pl --sup <CATH_superfamily_code> --dir <CATH_superfamily_dir> --groupsim_matrix <id/mc>

	#Options:
	#--groupsim-matrix	id	Identity matrix
	#			mc	Mclachlan matrix (Chemical similarity)
	
	# --groupsim_matrix id means using identity matrix for calculating the groupsim scores. Using Identity matrix, the Groupsim scores are within the range 0-1 where we use scores >=0.7 as a threshold of predicting SDPs.
	
	# For using --groupsim_matrix mc, that uses Mclaclan matrix,1972 the scoreanalysis subroutine in GSanalysis needs to be written for it. For this, the threshold values of SDP prediction by Groupsim needs to be determined using correlation by plotting groupsim scores calculated using Identity matrix and McLaclan matrix and determing an equivalent threshold.
	
	
	#rm -r $DATADIR/$superfamily/merge_node_alignments/
	#rm -r $DATADIR/$superfamily/starting_cluster_alignments/
	
	time=$(date)

	echo "[$time] #JOB COMPLETE for ${superfamily}."
done