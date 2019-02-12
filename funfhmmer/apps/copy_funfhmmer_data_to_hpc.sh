#!/bin/bash

if [ "$#" -lt 2 ]; 
    echo "Usage:"
    echo "$0 <PROJECTHOME> <HPC_CLUSTER> <HPC_PROJECT_NAME>"
    echo ""
	echo "ERROR: Project dir and/or HPC environment (chuckle|legion|myriad) and/or HPC project name has not been passed, received $# arguments";
	exit;
fi

PROJECTHOME=$1
HPC_CLUSTER=$2
PROJECT_NAME=$3
#PROJECT_NAME=${PROJECT_NAME:-funfhmmer_v4_2_0}

# Get the project directory
if [ ! -d "$PROJECTHOME" ]; then
        echo "ERROR: Project dir '$PROJECTHOME' does not exist."
        exit;
fi

function print_date {
	date=`date +'%Y/%m/%d %H:%M:%S'`
	echo "[${date}] $1"
}

print_date "PROJECTHOME       $PROJECTHOME"          
print_date "RUN_ENV           $HPC_CLUSTER"
print_date "PROJECT_NAME      $PROJECT_NAME"

DATADIR=$PROJECTHOME/data
APPSDIR=$PROJECTHOME/apps
RESULTSDIR=$PROJECTHOME/results

REMOTE_USER=`whoami`

copy_hpc () {
    
    REMOTE_LOGIN=${REMOTE_USER}@${REMOTE_HOST}
	REMOTE_DATA_ROOT=${REMOTE_LOGIN}:${REMOTE_DATA_PATH}

	print_date "REMOTE_USER       $REMOTE_USER"      
	print_date "REMOTE_HOST       $REMOTE_HOST"      
	print_date "REMOTE_DATA_ROOT  $REMOTE_DATA_ROOT"          

    print_date "Copying the code: $PROJECTHOME -> $HPC_CLUSTER ($REMOTE_DATA_PATH)"
    
    rsync -av $PROJECTHOME/ $REMOTE_DATA_ROOT/
    
    print_date "Done"

}

case "$HPC_CLUSTER" in

# on chuckle cluster
chuckle)

	REMOTE_DATA_PATH=/home/${PROJECT_NAME}
	REMOTE_HOST=bchuckle.cs.ucl.ac.uk

    #SGE_REQUEST_FLAGS="h_rt=4:0:0,h_vmem=7G,tmem=7G"
	copy_hpc
	;;
    
# on legion cluster
legion)
	# path to gemma data in legion scratch dir

    REMOTE_DATA_PATH=/scratch/scratch/${REMOTE_USER}/${PROJECT_NAME}
	REMOTE_HOST=login05.external.legion.ucl.ac.uk
    
	#SGE_REQUEST_FLAGS="h_rt=2:0:0,h_vmem=7G"
	copy_hpc
	;;

# on myriad cluster
myriad)

	REMOTE_DATA_PATH=/scratch/scratch/${REMOTE_USER}/${PROJECT_NAME}
	REMOTE_HOST=myriad.rc.ucl.ac.uk
        
	#SGE_REQUEST_FLAGS="h_rt=2:0:0,mem=7G"
	copy_hpc
	;;

*)
	print_date "Invalid input. Expected chuckle|legion|myriad. Got:$HPC_CLUSTER."
	;;
esac