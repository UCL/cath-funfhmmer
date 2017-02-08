Running FunFHMMer on the CS bchuckle cluster
======

1.Go to working directory

~~~~~
cd /cath/people2/ucbtdas/generate_FunFams_test/
~~~~~

2.Copy over base directory containing scripts and programs required for generating FunFams using FunFHMMer 

~~~~~
rsync -av /cath/homes2/ucbtdas/Working/eclipse_workspace/FunFHMMer_code/github_resources/scripts/ /cath/people2/ucbtdas/generate_FunFams_test/scripts/
~~~~~

3.Make a folder 'sf_starting_clusters' in the working directory

~~~~~
mkdir starting_clusters
~~~~~

4.Copy superfamily trace files and starting clusters for each superfamily on which FunFHMMer has to be run in separate folders inside 'sf_starting_clusters' 

  (i) TPP superfamily (functionally diverse superfamily)
~~~~~
rsync -av /cath/people2/ucbcdal/dfx_funfam2013_data/projects/gene3d_12/starting_clusters/3.40.50.970/*.faa /cath/people2/ucbcdal/dfx_funfam2013_data/projects/gene3d_12/clustering_output/3.40.50.970.trace /cath/people2/ucbtdas/generate_FunFams_test/starting_clusters/3.40.50.970/
~~~~~

 (ii) HUP superfamily (functionally diverse superfamily)
~~~~~
rsync -av /cath/people2/ucbcdal/dfx_funfam2013_data/projects/gene3d_12/starting_clusters/3.40.50.620/*.faa /cath/people2/ucbcdal/dfx_funfam2013_data/projects/gene3d_12/clustering_output/3.40.50.620.trace /cath/people2/ucbtdas/generate_FunFams_test/starting_clusters/3.40.50.620/
~~~~~

 (iii) 1.10.150.120 superfamily (small superfamily)
~~~~~
rsync -av /cath/people2/ucbcdal/dfx_funfam2013_data/projects/gene3d_12/starting_clusters/1.10.150.120/*.faa /cath/people2/ucbcdal/dfx_funfam2013_data/projects/gene3d_12/clustering_output/1.10.150.120.trace /cath/people2/ucbtdas/generate_FunFams_test/starting_clusters/1.10.150.120/
~~~~~

5.Make a list of all the superfamilies to be run (superfamilies.torun.list)

~~~~~
cd /cath/people2/ucbtdas/generate_FunFams_test/starting_clusters/
for i in $(ls -d */); do echo ${i%%/}; done > /cath/people2/ucbtdas/generate_FunFams_test/superfamilies.torun.list
~~~~~

6.Generate the superfamily-specific E-value thresholds from the superfamily trace files

~~~~~
cd /cath/people2/ucbtdas/generate_FunFams_test/
perl /cath/people2/ucbtdas/generate_FunFams_test/scripts/get_evalue_threshold_for_sf_traces.pl /cath/people2/ucbtdas/generate_FunFams_test/starting_clusters /cath/people2/ucbtdas/generate_FunFams_test/superfamilies.torun.list /cath/people2/ucbtdas/generate_FunFams_test
~~~~~

7.Create base directory structure, 'funfhmmer_test_run' in CS bchuckle cluster for running FunFHMMer

~~~~~
rsync -av /cath/homes2/ucbtdas/Working/eclipse_workspace/FunFHMMer_code/github_resources/funfhmmer_dir_cluster/ ucbtdas@bchuckle.cs.ucl.ac.uk:/cluster/project8/ff_stability/FFer_2016/funfhmmer_test_run/
~~~~~

8.Copy the E-value threshold files (SF_list_Evalues.list, SF_list_starting_clusters.list) to CS cluster folder

~~~~~
rsync -av /cath/people2/ucbtdas/generate_FunFams_test/SF_list_Evalues.list /cath/people2/ucbtdas/generate_FunFams_test/SF_list_starting_clusters.list ucbtdas@bchuckle.cs.ucl.ac.uk:/cluster/project8/ff_stability/FFer_2016/funfhmmer_test_run/bin/
~~~~~

9.Tar the sf_starting_clusters folder and copy it to CS bchuckle cluster

~~~~~
tar -zcvf /cath/people2/ucbtdas/generate_FunFams_test/starting_clusters/sf_to_run_starting_clusters.tar.gz -C /cath/people2/ucbtdas/generate_FunFams_test/starting_clusters/ .
rsync -arv /cath/people2/ucbtdas/generate_FunFams_test/starting_clusters/sf_to_run_starting_clusters.tar.gz ucbtdas@bchuckle.cs.ucl.ac.uk:/cluster/project8/ff_stability/FFer_2016/funfhmmer_test_run/sf_starting_clusters/
~~~~~

10.Edit the bash script to run funfhmmer (run_funfhmmer_jobs_bchuckle.sh) in the scripts folder in the working directory

~~~~~
cd /cath/people2/ucbtdas/generate_FunFams_test/scripts/
~~~~~

  (i) check the number of superfamilies to be run (n)

~~~~~
wc -l /cath/people2/ucbtdas/generate_FunFams_test/superfamilies.torun.list
~~~~~

  (ii)  Make the following changes in the bash script:

~~~~~
vim run_funfhmmer_jobs_bchuckle.sh
~~~~~

     ---- enter the value of n in line number 1
    
~~~~~
 #$ -S /bin/bash -t 1-<n>
~~~~~
     ---- change stdoutput file pathname in line number 17 to /cluster/project8/ff_stability/FFer_2016/funfhmmer_test_run/job_status
~~~~~
#$ -o <path to job status folder>
~~~~~
	---- change the project directory in line number 20 to /cluster/project8/ff_stability/FFer_2016/funfhmmer_test_run
~~~~~
projectdir=<path to project dir>
~~~~~
	---- check the directory and file names in line numbers 21-23
~~~~~
startingclustersdir=$projectdir/sf_starting_clusters
sflist=$projectdir/bin/SF_list_Evalues.list
sf_starting_clusters_tar_filename=$startingclustersdir/sf_to_run_starting_clusters.tar.gz
~~~~~

  (iii) Save the changes in the bash script in vim and exit

~~~~~
:wq
~~~~~

11.Copy the scripts folder in the working directory to the CS bchuckle directory

~~~~~
rsync -av /cath/people2/ucbtdas/generate_FunFams_test/scripts/ ucbtdas@bchuckle.cs.ucl.ac.uk:/cluster/project8/ff_stability/FFer_2016/funfhmmer_test_run/bin/
~~~~~

12.Login to the CS bchuckle cluster and change directory to the project directory

~~~~~
ssh ucbtdas@bchuckle.cs.ucl.ac.uk
~~~~~

~~~~~
cd /cluster/project8/ff_stability/FFer_2016/funfhmmer_test_run/bin/
qsub run_funfhmmer_jobs_bchuckle.sh
~~~~~

13.Finished superfamilies will be available as tarred files in folder sf_funfams

~~~~~
ls /cluster/project8/ff_stability/FFer_2016/funfhmmer_test_run/sf_funfams/
~~~~~

14.Copy back superfamily results and job statuses to working directory 

~~~~~
rsync -av ucbtdas@bchuckle.cs.ucl.ac.uk:/cluster/project8/ff_stability/FFer_2016/funfhmmer_test_run/sf_funfams/ /cath/people2/ucbtdas/generate_FunFams_test/sf_funfams/
rsync -av ucbtdas@bchuckle.cs.ucl.ac.uk:/cluster/project8/ff_stability/FFer_2016/funfhmmer_test_run/job_status/ /cath/people2/ucbtdas/generate_FunFams_test/job_status/
~~~~~