#!/bin/bash

# Set the FunFHMMer project directory
DIR=${PROJECTHOME}
DATADIR=$DIR/data
APPSDIR=$DIR/apps

if [ "$#" -ne 1 ]; then
	echo "ERROR: Superfamily List to run has not been passed, received $# arguments";
	exit;
fi

SFLISTFILE=$1

LOGFILE=$DATADIR/copyingSFdata.rsynclogfile

if [ ! -s $SFLISTFILE ] ; then
	echo "ERROR: $SFLISTFILE does not exist or is empty."
	echo ""
	exit;
fi

if [ -f $LOGFILE ] ; then
	rm $LOGFILE
fi

echo "# Copying GEMMA data for the list of superfamilies ($SFLISTFILE) to data/.."

cat $SFLISTFILE | while read superfamilyline
do
	stringarray=($superfamilyline)
	superfamily=${stringarray[0]}
	GEMMADIR=${stringarray[1]}
	
 	if [ ! -z $superfamily ]; then
 	
 		mkdir -p "$DATADIR/$superfamily"
 		
 		if [ -d $GEMMADIR/ ]; then
 		
			rsync -av $GEMMADIR/ $DATADIR/$superfamily/ >> $LOGFILE
			
			echo "# $superfamily copied."
	
		else
		
			echo "# ERROR: $GEMMADIR directory does not exist."
			echo ""
		fi
 	else
		
		echo "# ERROR: $SFLISTFILE has no superfamily name."
		echo ""
 	fi
done


if [ -s $SFLISTFILE ] ; then
	
	echo "# Done."
	fileinfo=$(wc $SFLISTFILE)
    #echo "$fileinfo"
	JOBS=$(echo $fileinfo | cut -d' ' -f1)
	echo ""
	echo "#** JOBNUM=$JOBS **"
	echo ""
				
	else
		echo "$SFLISTFILE is empty!"
	fi




