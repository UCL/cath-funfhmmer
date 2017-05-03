Generating CATH superfamily and FunFam assignments for genomes
======

1. Choose a genome and get all translated protein sequences in FASTA format.
   The FASTA file human_sequences.fasta is used as an example in this documentation.

~~~~~

~~~~~

2. Download the CATH Superfamily and FunFam (Functional Family) models from the CATH web pages.

~~~~~

~~~~~

3. Download the HMMER3 software from http://hmmer.org/download.html and install it by following the instructions in http://hmmer.org/documentation.html.
   The hmmscan program in HMMER3 is required for scanning sequences against CATH models.

~~~~~
tar zxf hmmer-3.1b2.tar.gz
cd hmmer-3.1b2
./configure
make
make check
~~~~~

The scripts for running the models require the hmmscan program to be in your command PATH environment variable.
Add this directory to your PATH variable

4. For generating only CATH superfamily assignments for the sequences, the sequences are scanned against only the CATH superfamily models.

~~~~~
s35 models
~~~~~

5. For generating CATH FunFam assignments for the sequences, the sequences are scanned against the CATH FunFam models and only those which meet the FunFam inclusion threshold are reported.

~~~~~
ff models with TC?
~~~~~

6. cath resolve hits or Domain Finder?

# Relevant Papers

1. [Functional classification of CATH superfamilies: a domain-based approach for protein function annotation](https://doi.org/10.1093/bioinformatics/btv398)

2. [CATH FunFHMMer web server: protein functional annotations using functional family assignments](https://doi.org/10.1093/nar/gkv488)
