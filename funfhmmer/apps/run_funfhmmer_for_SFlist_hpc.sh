#$ -S /bin/bash

# execute job from the current working directory
#$ -cwd

# merge the stdout and stderr into one file
#$ -j y

# stdout file pathname
#$ -o ../funfhmmer.job_$JOB_ID.task_$TASK_ID.stdout

# stderr file pathname
#$ -e ../funfhmmer.job_$JOB_ID.task_$TASK_ID.stderr

#set -x

if [ "$#" -lt 5 ]; then
	echo "USAGE:"
    echo ""
    echo "bash $0 --projecthome=<PROJECT_HOME> --projectlist=<PROJECT_LIST> --hpc=<HPC_CLUSTER> --projectname=<PROJECT_NAME> --automerge=<0/1>"
    echo ""
    echo "Optional:"
    echo "         --tracedir=<TREEDIR (default: 2nd col. of PROJECT_LIST)>"
    echo "         --ffdir=<FF_DIR (default:PROJECT_HOME/results)>"
    echo ""
    echo "NOTE: Use AUTOMERGE_LOWEVAL=1 for 1st iteration of FunFHMMer and for other iterations, use 0"
    echo ""
	echo "ERROR: All required arguments has not been passed, received $# arguments"
    echo ""
	exit;
fi

for i in "$@"
do
    case $i in
        --projecthome=*)
        DIR="${i#*=}"
        shift
        ;;
        --projectlist=*)
        SFLISTFILE="${i#*=}"
        shift
        ;;
        --hpc=*)
        HPC_CLUSTER="${i#*=}"
        shift
        ;;
        --projectname=*)
        PROJECT_NAME="${i#*=}"
        shift
        ;;
        --automerge=*)
        AUTOMERGE_LOWEVAL="${i#*=}"
        shift
        ;;
        --tracedir=*)
        TRACEDIR="${i#*=}"
        shift
        ;;
        --ffdir=*)
        FFDIR="${i#*=}"
        shift
        ;;
        *)
        
        ;;
    esac
done

# use default values of FF_DIR is nothing is provided
FFDIR=${FFDIR:-$DIR/results}

# Get the project directory
if [ ! -d "$DIR" ]; then
        echo ""
        echo "ERROR: '$DIR' does not exist for $HOSTNAME $SGE_O_HOST ."
        echo ""
        exit;
fi

if [ ! -d "$FFDIR" ]; then
        echo ""
        echo "'$FFDIR' does not exist."
        mkdir -p $FFDIR || die "mkdir failed for $FFDIR"
        echo "FFDIR '$FFDIR' created."
        echo ""
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
print_date "PROJECT_NAME	$PROJECT_NAME"
print_date "SFLIST              $SFLISTFILE"
print_date "FFDIR               $FFDIR"
print_date "AUTOMERGE_LOWEVAL   $AUTOMERGE_LOWEVAL"

if [ -z "$TRACEDIR" ]
then
    print_date "TRACEDIR                    2nd col. in $SFLISTFILE"
else
    print_date "TRACEDIR                    $TRACEDIR"
fi

APPSDIR=$DIR/apps
REDO_SUPS=$FFDIR/REDO_SUPS.$JOB_ID.list

superfamily=$(cat $SFLISTFILE | head -n $SGE_TASK_ID | tail -n 1 | awk '{printf $1}')
GEMMADIR=$(cat $SFLISTFILE | head -n $SGE_TASK_ID | tail -n 1 | awk '{printf $2}')

if [ -z "$superfamily" ]; then
    echo ""
    echo "ERROR: superfamily name is empty!"
    echo ""
    exit;
fi

if [ -z "$TRACEDIR" ]
then
    SF_DATA_DIR=$GEMMADIR
else
    SF_DATA_DIR=$TRACEDIR/$superfamily/simple_ordering.hhconsensus.windowed
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
    rsync -raz $SF_DATA_DIR/ $LOCAL_TMP_DIR/$superfamily/

    rsync -raz $SF_DATA_DIR/starting_cluster_alignments/ $LOCAL_TMP_DIR/$superfamily/funfam_alignments/

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
        cp $SFTREE_FUNFAMS_TAR $FFDIR/$superfamily.tar.gz

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

# on pchuckle cluster
pchuckle)

    	LOCAL_TMP_DIR=${FFDIR}/temp/${superfamily}_${JOB_ID}_${SGE_TASK_ID}

        run_hpc
        ;;

# on legion cluster
legion)
        # path to gemma data in legion scratch dir

        LOCAL_TMP_DIR=${FFDIR}/temp/${superfamily}_${JOB_ID}_${SGE_TASK_ID}

        run_hpc
        ;;

# on myriad cluster
myriad)

    	LOCAL_TMP_DIR=${FFDIR}/temp/${superfamily}_${JOB_ID}_${SGE_TASK_ID}

        run_hpc
        ;;

*)
	print_date "Invalid input. Expected pchuckle|legion|myriad. Got:$HPC_CLUSTER."
	;;
esac
