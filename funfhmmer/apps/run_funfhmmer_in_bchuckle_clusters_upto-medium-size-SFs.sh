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
if [ -d $DIR ]; then
        echo "ERROR: Cluster '$DIR' dir does not exist."
        exit;
fi

DATADIR=$DIR/data
APPSDIR=$DIR/apps
RESULTSDIR=$DIR/results

SFTREELISTFILE=$DATADIR/superfamilies.gemmatrees.torun.list

superfamily=$(cat $SFTREELISTFILE | head -n $SGE_TASK_ID | tail -n 1 | awk '{printf $1}')
superfamilytree=$(cat $SFTREELISTFILE | head -n $SGE_TASK_ID | tail -n 1 | awk '{printf $2}')
	
time=$(date)

echo "[$time] #Processing  ${superfamily} with ${superfamilytree} TREE.."
			
# create working temp dir
SCRATCH_DIR=/scratch0/ucbtdas
LOCAL_TMP_DIR=$SCRATCH_DIR/${JOB_ID}_${SGE_TASK_ID}

mkdir -p -v $LOCAL_TMP_DIR
	
cd $LOCAL_TMP_DIR

echo "[$time] #Start copying starting clusters of ${superfamily} with ${superfamilytree} TREE.."

#Copy the folder to FFer working dir
rsync -raz $DATADIR/$superfamily/$superfamilytree/ $LOCAL_TMP_DIR/$superfamily/

echo "[$time] #---DONE"

perl $APPSDIR/funfhmmer.pl --sup $superfamily --dir $LOCAL_TMP_DIR/$superfamily --groupsim_matrix id

rm -r $LOCAL_TMP_DIR/$superfamily/merge_node_alignments/

echo "[$time] #Copying FunFams for ${superfamily} with ${superfamilytree} TREE.."

#Tar the FunFams from the scratch dir and copy them back to home directory
SFTREE_FUNFAMS_TAR=$superfamily.tar.gz

tar -zcf $SFTREE_FUNFAMS_TAR -C $LOCAL_TMP_DIR .
cp $SFTREE_FUNFAMS_TAR $RESULTSDIR/$superfamily.tar.gz

echo "[$time] #JOB COMPLETE for ${superfamily} with ${superfamilytree} TREE."
echo ""
