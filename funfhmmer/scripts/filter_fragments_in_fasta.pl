#!/usr/bin/perl
use strict;
use warnings;

my $inf = shift;

my @seq_lengths;
#NOTE seqfile must not contain whitespace/newlines!
open(INF, "<$inf") || die "cannot open $1 ($!)";
while (<INF>)
	{
	if (/^\>/) { next; }
	chomp;
	push @seq_lengths, length($_);
	}
close INF;

use List::Util qw[min max sum];
my $avg = sprintf "%.2f", sum(@seq_lengths)/@seq_lengths;
my $threshold_length = ($avg * 0.8); 
#print min(@seq_lengths) . " $low $avg $up " . max(@seq_lengths) . "\n";

my $filtered = 0;

my ($seq_id, $seq);
# filter all seqs from MFASTA that have a length outside the accepted range
open my $INF, "<$inf" || die "cannot open $ARGV[0] ($!)";
while (<$INF>)
	{
	chomp;
	if (/^\>/) { $seq_id = $_; } 
	else 
		{
		$seq = $_;
		my $l = length($seq);
		if ($l>=$threshold_length)
			{
			print "$seq_id\n$seq\n";
			}
		else 
			{ 
			$filtered++;
			
			#print "excluded: $seq_id : $l\n";
			}
		}
	}
close $INF;

#print "$filtered sequences filtered\n";
