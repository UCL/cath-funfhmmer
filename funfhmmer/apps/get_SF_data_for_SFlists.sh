#!/bin/bash

# Set the FunFHMMer project directory
DIR=${PROJECTHOME}
APPSDIR=$DIR/apps

if [ "$#" -lt 1 ]; then
    echo ""
    echo "USAGE: bash $0 <SFLIST_FILE> <optional: DATADIR (default: PROJECTHOME/data)>"
    echo ""
	echo "ERROR: Superfamily List (and optinal DATADIR) has not been passed, received $# arguments";
	exit;
fi

SFLISTFILE=$1
DATADIR=$2
DATADIR=${DATADIR:-$DIR/data}

LOGFILE=$DATADIR/copyingSFdata.rsynclogfile

if [ ! -s $SFLISTFILE ] ; then
	echo "ERROR: $SFLISTFILE does not exist or is empty."
	echo ""
	exit;
fi

echo ""
echo "SFLIST        $SFLISTFILE"
echo "DATADIR       $DATADIR"
echo ""

if [ -f $LOGFILE ] ; then
	rm $LOGFILE
fi

echo "# Copying GEMMA data for the list of superfamilies ($SFLISTFILE) to DATADIR .."

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




