package Cluster::Scorecons;

use strict;
use warnings;
use FindBin;
use Path::Tiny;
use File::Slurp;
use Exporter qw(import);

=head1 NAME

Cluster::Scorecons - Generate Scorecons and DOPS for cluster alignments

=head1 SYNOPSIS

	# see Cath::CSA::IO
	$scorecons = Cluster::Scorecons::IO->new( file => '/path/to/file.aln' )->parse_file;
	
	# number of sequences in cluster
	$scorecons->count_seqs;
	
	# new CSA matching pdb_id=1abc
	$filtered_csa = $csa->filter( pdb_id => '1abc' );
	
	# new CSA matching pdb_id=1abc OR pdb_id=2bcd
	$filtered_csa = $csa->filter( pdb_id => [ '1abc', '2bcd' ] );
	
	# new CSA matching pdb_id=1abc AND residue_type=Arg
	$filtered_csa = $csa->filter( pdb_id => '2bcd', residue_type => 'Arg' );

=cut

our @EXPORT_OK = qw(calculate_scorecons_dops assign_dops_score);

sub calculate_scorecons_dops{
	my ($cluster_name, $dir) = @_;
	my $analysis_subfoldername = "analysis_data";
	my $cluster_dopsfile= path("$dir/$analysis_subfoldername","$cluster_name.aln.dops");
	unless($cluster_dopsfile->exists){
		if(path("$dir", "$cluster_name.aln")->exists){
			system "$bindir/scorecons/scorecons -a $dir/$cluster_name.aln -o $dir/$analysis_subfoldername/$cluster_name.aln.scorecons -m $bindir/scorecons/PET91mod.mat2 1> $cluster_dopsfile 2> $dir/$analysis_subfoldername/funfhmmer_run_dops.temp";
			unlink("$dir/$analysis_subfoldername/$cluster_name.aln.scorecons"); # we actually dont need the scorecons file
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
	my $dops_file = path("$dir/$analysis_subfoldername","$cluster_name.aln.dops");
	
	unless(-e "$dops_file"){
		&calculate_scorecons_dops($cluster_name, $dir);
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