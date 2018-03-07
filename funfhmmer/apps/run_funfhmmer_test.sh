#$ -S /bin/bash -t 1-1

# execute job from the current working directory
#$ -cwd

# max runtime
#$ -l h_rt=0:30:0

# memory requirements
#$ -l h_vmem=1G,tmem=1G

# merge the stdout and stderr into one file
#$ -j y

# stdoutput file pathname
#$ -o ../job_status

# Set the FunFHMMer project directory
DIR=/cluster/project8/ff_stability/funfhmmer-2018/funfhmmer
DATADIR=$DIR/data
APPSDIR=$DIR/apps
RESULTSDIR=$DIR/results
SFTREELISTFILE=$DATADIR/superfamilies.gemmatrees.torun.list

superfamily=$(cat $SFTREELISTFILE | head -n $SGE_TASK_ID | tail -n 1 | awk '{printf $1}')
superfamilytree=$(cat $SFTREELISTFILE | head -n $SGE_TASK_ID | tail -n 1 | awk '{printf $2}')
	
time=$(date)

echo "[$time] #Processing  ${superfamily} with ${superfamilytree} TREE.."

perl $APPSDIR/funfhmmer.pl --sup $superfamily --dir $DATADIR/$superfamily/$superfamilytree --groupsim_matrix id

echo "[$time] #JOB COMPLETE for ${superfamily} with ${superfamilytree} TREE."
echo ""