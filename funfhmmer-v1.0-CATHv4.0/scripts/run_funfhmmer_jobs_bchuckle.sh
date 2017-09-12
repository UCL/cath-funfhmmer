#$ -S /bin/bash -t 1-<n>
# Told the SGE that this is an array job, with "tasks" to be numbered 1 to n (one for each SF)

# execute job from the current working directory (i.e. submission dir)
#$ -cwd

# max runtime
#$ -l h_rt=12:0:0

# memory requirements
#$ -l h_vmem=4G,tmem=4G

# merge the stdout and stderr into one file
#$ -j y

# stdoutput file pathname
#$ -o <path to job status folder>

# data folders
projectdir=<path to project dir>
startingclustersdir=$projectdir/sf_starting_clusters
sflist=$projectdir/bin/SF_list_Evalues.list
sf_starting_clusters_tar_filename=$startingclustersdir/sf_to_run_starting_clusters.tar.gz

sf=$(cat $sflist | head -n $SGE_TASK_ID | tail -n 1 | awk '{printf $1}')
q1=$(cat $sflist | head -n $SGE_TASK_ID | tail -n 1 | awk '{printf $2}')
q3=$(cat $sflist | head -n $SGE_TASK_ID | tail -n 1 | awk '{printf $3}')

time=$(date)

echo "[$time] #Processing $sf with Evalue thresholds- $q1(Q1) and $q3(Q3)"

# create working temp dir
SCRATCH_DIR=/scratch0/ucbtdas
LOCAL_TMP_DIR=$SCRATCH_DIR/${JOB_ID}_${SGE_TASK_ID}
echo
echo "Creating working tmp directory ${LOCAL_TMP_DIR}..."
mkdir -p -v $LOCAL_TMP_DIR
cd $LOCAL_TMP_DIR
echo "DONE"
echo
echo " -- Start copying starting clusters of $sf"

#Untar SF starting cluster folder to the same folder
cd $startingclustersdir
tar -zxf $sf_starting_clusters_tar_filename ./$sf -C $startingclustersdir
cd $projectdir/bin

# Set scratch dir to funfamdir
funfamdir=$LOCAL_TMP_DIR

#Copy the folder to FFer working dir
rsync -raz $startingclustersdir/$sf/ $LOCAL_TMP_DIR/$sf/

#Remove the untarred folder
rm -r $startingclustersdir/$sf

echo " -- Finished copying starting clusters of $sf"

perl $projectdir/bin/run_funfhmmer_scripts_for_a_sf_bchuckle.pl $projectdir $sf $q1 $q3 $funfamdir

#Tar the FunFams from the scratch dir and copy them back to home directory
tar -zcvf $sf.tar.gz -C $funfamdir/$sf .
cp $sf.tar.gz $projectdir/sf_funfams/$sf.tar.gz

rm -r $projectdir/bin/*.tar.gz

echo
echo "***Finished copying Results of FFer on $sf***"
