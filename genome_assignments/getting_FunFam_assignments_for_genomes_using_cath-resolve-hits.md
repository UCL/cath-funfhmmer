Generating CATH superfamily and FunFam assignments for genomes using cath-resolve-hits
======

1. Go to working directory

~~~~~
mkdir cath_genome_assignments
cd cath_genome_assignments
~~~~~

2. Choose a genome and get all translated protein sequences in FASTA format. 
For example, test.fasta has been used as an example in this documentation.

3. Download the CATH FunFam (Functional Family) models from from /cath/people2/ucbtdas/CAFA3/CATH_MODELS/funfam.hmm3.TC.lib.gz.

~~~~~
mkdir cath_models
rsync -arv /cath/people2/ucbtdas/CAFA3/CATH_MODELS/funfam.hmm3.TC.lib.gz ./cath_models/funfam.hmm3.TC.lib.gz
gunzip ./cath_models/funfam.hmm3.TC.lib.gz
~~~~~

4. Download the [HMMER3](http://hmmer.org/) software and install it by following the instructions in http://hmmer.org/documentation.html. The hmmscan program in HMMER3 is required for scanning sequences against CATH models. All the binary tarballs include source code along with the binaries/ directory containing precompiled binaries. 

~~~~~
tar zxf hmmer-3.1b2-linux-intel-x86_64.tar.gz
~~~~~

5. Download [cath-resolve-hits](https://github.com/UCLOrengoGroup/cath-tools/releases/download/v0.13.1/cath-resolve-hits).
Detailed documents of this tool is available [here](http://cath-tools.readthedocs.io/en/latest/tools/cath-resolve-hits/). 

~~~~~
wget "https://github.com/UCLOrengoGroup/cath-tools/releases/download/v0.13.1/cath-resolve-hits"
~~~~~

6. For generating CATH FunFam assignments for the sequences, the sequences are scanned against the CATH FunFam models and only those which meet the FunFam inclusion threshold are reported.

~~~~~
mkdir results

# perl get_CATH_FunFam_assignments_cath-resolve-hits.pl <fasta_file> <output_dir>
perl get_CATH_FunFam_assignments_cath-resolve-hits.pl test.fasta ./results/
~~~~~

7. Output file:

~~~~~
test.funfam.dom_assignments
~~~~~

# Relevant Links:

1. [Functional classification of CATH superfamilies: a domain-based approach for protein function annotation](https://doi.org/10.1093/bioinformatics/btv398)

2. [CATH FunFHMMer web server: protein functional annotations using functional family assignments](https://doi.org/10.1093/nar/gkv488)

3. [HMMER3 User Manual](ftp://ftp.hgc.jp/pub/mirror/wustl/hmmer3/3.1b1/Userguide.pdf)
