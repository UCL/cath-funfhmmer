#$ -S /bin/bash

# execute job from the current working directory
#$ -cwd

# max runtime
#$ -l h_rt=1:0:0

# memory requirements
#$ -l h_vmem=1G,tmem=1G

# merge the stdout and stderr into one file
#$ -j y

# stdoutput file pathname
#$ -o ../job_status


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
echo "[$time] #Processing  ${superfamily} with ${superfamilytree} TREE.."
echo ""

# create working temp dir
SCRATCH_DIR=/scratch0/ucbtdas
LOCAL_TMP_DIR=$SCRATCH_DIR/${JOB_ID}_${SGE_TASK_ID}

mkdir -p -v $LOCAL_TMP_DIR
	
cd $LOCAL_TMP_DIR

echo ""
echo "[$time] #Start copying starting clusters of ${superfamily}.."

#Copy the folder to FFer working dir
rsync -raz $DATADIR/$superfamily/ $LOCAL_TMP_DIR/$superfamily/

echo "[$time] #---DONE"
echo ""

perl $APPSDIR/funfhmmer.pl --sup $superfamily --dir $LOCAL_TMP_DIR/$superfamily --groupsim_matrix id

rm -r $LOCAL_TMP_DIR/$superfamily/merge_node_alignments/

echo ""
echo "[$time] #Copying back generated FunFams for ${superfamily}.."

#Tar the FunFams from the scratch dir and copy them back to home directory
SFTREE_FUNFAMS_TAR=$superfamily.tar.gz

tar -zcf $SFTREE_FUNFAMS_TAR -C $LOCAL_TMP_DIR .
cp $SFTREE_FUNFAMS_TAR $RESULTSDIR/$superfamily.tar.gz

echo ""
echo "[$time] #JOB COMPLETE for ${superfamily}."
echo ""
