#!/usr/bin/bash

if [ "$#" -lt 2 ]; then
	echo "Usage:"
    echo ""
    echo "$0 <PROJECTHOME> <SFLISTFILE> <OPTIONAL: AUTOMERGE_LOWEVAL> <OPTIONAL: PROJECTHOME_NAME>"
    echo ""
	echo "ERROR: All required arguments has not been passed, received $# arguments"
	exit;
fi

DIR=$1
SFLISTFILE=$2
AUTOMERGE_LOWEVAL=$3
AUTOMERGE_LOWEVAL=${AUTOMERGE_LOWEVAL:-1}
PROJECT_NAME=$4
PROJECT_NAME=${PROJECT_NAME:-funfhmmer_v4_2_0}

# Get the project directory
if [ ! -d "$DIR" ]; then
        echo "ERROR: Cluster dir '$DIR' does not exist."
        exit;
fi

function print_date {
	date=`date +'%Y/%m/%d %H:%M:%S'`
	echo "[${date}] $1"
}

REMOTE_USER=`whoami`

print_date "REMOTE_USER         $REMOTE_USER"
print_date "FUNFHMMER_DIR       $DIR"
print_date "SFLISTFILE          $SFLISTFILE"
print_date "AUTOMERGE_LOWEVAL   $AUTOMERGE_LOWEVAL"

DATADIR=$DIR/data
APPSDIR=$DIR/apps
RESULTSDIR=$DIR/results
REDO_SUPS=$RESULTSDIR/REDO_SUPS.list

REMOTE_DATA_PATH=/scratch/scratch/${REMOTE_USER}/${PROJECT_NAME}
LOCAL_TMP_DIR=${REMOTE_DATA_PATH}/results/local_run

mkdir -p -v $LOCAL_TMP_DIR

cat $SFLISTFILE | while read superfamily
do
 	if [ -d $DATADIR/$superfamily/ ]; then
        
        echo ""
        echo "Generating FunFams locally for $superfamily here: $LOCAL_TMP_DIR/"
        echo ""
        
        rsync -raz $DATADIR/$superfamily/ $LOCAL_TMP_DIR/$superfamily/
        rsync -raz $DATADIR/$superfamily/starting_cluster_alignments/ $LOCAL_TMP_DIR/$superfamily/funfam_alignments/
        
        perl $APPSDIR/funfhmmer.pl --sup $superfamily --dir $LOCAL_TMP_DIR/$superfamily --groupsim_matrix id --automerge_loweval $AUTOMERGE_LOWEVAL 1> $LOCAL_TMP_DIR/$superfamily/funfhmmer.stdout 2> $LOCAL_TMP_DIR/$superfamily/funfhmmer.stderr
        
        echo "Finished generating FunFams for $superfamily."
        
    fi
done
