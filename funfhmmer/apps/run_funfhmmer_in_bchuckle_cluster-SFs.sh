#$ -S /bin/bash

# execute job from the current working directory
#$ -cwd

# max runtime
#$ -l h_rt=1:0:0

# memory requirements
#$ -l h_vmem=1G,tmem=1G

# merge the stdout and stderr into one file
#$ -j y

# stdout file pathname
#$ -o ../job_status/run_funfhmmer_in_bchuckle_cluster-SFs.job_$JOB_ID.task_$TASK_ID.stdout

# stderr file pathname
#$ -e ../job_status/run_funfhmmer_in_bchuckle_cluster-SFs.job_$JOB_ID.task_$TASK_ID.stderr


if [ "$#" -ne 1 ]; then
	echo "ERROR: Cluster dirname has not been passed, received $# arguments";
	exit;
fi

DIR=$1


# Get the project directory
if [ ! -d "$DIR" ]; then
        echo "ERROR: Cluster dir '$DIR' does not exist for $HOSTNAME $SGE_O_HOST ."
        exit;
fi

DATADIR=$DIR/data
APPSDIR=$DIR/apps
RESULTSDIR=$DIR/results

SFTREELISTFILE=$DATADIR/superfamilies.list

superfamily=$(cat $SFTREELISTFILE | head -n $SGE_TASK_ID | tail -n 1 | awk '{printf $1}')
	
time=$(date)

echo ""
echo "[$time] #Processing  ${superfamily} .."
echo ""

# create working temp dir
SCRATCH_DIR=/scratch0/`whoami`-funfhmmer
LOCAL_TMP_DIR=$SCRATCH_DIR/${JOB_ID}_${SGE_TASK_ID}

mkdir -p -v $LOCAL_TMP_DIR
	
cd $LOCAL_TMP_DIR

echo ""
echo "[$time] #Start copying starting clusters of ${superfamily}.."

#Copy the folder to FFer working dir
rsync -raz $DATADIR/$superfamily/ $LOCAL_TMP_DIR/$superfamily/

rsync -raz $DATADIR/$superfamily/starting_cluster_alignments/ $LOCAL_TMP_DIR/$superfamily/funfam_alignments/

echo "[$time] #---DONE"
echo ""

perl $APPSDIR/funfhmmer.pl --sup $superfamily --dir $LOCAL_TMP_DIR/$superfamily --groupsim_matrix id

# funfhmmer.pl Usage:

	#funfhmmer.pl --sup <CATH_superfamily_code> --dir <CATH_superfamily_dir> --groupsim_matrix <id/mc>

	#Options:
	#--groupsim-matrix	id	Identity matrix
	#			mc	Mclachlan matrix (Chemical similarity)
	
# --groupsim_matrix id means using identity matrix for calculating the groupsim scores. Using Identity matrix, the Groupsim scores are within the range 0-1 where we use scores >=0.7 as a threshold of predicting SDPs.
	
# For using --groupsim_matrix mc, that uses Mclaclan matrix,1972 the scoreanalysis subroutine in GSanalysis needs to be written for it. For this, the threshold values of SDP prediction by Groupsim needs to be determined using correlation by plotting groupsim scores calculated using Identity matrix and McLaclan matrix and determing an equivalent threshold.

rm -r $LOCAL_TMP_DIR/$superfamily/merge_node_alignments/
rm -r $LOCAL_TMP_DIR/$superfamily/starting_cluster_alignments/

echo ""
echo "[$time] #Copying back generated FunFams for ${superfamily}.."

#Tar the FunFams from the scratch dir and copy them back to home directory
SFTREE_FUNFAMS_TAR=$superfamily.tar.gz

tar -zcf $SFTREE_FUNFAMS_TAR -C $LOCAL_TMP_DIR .
cp $SFTREE_FUNFAMS_TAR $RESULTSDIR/$superfamily.tar.gz

echo ""
echo "[$time] #JOB COMPLETE for ${superfamily}."
echo ""
