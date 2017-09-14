#$ -S /bin/bash -t 1-123
# Told the SGE that this is an array job, with "tasks" to be numbered 1 to n (one for each job)

# execute job from the current working directory (i.e. submission dir)
#$ -cwd

# max runtime
#$ -l h_rt=12:0:0

# memory requirements
#$ -l h_vmem=4G,tmem=4G

# merge the stdout and stderr into one file
#$ -j y

# stdoutput file pathname
#$ -o /home/ucbtdas/GeMMA_benchmarking/FFer_standalone_TL_bchuckle/job_status

# Set the FunFHMMer project directory
DIR=/home/ucbtdas/GeMMA_benchmarking/funfhmmer_standalone
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
rsync -raz $DATADIR/$superfamily/$superfamilytree/ $LOCAL_TMP_DIR/$superfamily.$superfamilytree/

echo "[$time] #---DONE"

perl $APPSDIR/funfhmmer.pl --sup $superfamily --dir $LOCAL_TMP_DIR/$superfamily.$superfamilytree

echo "[$time] #Copying FunFams for ${superfamily} with ${superfamilytree} TREE.."

#Tar the FunFams from the scratch dir and copy them back to home directory
SFTREE_FUNFAMS_TAR=$superfamily.$superfamilytree.tar.gz

tar -zcf $SFTREE_FUNFAMS_TAR -C $LOCAL_TMP_DIR .
cp $SFTREE_FUNFAMS_TAR $RESULTSDIR/$superfamily.$superfamilytree.tar.gz

echo "[$time] #JOB COMPLETE for ${superfamily} with ${superfamilytree} TREE."