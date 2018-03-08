#!/bin/bash

# Set the FunFHMMer project directory
DIR=${PROJECTHOME}
DATADIR=$DIR/data
APPSDIR=$DIR/apps
SFLISTFILE=$DATADIR/superfamilies.torun.list
LOGFILE=$DATADIR/copyingSFdata.rsynclogfile
SFTREELISTFILE=$DATADIR/superfamilies.gemmatrees.torun.list

# Make sure that the list of the superfamilies to be run is in the data folder 

echo ""

echo "1. Copying GEMMA data for the list of superfamilies to data/ .."

if [ -f $SFTREELISTFILE ] ; then
	rm $SFTREELISTFILE
fi

#cd $GEMMADATA

cat $SFLISTFILE | while read superfamilyline
do
	#echo "$superfamilyline"
	stringarray=($superfamilyline)
	superfamily=${stringarray[0]}
	GEMMADIR=${stringarray[1]}
	
	#echo "${superfamily}"
	#echo "${GEMMADIR}"
	
 	if [[ $superfamily =~ ^[0-9.*] ]]; then
 		mkdir -p "$DATADIR/$superfamily"
 		rsync -arv $GEMMADIR/$superfamily/ $DATADIR/$superfamily/ >> $LOGFILE
 		for superfamilytree in $(find $DATADIR/$superfamily/ -mindepth 1 -maxdepth 1 -type d)
 		do
 			superfamilytree_name=$(basename ${superfamilytree})
 			#rsync -arv $DATADIR/$superfamily/$superfamilytree_name/starting_cluster_alignments/ $DATADIR/$superfamily/$superfamilytree_name/funfam_alignments/ >> $LOGFILE
 			mv $DATADIR/$superfamily/$superfamilytree_name/starting_cluster_alignments/ $DATADIR/$superfamily/$superfamilytree_name/funfam_alignments/
 			echo "${superfamily} ${superfamilytree_name}" >> $SFTREELISTFILE
 		done
 	fi
done

echo "2. Done."

fileinfo=$(wc $SFTREELISTFILE)
JOBS=$(echo $fileinfo|cut -d' ' -f1)
echo ""
echo "** JOBNUM=$JOBS **"
echo ""
