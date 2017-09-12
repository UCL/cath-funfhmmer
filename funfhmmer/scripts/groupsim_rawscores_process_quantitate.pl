#!/usr/bin/perl
use strict;

# this script is going to create an alignment features file
# to feed into jalview applet. 

# lets declare some variables
my $CONSfile = shift; # the GroupSim file
my $file = "$CONSfile.processed";
my $bug = "# col_num	score	column";

# now lets get the groupsim score data
my $p=0;
open(CONSFILE, "<$CONSfile")
		or die "Can't open file $CONSfile\n";
open(OUTFILE, ">$file")
	or die "Can't open file $file\n";
while(my $line = <CONSFILE>) {  # reading conservation score file

    if($line=~ /(\d*)\t(\w\w\w\w|\-?\d\.\d*)/){
	my $num = $1 + 1;
	$line =~ s/$1/$num/;
	
	if($p==0){
		$p++;}
	else{
	print OUTFILE "$line";}
}
}
close(CONSFILE);
close(OUTFILE);

my $x1=0; my $x2=0; my $x3=0; my $x4=0; my $x5=0;  my $none=0; my $tot=0;
my $file2 = "$file.quantitate";
open(INFILE, "<$file")
		or die "Can't open file $file\n";
open(OUTFILE1, ">$file2")
	or die "Can't open file $file2\n";
while(my $line = <INFILE>) {  # reading groupsim score file
	$tot++;
    if($line=~ /(\d*)\t(\-?\d\.\d*)\t([\-|\w]*)\s\|\s([\-|\w]*)/){
	my $num =$1;my $score = $2; #our $a=$3;our $b=$4; chomp($a);chomp($b);
	
	if($score<=0.3){$x1++;}
	elsif($score>0.3 && $score<=0.4){$x2++;}
	elsif($score>=0.7 && $score<0.8){$x4++;}
	elsif($score>=0.8 && $score<=1){$x5++;}
	else{$x3++;}
		
}
elsif($line=~ /\d*\t\w*/){
	$none++;
	}
}
print OUTFILE1 "No. of residues more than these Groupsim Scores:\n<=.3\t<=.4\t.4~.7\t.7<.8\t.8=1\tNone\tTot\n";
print OUTFILE1 "$x1\t$x2\t$x3\t$x4\t$x5\t$none\t$tot\n";
close(INFILE);
close(OUTFILE1);
