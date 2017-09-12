#!/usr/bin/env perl
use strict;
use warnings;

## This script checks for superfamily run progress and prints a .check file and generates a .redo file if required

my ($superfamily,$wd)  = @ARGV; 
chomp($superfamily);
chomp($wd);

#FUNFAMS dir
my $sf_funfam_dir = "$wd/$superfamily";
#TRACE dir
my $sf_tracefile = "$sf_funfam_dir/$superfamily.trace";
#RUNLOG dir
my $sf_runlogfile = "$sf_funfam_dir/$superfamily.LOG";
#MERGELOG dir
my $sf_mergelogfile ="$sf_funfam_dir/$superfamily.mergelog";
#REDO dir
my $sf_redofile = "$sf_funfam_dir/$superfamily.redo";
#DONE file - completed successfully
my $sf_donefile = "$sf_funfam_dir/$superfamily.done";
#CHECK dir
my $chkfile = "$sf_funfam_dir/$superfamily.check";
open(CHECKRUN, ">>$chkfile") or die "Can't open file $chkfile\n";
	
my $flag=0;

#chk trace file exists or not 
if(! -e "$sf_tracefile"){
	$flag++;
}

#chk trace file is empty or not
if(-z "$sf_tracefile"){
	$flag++;
}

#check whether any empty .aln files are present in the folder\n";
my $aln=0; my @alnlist;
foreach my $file (glob("$sf_funfam_dir/*.aln")) {
	if(-z "$file"){
		my @fields = split("\/",$file);
		my $alnname= pop(@fields);
		$alnname=~ s/.aln//g;
		push(@alnlist,$alnname);
		$aln++;
	}
}
if($aln == 0){
	print CHECKRUN "ALNs: no empty file\n";
}
elsif($aln>0){
	print CHECKRUN "ALNs: EMPTY files - @alnlist\tREDO\n";
	$flag++;
}

#print "# chk whether any .faa file is left\n";
my $countfaa =0; my @faalist;
foreach my $file (glob("$sf_funfam_dir/*.faa")) {
	$countfaa++;
	my @fields = split("\/",$file);
	my $faaname= pop(@fields);
	$faaname=~ s/.faa//g;
	push(@faalist,$faaname);
}
if($countfaa > 0){
	print CHECKRUN "FAAs: PRESENT - @faalist\tREDO\n";
	$flag++;
}
elsif($countfaa==0){
	print CHECKRUN "FAAs: no faa file\n";
}

#print "#check whether LOG file says - Job finished, get the hours\n";
my $line = `fgrep -w "hours" $sf_runlogfile`;
chomp($line);
if($line){
	print "$superfamily run: finished\n";
	$line=~/(\d+\.*\d*) hours/;
	my $hrs = $1;
	print CHECKRUN "$superfamily runtime: $hrs hours\n";
}
else{
	print CHECKRUN "$superfamily run: NOT finished\tREDO\n";
	$flag++;
}

#check whether a redo file for this superfamily already exists
if(-e "$sf_redofile"){
	if(! -z "$sf_redofile"){
		print CHECKRUN "REDO file: existed before\n";
	}
}

#print "# chk whether any .clstr file is present\n";
my $countclstr =0; 
foreach my $file (glob("$sf_funfam_dir/*.clstr")) {
	$countclstr++;
}
if($countclstr > 0){
	print CHECKRUN "CD-HIT: used\n";
}
elsif($countclstr==0){
	print CHECKRUN "CD-HIT: not used\n";
}

if($flag==0){
	print CHECKRUN "RUN: successfully completed\n";
	if(-e "$sf_redofile"){
		unlink($sf_redofile);
	}
	unless(-e "$sf_donefile"){
		open(DONE, ">$sf_donefile") or die "Can't open file $sf_donefile\n";
		print DONE "$superfamily\n";
		close DONE;
	}
	#tar the superfamily funfam folder
	#my $sf_tarname= "$base_dir/sf_funfams/$superfamily.tar.gz";
	#system("tar -zcvf $sf_tarname -C $base_dir/sf_funfams/$superfamily .");
}
elsif($flag>0){
	print CHECKRUN "RUN: NOT completed\n";
	unless(-e "$sf_redofile"){
		open(REDO, ">$sf_redofile") or die "Can't open file $sf_redofile\n";
		print REDO "$superfamily\n";
		close REDO;
	}
}
close CHECKRUN;
