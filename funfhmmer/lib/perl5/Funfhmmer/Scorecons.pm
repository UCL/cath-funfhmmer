package Funfhmmer::Scorecons;

use strict;
use warnings;
use FindBin;
use Path::Tiny;
FindBin::again();

# non-core modules
use lib "$FindBin::Bin/../lib/perl5";
use File::Slurp;
use Path::Tiny;
use Exporter qw(import);

our $bindir = path($FindBin::Bin, "..", "bin");

our @EXPORT_OK = qw(calculate_scorecons_dops assign_dops_score);

sub calculate_scorecons_dops{

	my ($cluster_name, $dir) = @_;
	my $analysis_subfoldername = "analysis_data";
	my $cluster_dopsfile= path("$dir/$analysis_subfoldername","$cluster_name.aln.dops");
	
	unless($cluster_dopsfile->exists){
	
		if(path("$dir", "$cluster_name.aln")->exists){
		
			system "$bindir/scorecons/scorecons -a $dir/$cluster_name.aln -o $dir/$analysis_subfoldername/$cluster_name.aln.scorecons -m $bindir/scorecons/PET91mod.mat2 1> $cluster_dopsfile 2> $dir/$analysis_subfoldername/funfhmmer_run_dops.temp";
			
			unlink("$dir/$analysis_subfoldername/$cluster_name.aln.scorecons"); 
			
			#Edit the dops file to replace the file from "DOPS score: xxx" to just "xxx"
			system("perl -p -i -e 's/DOPS score: //g' $cluster_dopsfile");
		}
		
		elsif(-e "$dir/$analysis_subfoldername/$cluster_name.aln"){
			
			system "$bindir/scorecons/scorecons -a $dir/$analysis_subfoldername/$cluster_name.aln -o $dir/$analysis_subfoldername/$cluster_name.aln.scorecons -m $bindir/scorecons/PET91mod.mat2 1> $cluster_dopsfile 2> $dir/$analysis_subfoldername/funfhmmer_run_dops.temp";
			
			unlink("$dir/$analysis_subfoldername/$cluster_name.aln.scorecons");
			
			system("perl -p -i -e 's/DOPS score: //g' $cluster_dopsfile");
		}
	}
}

sub assign_dops_score{
	my ($cluster_name, $dir) = @_;
	my $analysis_subfoldername = "analysis_data";
	my $dops_file = path("$dir/funfam_alignments/$analysis_subfoldername","$cluster_name.aln.dops");
	
	unless(-e "$dops_file"){
		&calculate_scorecons_dops($cluster_name, "$dir/funfam_alignments");
	}
	my $dops_score;
	if(-z "$dops_file"){
		$dops_score= "0.000";
	}
	elsif(-e "$dops_file"){
		$dops_score = read_file("$dops_file");
		chomp($dops_score);
	}
	return $dops_score;
}

1;