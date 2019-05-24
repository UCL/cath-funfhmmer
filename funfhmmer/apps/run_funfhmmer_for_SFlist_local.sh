#!/usr/bin/bash

if [ "$#" -lt 2 ]; then
	echo "Usage:"
    echo ""
    echo "$0 <PROJECTHOME> <SFLISTFILE> <OPTIONAL: AUTOMERGE_LOWEVAL (default:1)>"
    echo ""
    echo "Use AUTOMERGE_LOWEVAL=1 for 1st iteration of FunFHMMer and for other iterations, use 0"
    echo ""
	echo "ERROR: All required arguments has not been passed, received $# arguments"
	exit;
fi

DIR=$1
SFLISTFILE=$2
AUTOMERGE_LOWEVAL=$3
AUTOMERGE_LOWEVAL=${AUTOMERGE_LOWEVAL:-1}

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

print_date "USER                $REMOTE_USER"
print_date "FUNFHMMER_DIR       $DIR"
print_date "SFLISTFILE          $SFLISTFILE"
print_date "AUTOMERGE_LOWEVAL   $AUTOMERGE_LOWEVAL"

DATADIR=$DIR/data
APPSDIR=$DIR/apps
RESULTSDIR=$DIR/results
REDO_SUPS=$RESULTSDIR/REDO_SUPS.list

LOCAL_TMP_DIR=$DIR/results

mkdir -p -v $LOCAL_TMP_DIR

cat $SFLISTFILE | while read superfamilyline
do
	
	stringarray=($superfamilyline)
	superfamily=${stringarray[0]}
	GEMMADIR=${stringarray[1]}

	SF_DATA_DIR=$DATADIR/$superfamily

	echo "$SF_DATA_DIR"
	
 	if [ -d $SF_DATA_DIR ]; then
        
	        echo ""
        	echo "Generating FunFams locally for $superfamily here: $LOCAL_TMP_DIR/"
        	echo ""
        
        	rsync -raz $SF_DATA_DIR/ $LOCAL_TMP_DIR/$superfamily/
        	rsync -raz $SF_DATA_DIR/starting_cluster_alignments/ $LOCAL_TMP_DIR/$superfamily/funfam_alignments/
        
        	perl $APPSDIR/funfhmmer.pl --sup $superfamily --dir $LOCAL_TMP_DIR/$superfamily --groupsim_matrix id --automerge_loweval $AUTOMERGE_LOWEVAL 1> $LOCAL_TMP_DIR/$superfamily/funfhmmer.stdout 2> $LOCAL_TMP_DIR/$superfamily/funfhmmer.stderr
        
        	echo "Finished generating FunFams for $superfamily."
	
    	fi
done
