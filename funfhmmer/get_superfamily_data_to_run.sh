#!/bin/bash

# Set the FunFHMMer project directory
DIR=${PROJECTHOME}
DATADIR=$DIR/data
APPSDIR=$DIR/apps
SFLISTFILE=$DATADIR/superfamilies.torun.list
STARTINGCLUSTERLISTDIR=$DATADIR/starting_cluster_lists
STARTINGCLUSTERDATA=/cath/people2/ucbctnl/GeMMA/v4_0_0/starting_clusters
GEMMADATA=/cath/people2/ucbctnl/GeMMA/bchuckle_trees
LOGFILE=$DATADIR/copyingSFdata.rsynclogfile
SFTREELISTFILE=$DATADIR/superfamilies.gemmatrees.torun.list

# Make sure that the list of the superfamilies to be run is in the data folder 

echo ""
echo "1. Start Pre-processing superfamily data before running FFer in Bchuckle.."

echo "2. Getting list of superfamilies in the DATA folder.."

# Copy the list of the superfamily tree.trace to the data folder 
# copy the starting clusters from the starting cluster folder to each tree folder
# Get the tree dir list of all the superfamilies to be run 

echo "3. Getting superfamily data ready for running FFer in DATA folder.."

if [ -f $SFTREELISTFILE ] ; then
	rm $SFTREELISTFILE
fi

cd $GEMMADATA

cat $SFLISTFILE | while read superfamily

do
	if [[ $superfamily =~ ^[0-9.*] ]]; then
		mkdir -p "$DATADIR/$superfamily"
		rsync -arv --exclude '*.faa' $superfamily/ $DATADIR/$superfamily/ >> $LOGFILE
		for superfamilytree in $(find $DATADIR/$superfamily/ -mindepth 1 -maxdepth 1 -type d)
		do
			rsync -arv $STARTINGCLUSTERDATA/$superfamily/*.faa ${superfamilytree} >> $LOGFILE
			superfamilytree_name=$(basename ${superfamilytree})
			echo "${superfamily} ${superfamilytree_name}" >> $SFTREELISTFILE
			
		done
	fi
done

echo "4. Done."

fileinfo=$(wc $SFTREELISTFILE)
JOBNUM=$(echo $fileinfo|cut -d' ' -f1)
echo ""
echo "** JOBNUM=$JOBNUM jobs need to be run**"
export HPC_JOBNUM=${JOBNUM}
echo ""