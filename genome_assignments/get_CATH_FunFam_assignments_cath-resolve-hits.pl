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

my $out = "$fasta_name.funfam.domtblout";
my $domain_assignments = "$fasta_name.funfam.dom_assignments";

# Run HMMSEARCH to get HMMER3 OUTPUT
system("$hmmer3dir/hmmsearch --cut_tc --domtblout $out $hmmlibpath $fastafile > /dev/null 2>&1");
# Run cath-resolve-hits to get CATH DOMAIN ASSIGNMENTS
system("./cath-resolve-hits --input-format hmmer_domtblout --output-file $domain_assignments $out");

	
