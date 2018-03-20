#!/bin/bash

# Set the FunFHMMer project directory
DIR=${PROJECTHOME}
DATADIR=$DIR/data
APPSDIR=$DIR/apps
SFLISTFILE=$DATADIR/superfamilies.torun.list
LOGFILE=$DATADIR/copyingSFdata.rsynclogfile
SFTREELISTFILE=$DATADIR/superfamilies.list

echo ""

if [ ! -s $SFLISTFILE ] ; then
	echo "ERROR: $SFLISTFILE does not exist or is empty."
	echo ""
	exit;
fi

if [ -f $SFTREELISTFILE ] ; then
	rm $SFTREELISTFILE
fi

echo "# Copying GEMMA data for the list of superfamilies to data/ .."

cat $SFLISTFILE | while read superfamilyline
do
	stringarray=($superfamilyline)
	superfamily=${stringarray[0]}
	GEMMADIR=${stringarray[1]}
	
 	if [ ! -z $superfamily ]; then
 	
 		mkdir -p "$DATADIR/$superfamily"
 		
 		if [ -d $GEMMADIR/$superfamily/ ]; then
 		
			rsync -arv $GEMMADIR/$superfamily/ $DATADIR/$superfamily/ >> $LOGFILE
			
			echo "# $superfamily copied."
				
			echo "${superfamily}" >> $SFTREELISTFILE
	
		else
		
			echo "# ERROR: $GEMMADIR/$superfamily/ directory does not exist."
			echo ""
		fi
 	else
		
		echo "# ERROR: $SFLISTFILE has no superfamily name."
		echo ""
 	fi
done


if [ -s $SFTREELISTFILE ] ; then
	
	echo "# Done."
	fileinfo=$(wc $SFTREELISTFILE)
	JOBS=$(echo $fileinfo|cut -d' ' -f1)
	echo ""
	echo "#** JOBNUM=$JOBS **"
	echo ""
				
	else
		echo "$SFTREELISTFILE is empty!"
	fi




