#$ -S /bin/bash

# execute job from the current working directory
#$ -cwd

# merge the stdout and stderr into one file
#$ -j y

# stdout file pathname
#$ -o ../job_status/funfhmmer.job_$JOB_ID.task_$TASK_ID.stdout

# stderr file pathname
#$ -e ../job_status/funfhmmer.job_$JOB_ID.task_$TASK_ID.stderr

#set -x

if [ "$#" -lt 3 ]; then
    echo "Usage:"
    echo ""
    echo "$0 <PROJECTHOME> <SFLISTFILE> <HPC_CLUSTER> <OPTIONAL: AUTOMERGE_LOWEVAL> <OPTIONAL: PROJECTHOME_NAME>"
    echo ""
	echo "ERROR: All required arguments has not been passed, received $# arguments"
	exit;
fi

DIR=$1
SFLISTFILE=$2
HPC_CLUSTER=$3
AUTOMERGE_LOWEVAL=$4
AUTOMERGE_LOWEVAL=${AUTOMERGE_LOWEVAL:-1}
PROJECT_NAME=$5
PROJECT_NAME=${PROJECT_NAME:-funfhmmer_v4_2_0}

# Get the project directory
if [ ! -d "$DIR" ]; then
        echo "ERROR: Cluster dir '$DIR' does not exist for $HOSTNAME $SGE_O_HOST ."
        exit;
fi

function print_date {
	date=`date +'%Y/%m/%d %H:%M:%S'`
	echo "[${date}] $1"
}

echo perl:$(which perl)

REMOTE_USER=`whoami`

print_date "REMOTE_USER         $REMOTE_USER"
print_date "RUN_ENV             $HPC_CLUSTER"
print_date "FUNFHMMER_DIR       $DIR"          
print_date "SFLIST              $SFLISTFILE"
print_date "AUTOMERGE_LOWEVAL   $AUTOMERGE_LOWEVAL"

DATADIR=$DIR/data
APPSDIR=$DIR/apps
RESULTSDIR=$DIR/results
REDO_SUPS=$RESULTSDIR/REDO_SUPS.$JOB_ID.list

superfamily=$(cat $SFLISTFILE | head -n $SGE_TASK_ID | tail -n 1 | awk '{printf $1}')

if [ -z "$superfamily" ]; then
    echo "ERROR: superfamily name is empty!"
    exit;
fi

time=$(date)

echo ""
echo "[$time] #Processing  ${superfamily} .."
echo ""

run_hpc () {

    # create working temp dir
    mkdir -p -v $LOCAL_TMP_DIR
    cd $LOCAL_TMP_DIR

    time=$(date)

    echo ""
    echo "[$time] #Start copying starting clusters of ${superfamily}.."

    #Copy the folder to FFer working dir
    rsync -raz $DATADIR/$superfamily/ $LOCAL_TMP_DIR/$superfamily/

    rsync -raz $DATADIR/$superfamily/starting_cluster_alignments/ $LOCAL_TMP_DIR/$superfamily/funfam_alignments/

    time=$(date)
    echo "[$time] #---DONE"
    echo ""

    time=$(date)
    echo "[$time] #Start generating FunFams"

    perl $APPSDIR/funfhmmer.pl --sup $superfamily --dir $LOCAL_TMP_DIR/$superfamily --groupsim_matrix id 1 --automerge_loweval $AUTOMERGE_LOWEVAL > $LOCAL_TMP_DIR/$superfamily/funfhmmer.stdout 2> $LOCAL_TMP_DIR/$superfamily/funfhmmer.stderr   

            
    # For using --groupsim_matrix mc, that uses Mclaclan matrix,1972 the scoreanalysis subroutine in GSanalysis needs to be written for it. For this, the threshold values of SDP prediction by Groupsim needs to be determined using correlation by plotting groupsim scores calculated using Identity matrix and McLaclan matrix and determing an equivalent threshold.

    SUP_RUN_LOG=$LOCAL_TMP_DIR/$superfamily/$superfamily.LOG

    if grep -Fwq "hours" $SUP_RUN_LOG; then
    
        time=$(date)
        echo "[$time] #Finished generating FunFams.."
    
        rm -r $LOCAL_TMP_DIR/$superfamily/merge_node_alignments/
        rm -r $LOCAL_TMP_DIR/$superfamily/starting_cluster_alignments/
	
        echo ""
        time=$(date)
        echo "[$time] #Copying back generated FunFams for ${superfamily}.."

        #Tar the FunFams from the scratch dir and copy them back to home directory
        SFTREE_FUNFAMS_TAR=$superfamily.tar.gz

        tar -zcf $SFTREE_FUNFAMS_TAR -C $LOCAL_TMP_DIR .
        cp $SFTREE_FUNFAMS_TAR $RESULTSDIR/$superfamily.tar.gz

        echo ""
        time=$(date)
        echo "[$time] #JOB COMPLETE for ${superfamily}."
        echo ""
    
    else
    
        echo
        time=$(date)
        echo "[$time] #FunFam generation was NOT complete for ${superfamily}"
        echo $superfamily >> $REDO_SUPS
        echo ""
    
    fi
}

case "$HPC_CLUSTER" in

# on chuckle cluster
chuckle)
    
    	SCRATCH_DIR=/scratch0/${REMOTE_USER}-funfhmmer
    	LOCAL_TMP_DIR=$SCRATCH_DIR/${JOB_ID}_${SGE_TASK_ID}
    
        run_hpc
        ;;
    
# on legion cluster
legion)
        # path to gemma data in legion scratch dir

        REMOTE_DATA_PATH=/scratch/scratch/${REMOTE_USER}/${PROJECT_NAME}
        LOCAL_TMP_DIR=${REMOTE_DATA_PATH}/results/${JOB_ID}_${SGE_TASK_ID}
    
        run_hpc
        ;;

# on myriad cluster
myriad)

        REMOTE_DATA_PATH=/scratch/scratch/${REMOTE_USER}/${PROJECT_NAME}
    	LOCAL_TMP_DIR=${REMOTE_DATA_PATH}/results/${JOB_ID}_${SGE_TASK_ID}
    
        run_hpc
        ;;

*)
	print_date "Invalid input. Expected chuckle|legion|myriad. Got:$HPC_CLUSTER."
	;;
esac
