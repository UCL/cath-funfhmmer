package Funfhmmer::Align;

=head1 NAME

Funfhmmer::Align - Object to make an alignment (collection of protein sequences)

=head1 SYNOPSIS

Note: usually this object is created through L<Funfhmmer::Align>

=head1 METHODS

=cut

use strict;
use warnings;
use File::Basename;
use Path::Tiny;
use FindBin;
use Exporter qw(import);

use lib "$FindBin::Bin/../lib/perl5";

our @EXPORT_OK = qw(generate_clusterfaa_align generate_catcluster_align);

sub generate_clusterfaa_align{
	my ($clustername, $dir) = @_;
	my $cluster_faa = path("$dir", "$clustername.faa");
	my $cluster_aln = path("$dir", "$clustername.aln");
	unless($cluster_aln->exists){
		&align($cluster_faa, $cluster_aln);
		&check_align($cluster_faa, $cluster_aln);
	}
}

sub generate_catcluster_align{
	my ($input_path, $output_path) = @_;
	if(!-e "$output_path" || -z "$output_path"){ 
		&align($input_path, $output_path);
		&check_align($input_path, $output_path);
	}
}

sub check_align{
	my ($cluster_faa, $cluster_aln) = @_;
	#####
	# Check whether aln file is generated and if it is empty, then quit
	# if aln file is non-existant or empty, make alignment
	# if non-empty aln has been created, delete the faa file
	#####
	if(!-e "$cluster_aln" || -z "$cluster_aln"){
		&align($cluster_faa, $cluster_aln);
	}
	if(-e "$cluster_aln" && !-z "$cluster_aln" && -e "$cluster_faa"){
		unlink("$cluster_faa");
	}
}

sub align{
	my ($cluster_faa, $cluster_aln) = @_;
	my $bindir = path( $FindBin::Bin, "..", "bin" );
	my $cdhit = path("$bindir/cdhit-master","cdhit");
	my $mafft = path("$bindir/mafft-linux64","mafft.bat");
	
	
	my $seqnumber = `grep -c '>' $cluster_faa`;
	chomp($seqnumber);
	
	if($seqnumber == 1){   
		rename("$cluster_faa", "$cluster_aln");
	}
	else {	#####
		# If the clusters are very big, run cd-hit on the cluster sequences to reduce processing time
		#####
		my $cdhit_operation = 0;
		if($seqnumber > 3000 && $seqnumber < 10000){
			#####
			# make 1.aln -> 1.cd.aln after removing non-redundant sequences
			# delete 1.aln, rename 1.cd.aln -> 1.aln, del another cdhit cluster forming file, keep one for adding them back in
			#####
			system("$cdhit -i $cluster_faa -o $cluster_faa.cd -d 100 -c 0.95 -n 5");
			$cdhit_operation++;
		}
		elsif($seqnumber > 10000 && $seqnumber < 20000){
			system("$cdhit -i $cluster_faa -o $cluster_faa.cd -d 100 -c 0.94 -n 5");
			$cdhit_operation++;
		}
		elsif($seqnumber > 20000){
			system("$cdhit -i $cluster_faa -o $cluster_faa.cd -d 100 -c 0.93 -n 5");
			$cdhit_operation++;
		}
		if($cdhit_operation > 0){
			unlink("$cluster_faa");
			rename("$cluster_faa.cd", "$cluster_faa");
			unlink("$cluster_faa.cd.clstr");
		}
		#####		
		# Align sequences using MAFFT 
		#####
		if($seqnumber >= 2 && $seqnumber <= 500){ 
			system("$mafft --anysymbol --amino --quiet --localpair --maxiterate 1000 $cluster_faa > $cluster_aln");
		}
		elsif($seqnumber >= 501 && $seqnumber <= 2000){
			system("$mafft --anysymbol --amino --quiet --maxiterate 2 $cluster_faa > $cluster_aln");
		}
		elsif($seqnumber >= 2001){
			system("$mafft --anysymbol --amino --quiet --retree 1 $cluster_faa > $cluster_aln");
		}
	}
}

1;