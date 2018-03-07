package Funfhmmer::Merge;

use strict;
use warnings;
use FindBin;
use File::Basename;
use File::Copy;
use Path::Tiny;

# non-core modules
use lib "$FindBin::Bin/../lib/perl5";
use Funfhmmer::Align;

use Exporter qw(import);

our @EXPORT_OK = qw(merge_use_gemma_alns merge_cluster_pair merge_gs_3);

sub merge_use_gemma_alns{
	
	my ($input1, $input2, $output, $dir) = @_;
	
	# copy merge node to funfam aln folder
	my $merged_node_aln = path("$dir/merge_node_alignments/$output.aln");
	my $funfam_aln = path("$dir/funfam_alignments/$output.aln");
	copy($merged_node_aln, $funfam_aln) or die "Copy failed: $!";
	
	#remove child clusters in funfam aln folder
	my $inputfile1 = path("$dir/funfam_alignments/$input1.aln");
	my $inputfile2 = path("$dir/funfam_alignments/$input2.aln");
	$inputfile1->remove;
	$inputfile2->remove;
	
}

sub merge_cluster_pair{

	my ($input1, $input2, $output, $dir) = @_;
	
	my $inputfile1 = $dir->path("funfam_alignments/$input1.aln");
	my $inputfile2 = $dir->path("funfam_alignments/$input2.aln");
	
	my $outputfile = $dir->path("$output");
	my $outputfile_aln = $dir->path("funfam_alignments/$output.aln");
	
	system("cat $inputfile1 $inputfile2 > $outputfile");
	
	Funfhmmer::Align::generate_catcluster_align($outputfile,$outputfile_aln);
	
	$outputfile->remove;
	$inputfile1->remove;
	$inputfile2->remove;
	
}

sub merge_gs_3{

	my ($input1, $input2, $input3, $output, $dir) = @_;
	
	my $inputfile1 = $dir->path("funfam_alignments/$input1.aln");
	my $inputfile2 = $dir->path("funfam_alignments/$input2.aln");
	my $inputfile3 = $dir->path("funfam_alignments/$input3.aln");
	
	my $outputfile = $dir->path("funfam_alignments/$output");
	my $outputfile_aln = $dir->path("funfam_alignments/$output.aln");
	
	system("cat $inputfile1 $inputfile2 $inputfile3 > $outputfile");
	
	Funfhmmer::Align::generate_catcluster_align($outputfile,$outputfile_aln);
	
	$inputfile1->remove;
	$inputfile2->remove;
	$inputfile3->remove;
	$outputfile->remove;
	
}	

1;