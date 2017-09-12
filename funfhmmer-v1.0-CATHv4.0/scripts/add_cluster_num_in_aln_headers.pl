#!/usr/bin/env perl
use strict;
#use warnings;

#Take 2 original funfam.faa (>fausiu/12-13) as input and get funfam1.funfam2 (>fausiu/12-13|435)
my $dir = shift @ARGV; chomp($dir); 
my $funfam1path = shift @ARGV; chomp($funfam1path); my $funfam1; 
my $funfam2path = shift @ARGV; chomp($funfam2path); my $funfam2;
if($funfam1path=~ /$dir\/(\d*)\./){
	$funfam1 = $1;
}
if($funfam2path=~ /$dir\/(\d*)\./){
	$funfam2 = $1;
}	
my $filename1="$dir/$funfam1.$funfam2";
open(INFILE, "<$funfam1path")
	or die "Can't open file $funfam1path\n";
open(OUTFILE, ">$filename1")
	or die "Can't open file $filename1\n";
while(my $line = <INFILE>) { 
	chomp ($line);
	if($line=~ /\>\w*\/\d*-\d*/){
		print OUTFILE "$line|$funfam1\n";
		#print "$line|$funfam\n";
		}
	else{	
		print OUTFILE "$line\n";
	}
}
close(INFILE);
open(INFILE, "<$funfam2path")
	or die "Can't open file $funfam2path\n";
while(my $line = <INFILE>) { 
	chomp ($line);
	if($line=~ /\>\w*\/\d*-\d*/){
		print OUTFILE "$line|$funfam2\n";
		#print "$line|$funfam\n";
		}
	else{	
		print OUTFILE "$line\n";
	}
}
close(INFILE);
close(OUTFILE);
