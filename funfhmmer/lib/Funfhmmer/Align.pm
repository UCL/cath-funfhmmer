package Funfhmmer::Align;

=head1 NAME

Funfhmmer::Align - object to make an alignment (collection of protein sequences)

=head1 SYNOPSIS

	use Funfhmmer::Align

=head1 DESCRIPTION

This is used to align sequence cluster files.

=cut

use strict;
use warnings;

# core modules
use File::Basename;
use FindBin;
use Exporter qw(import);

# non-core modules
use Path::Tiny;

#Funfhmmer modules
use lib "$FindBin::Bin/../lib";

our @EXPORT_OK = qw(generate_clusterfaa_align generate_catcluster_align);

=head1 METHODS

=head2 generate_clusterfaa_align()

Returns aligned fasta file for a cluster fasta filename in a directory

	generate_clusterfaa_align($clustername, $dir)

=cut

sub generate_clusterfaa_align{
	
	my ($clustername, $dir) = @_;
	my $cluster_faa = path("$dir", "$clustername.faa");
	my $cluster_aln = path("$dir", "$clustername.aln");
	
	unless($cluster_aln->exists){
		
		&align($cluster_faa, $cluster_aln);
		&check_align($cluster_faa, $cluster_aln);
	
	}
	
}

=head2 generate_catcluster_align()

Returns an aligned file for a concatenated file of two alignments

	generate_catcluster_align($input_path, $output_path)

=cut

sub generate_catcluster_align{
	
	my ($input_path, $output_path) = @_;
	
	if(!-e "$output_path" || -z "$output_path"){
		
		&align($input_path, $output_path);
		&check_align($input_path, $output_path);
		
	}
	
}

=head2 check_align()

Checks the generated aligned file. If aln file is non-existant or empty, redo the alignment.
If a non-empty alignment file has been created, delete the fasta file.

	check_align($cluster_faa, $cluster_aln)

=cut

sub check_align{
	my ($cluster_faa, $cluster_aln) = @_;
	
	if(!-e "$cluster_aln" || -z "$cluster_aln"){
		&align($cluster_faa, $cluster_aln);
	}
	if(-e "$cluster_aln" && !-z "$cluster_aln" && -e "$cluster_faa"){
		unlink("$cluster_faa");
	}
}

=head2 align()

Returns a aligned file for an input fasta file

	align($cluster_faa, $cluster_aln)

=cut

sub align{
	
	my ($cluster_faa, $cluster_aln) = @_;
	
	my $bindir = path( $FindBin::Bin, "..", "bin" );
	my $cdhit = path("$bindir/cdhit-master","cd-hit");
	my $mafft = path("$bindir/mafft-linux64","mafft.bat");

	my $seqnumber = `grep -c '>' $cluster_faa`;
	chomp($seqnumber);

	if($seqnumber == 1){
		
		rename("$cluster_faa", "$cluster_aln");
		
	}
	else {	#####
		
		my $cdhit_operation = 0;
		
		# If the clusters are very big, run cd-hit on the cluster sequences to reduce processing time
		#####
=head
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
=cut
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
