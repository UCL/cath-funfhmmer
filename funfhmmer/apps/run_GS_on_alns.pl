#!/usr/bin/env perl
use strict;
use warnings;
use File::Copy;
use FindBin;

# non-core modules
use lib "$FindBin::Bin/../lib/perl5";
use Getopt::Long;
use Path::Tiny;
use Log::Dispatch;
use DateTime;
use Math::Round;
use Data::Dumper;
use File::Basename;
use File::Copy;
use List::Util qw( min max );
my $USAGE = <<"__USAGE__";

Usage:

    $0 --dir <dir_of_merged_alns> --groupsim_matrix <id/mc>

    Options:
    --groupsim-matrix	id	Identity matrix
			mc	Mclachlan matrix (Chemical similarity)

__USAGE__

if (! scalar @ARGV) {
	print $USAGE;
	exit;
}

my $wd;
my $superfamily;
my $groupsim_matrix;

GetOptions (
		"dir=s"  => \$wd,    # string
		"groupsim_matrix=s" => \$groupsim_matrix,
	    )
	    or die("Error in command line arguments $!\n");

die "! ERROR: Input dir '$wd' does not exist $!\n"
  unless -e $wd;

die "! ERROR: groupsim_matrix (input given:'$groupsim_matrix') should be either 'id' or 'mc' $!\n"
  unless($groupsim_matrix eq "id" || $groupsim_matrix eq "mc");

#####
# Specify the FunFam and trace directory paths:
#####

our $dir = path("$wd")->absolute;
unless($dir->exists){
	print "ERROR: $dir does not exist.\n";
	exit 0;
}

foreach my $aln (glob ("$dir/analysis_data/*.aln")){
  chomp($aln);
  my $aln_name = basename($aln, ".aln");
  $aln_name=~ /^(\S+)\.(\S+)/;
  my $input1 = $1;
  my $input2 = $2;

  print "$aln_name\t$input1\t$input2\n";

  #get GROUPSIM_SCORE FILE using identity matrix
	my $groupsim_scores = path("$dir/analysis_data/$input1.$input2.GS1");
	my $groupsimfile = path("$dir/analysis_data/$input1.$input2.GS.processed.quantitate1");
	my $bindir ="/cluster/project8/ff_stability/funfhmmer-2018/bin";  
	if($groupsim_matrix eq "id"){
		
		system ("python2 $bindir/groupsim/group_sim_sdp.py -c 0.3 -g 0.5 $aln $input1 $input2 > $groupsim_scores");
		
		if (-z "$groupsim_scores"){
			
			system ("python2 $bindir/groupsim/group_sim_sdp_without_cons.py -c 0.3 -g 0.5 $aln $input1 $input2 > $groupsim_scores");
	
		}
	}
	if(-e "$groupsim_scores"){
		print("generated GS file\n");
	}
  #exit 0;
}
