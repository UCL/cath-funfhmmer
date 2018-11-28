package Funfhmmer::Filter;

=head1 NAME

Funfhmmer::Filter - object to filter an alignment

Note: This module is NOT being used in v2.1 as the new GeMMA starting clusters are pre-filtered.

=head1 SYNOPSIS

	use Funfhmmer::Filter

=head1 DESCRIPTION

This is used to filter starting cluster fasta files of sequence fragments in the old GeMMA algorithm.
Sequence fragments are considered to be sequence that have length < 80% of the average sequence length of the cluster relatives.

=cut

use strict;
use warnings;

# core modules
use File::Basename;
use File::Copy;
use FindBin;

# non-core modules
use Path::Tiny;
use List::Util qw[min max sum];
use Exporter qw(import);

#Funfhmmer modules
use lib "$FindBin::Bin/../lib";
use Funfhmmer::Align;

our @EXPORT_OK = qw(filter_mfastas filter_cluster);

=head1 METHODS

=head2 filter_mfastas()

Returns filtered fasta files for a directory containing starting clusters in fasta format

	filter_mfastas($dir_path)

=cut

sub filter_mfastas{
	
	my $dir_path = shift;
	
	#####
	# Filter starting clusters fragment sequences (length < 80% of avg. sequence length of the cluster)
	#####
	
	my $dir = path("$dir_path");
	my $filter_dir = $dir->child("filtered");
	unless($filter_dir->is_dir) {
		mkdir $filter_dir;
	}
	
	foreach my $faa (glob("$dir_path/*.faa")) {
		my $clustername=basename($faa, ".faa");
		my $filtered_clusterfile = $filter_dir->child("$clustername.faa");
		&filter_cluster($faa, $filtered_clusterfile, $clustername);
	}
	
}

=head2 filter_cluster()

Returns a filtered version of an aligned cluster file

	filter_cluster($faa, $filtered_clusterfile, $clustername)

=cut

sub filter_cluster{
	
	my ($faa, $filtered_clusterfile, $clustername) = @_;
	my @seq_lengths;
	
	#####
	# NOTE: seqfile must not contain whitespace/newlines!
	#####
	
	open(FILTERED, ">$filtered_clusterfile") or die "cannot open $filtered_clusterfile";
	open(INF, "<$faa") or die "cannot open $faa";
	while (<INF>){
	if (/^\>/) { next; }
		chomp;
		push @seq_lengths, length($_);
	}
	close INF;
	my $avg = sprintf "%.2f", sum(@seq_lengths)/@seq_lengths;
	my $threshold_length = ($avg * 0.8); 
	my $filtered = 0;
	my ($seq_id, $seq);
	
	#####
	# filter all seqs from MFASTA that have a length outside the accepted range
	#####
	
	open(INF, "<$faa") or die "cannot open $faa";
	while (<INF>){
		chomp;
		if (/^\>/) { $seq_id = $_; } 
		else{
			$seq = $_;
			my $l = length($seq);
			if($l>=$threshold_length){
				print FILTERED "$seq_id#$clustername\n$seq\n";
			}
			else{ 
				$filtered++;
			     }
			}
	}
	close INF;
	close FILTERED;
	
	unlink($faa);
	copy($filtered_clusterfile, $faa);
	#unlink("$filtered_clusterfile");
	
}

1;