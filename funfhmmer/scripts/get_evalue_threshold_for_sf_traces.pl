#!/usr/bin/env perl
use strict;
use warnings;
use File::Slurp;
use File::Basename;
use Data::Dumper;
use Bio::SeqIO;
use Bio::Seq;
use File::Copy;
use List::Util qw( min max );
use Statistics::Descriptive;

my $USAGE = <<"__USAGE__";

Usage: 

    $0 <dir_sf_starting_clusters> <list_of_sfs_in_dir> <outputdir>
    
    Output in <outputdir>:
    
    1. SF_list_Evalues.list            - SFs_list_with_Evalue_thresholds
    2. SF_list_starting_clusters.list  - Sfs_list_with_number_of_starting_clusters

__USAGE__

#Get the superfamily trace and calculate an Evalue threshold

if ( scalar @ARGV != 3 ) {
 print $USAGE;
 exit;
}

my ($dir,$list,$outdir) = @ARGV;
chomp($list);
chomp($dir);
chomp($outdir);
###

my @list = read_file("$list");

my $out2 = "$outdir/SF_list_starting_clusters";
open(OUT2, ">$out2") or die "Can't open file $out2\n";
foreach my $sup (@list) {
	chomp($sup);
	my $supdir = "$dir/$sup";
	my $clusternum =0;
	foreach my $file (glob("$supdir/*.faa")) {
		$clusternum++;
	}
	print OUT2 "$sup\t$clusternum\n";
}

close OUT2;

system("sort -k2,2 -n $out2 > $out2.list");
unlink($out2);

my $out1 = "$outdir/SF_list_Evalues.list";
open(OUT1, ">$out1") or die "Can't open file $out1\n";

my @list2 = read_file("$out2.list");
foreach my $l (@list2) {
	my($sup, $scnum) = split("\t",$l);
	my $trace = "$dir/$sup/$sup.trace";
	my @tracelines = read_file("$trace");
	my @evalues;
	foreach my $traceline (@tracelines){
		chomp($traceline);
		my ($c1,$c2,$c3,$eval)=split("\t", $traceline);
		push(@evalues,$eval);
	}
	my $stat = Statistics::Descriptive::Full->new();
	$stat->add_data(@evalues);
	my $min = $stat->quantile(0);
	my $q1 = $stat->quantile(1);
	my $percentile10 = $stat->percentile(10);
	my $median = $stat->quantile(2);
	my $q3 = $stat->quantile(3);
	my $max = $stat->quantile(4);
	print OUT1 "$sup $percentile10 $q3\n";
	#print OUT1 "$sup $q1 $q3\n";
}
close OUT1;

