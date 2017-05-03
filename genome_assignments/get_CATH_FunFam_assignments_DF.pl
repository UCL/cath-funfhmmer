#!/usr/bin/env perl
use strict;
use warnings;
use Bio::SeqIO;
use Bio::Seq;
use File::Basename;

my $USAGE = <<"__USAGE__";

Usage: 

    $0 <fastafile> <output_dir>

    E.g. $0 xxx.fasta output_dir

__USAGE__

if ( scalar @ARGV != 2 ) {
 print $USAGE;
 exit;
} 

# get the input fastafile and output dir
my ($fastafile, $output_dir) = @ARGV; 
chomp($fastafile);
chomp($output_dir);

my $hmmlibpath = "./cath_models/funfam.hmm3.TC.lib";
my $hmmer3dir = "./hmmer-3.1b2-linux-intel-x86_64";
my $fasta_name = basename($fastafile, ".fasta");
print "Processing $fasta_name:\n";

my $out = "$fasta_name.funfam.out";
my $ssf = "$fasta_name.funfam.ssf";
my $df = "$fasta_name.funfam.df";

# Run HMMSCAN to get HMMER3 OUTPUT
system("$hmmer3dir/hmmscan --cut_tc -o $out $hmmlibpath $fastafile");
if(-e "$out"){
	# REFORMAT HMMER3 OUTPUT TO SSF FORMAT FOR RUNNING DF
	system("./DF/hmmer3scan_to_ssf.pl $out $ssf");
	if(-e "$ssf"){
		# RUN DF to get CATH DOMAIN ASSIGNMENTS
		system("./DF/DomainFinder3 -i $ssf -o $df");
	}
}


	
