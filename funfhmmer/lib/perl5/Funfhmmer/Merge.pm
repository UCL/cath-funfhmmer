package Funfhmmer::Merge;
use strict;
use warnings;
use FindBin;
use File::Basename;

# non-core modules
use lib "$FindBin::Bin/../lib/perl5";
use Funfhmmer::Align;

use Exporter qw(import);

our @EXPORT_OK = qw(merge_cluster_pair merge_gs_3);

sub merge_cluster_pair{ 															
	my ($input1,$input2,$output,$dir) = @_;
	my $inputfile1 = $dir->path("$input1.aln");
	my $inputfile2 = $dir->path("$input2.aln");
	my $outputfile = $dir->path("$output");
	my $outputfile_aln = $dir->path("$output.aln");
	system("cat $inputfile1 $inputfile2 > $outputfile");
	Funfhmmer::Align::generate_catcluster_align($outputfile,$outputfile_aln);
	$inputfile1->remove;
	$inputfile2->remove;
	$outputfile->remove;
}

sub merge_gs_3{
	my ($input1, $input2, $input3,$output,$dir) = @_;
	my $inputfile1 = $dir->path("$input1.aln");
	my $inputfile2 = $dir->path("$input2.aln");
	my $inputfile3 = $dir->path("$input3.aln");
	my $outputfile = $dir->path("$output");
	my $outputfile_aln = $dir->path("$output.aln");
	system("cat $inputfile1 $inputfile2 $inputfile3 > $outputfile");
	Funfhmmer::Align::generate_catcluster_align($outputfile,$outputfile_aln);
	$inputfile1->remove;
	$inputfile2->remove;
	$inputfile3->remove;
	$outputfile->remove;
}	

1;