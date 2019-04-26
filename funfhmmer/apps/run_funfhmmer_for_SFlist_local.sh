#!/usr/bin/bash

if [ "$#" -lt 3 ]; then
	echo "USAGE:"
    echo ""
    echo "bash $0 --projecthome=<PROJECTHOME> --projectlist=<PROJECT_LIST> --automerge=<0/1>"
    echo ""
    echo "Optional:"
    echo "         --tracedir=<TREEDIR (default:2nd col. of PROJECT_LIST)>"
    echo "         --ffdir=<LOCAL_FF_DIR (default:PROJECTHOME/local_run)>"
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
        --automerge=*)
        AUTOMERGE_LOWEVAL="${i#*=}"
        shift
        ;;
        --tracedir=*)
        TRACEDIR="${i#*=}"
        shift
        ;;
        --ffdir=*)
        LOCAL_FF_DIR="${i#*=}"
        shift
        ;;
        *)
        
        ;;
    esac
done

# use default values of LOCAL_FF_DIR if nothing is provided

LOCAL_FF_DIR=${LOCAL_FF_DIR:-$PROJECTHOME/local_run}

# Get the project directory
if [ ! -d "$DIR" ]; then
        echo "ERROR: dir '$DIR' does not exist."
        exit;
fi

# Check RESULTDIR directory

if [ ! -d "$LOCAL_FF_DIR" ]; then
        echo ""
        echo "'$LOCAL_FF_DIR' does not exist."
        mkdir -p $LOCAL_FF_DIR || die "mkdir failed for $LOCAL_FF_DIR"
        echo "LOCAL_FF_DIR '$LOCAL_FF_DIR' created."
        echo ""
fi


function print_date {
	date=`date +'%Y/%m/%d %H:%M:%S'`
	echo "[${date}] $1"
}

REMOTE_USER=`whoami`

print_date "USER                        $REMOTE_USER"
print_date "FUNFHMMER_DIR               $DIR"
print_date "PROJECT_LIST_FILE           $SFLISTFILE"
print_date "LOCAL_FF_DIR                $LOCAL_FF_DIR"
print_date "AUTOMERGE_LOWEVAL           $AUTOMERGE_LOWEVAL"

if [ -z "$TRACEDIR" ]
then
    print_date "TRACEDIR                    2nd col. in $SFLISTFILE"
else
    print_date "TRACEDIR                    $TRACEDIR"
fi

APPSDIR=$DIR/apps
REDO_SUPS=$TRACEDIR/REDO_SUPS.list

cat $SFLISTFILE | while read superfamilyline
do

	stringarray=($superfamilyline)
	superfamily=${stringarray[0]}
	GEMMADIR=${stringarray[1]}

    if [ -z "$TRACEDIR" ]
    then
        SF_DATA_DIR=$GEMMADIR
    else
        SF_DATA_DIR=$TRACEDIR/$superfamily/simple_ordering.hhconsensus.windowed
    fi

 	if [ -d $SF_DATA_DIR ]; then

	        echo ""
        	echo "Generating FunFams locally for $superfamily:"
        	echo ""

            echo "-- PROJECT_DATA_DIR            $SF_DATA_DIR"
            echo "-- PROJECT_RESULT_DIR          $LOCAL_FF_DIR/$superfamily/"

        	rsync -raz $SF_DATA_DIR/ $LOCAL_FF_DIR/$superfamily/
        	rsync -raz $SF_DATA_DIR/starting_cluster_alignments/ $LOCAL_FF_DIR/$superfamily/funfam_alignments/

        	perl $APPSDIR/funfhmmer.pl --sup $superfamily --dir $LOCAL_FF_DIR/$superfamily --groupsim_matrix id --automerge_loweval $AUTOMERGE_LOWEVAL 1> $LOCAL_FF_DIR/$superfamily/funfhmmer.stdout 2> $LOCAL_FF_DIR/$superfamily/funfhmmer.stderr

        	echo "-- Finished generating FunFams for $superfamily."
            echo ""
            echo ""

            #exit 0;

    	fi
done
