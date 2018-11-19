package Funfhmmer::Merge;

=head1 NAME

Funfhmmer::Merge - object to merge (concatenate) sequence cluster files

=head1 SYNOPSIS

	use Funfhmmer::Merge

=head1 DESCRIPTION

This is used to merge (concatenate) sequence cluster alignment files.

=cut

use strict;
use warnings;

# core modules
use FindBin;
use File::Basename;
use File::Copy;
use Exporter qw(import);

# non-core modules
use Path::Tiny;

# Funfhmmer modules
use lib "$FindBin::Bin/../lib";
use Funfhmmer::Align;


our @EXPORT_OK = qw(merge_use_gemma_alns merge_cluster_pair merge_gs_3);

=head1 METHODS

=head2 merge_use_gemma_alns()

...

	merge_use_gemma_alns( $input1, $input2, $output, $dir )

=cut

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

=head2 merge_cluster_pair()

...

	merge_cluster_pair( $input1, $input2, $output, $dir )

=cut

sub merge_cluster_pair{

	my ($input1, $input2, $output, $dir) = @_;
	
	my $inputfile1 = path("$dir/funfam_alignments/$input1.aln");
	my $inputfile2 = path("$dir/funfam_alignments/$input2.aln");
	
	my $outputfile = path("$dir/$output");
	my $outputfile_aln = path("$dir/funfam_alignments/$output.aln");
	
	system("cat $inputfile1 $inputfile2 > $outputfile");
	
	Funfhmmer::Align::generate_catcluster_align($outputfile,$outputfile_aln);
	
	$outputfile->remove;
	$inputfile1->remove;
	$inputfile2->remove;
	
}

=head2 merge_gs_3()

...

	merge_gs_3( $input1, $input2, $input3, $output, $dir )

=cut

sub merge_gs_3{

	my ($input1, $input2, $input3, $output, $dir) = @_;
	
	my $inputfile1 = path("$dir/funfam_alignments/$input1.aln");
	my $inputfile2 = path("$dir/funfam_alignments/$input2.aln");
	my $inputfile3 = path("$dir/funfam_alignments/$input3.aln");
	
	my $outputfile = path("$dir/funfam_alignments/$output");
	my $outputfile_aln = path("$dir/funfam_alignments/$output.aln");
	
	system("cat $inputfile1 $inputfile2 $inputfile3 > $outputfile");
	
	Funfhmmer::Align::generate_catcluster_align($outputfile,$outputfile_aln);
	
	$inputfile1->remove;
	$inputfile2->remove;
	$inputfile3->remove;
	$outputfile->remove;
	
}	

1;
