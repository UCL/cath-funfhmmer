package Funfhmmer::TestIO;

=head1 NAME

Funfhmmer::TestIO - object to test input and output

=head1 SYNOPSIS

	use Funfhmmer::TestIO

=head1 DESCRIPTION


=cut

use strict;
use warnings;
use FindBin;

# non-core modules
use lib "$FindBin::Bin/../lib";

use Exporter qw(import);


our @EXPORT_OK = qw(check_input check_output);

=head1 METHODS

=head2 check_input()

...

	check_input($superfamily, $evalthresh_gs_start, $evalthresh_q3, $wd)

=cut

sub check_input{
	my ($superfamily, $evalthresh_gs_start, $evalthresh_q3, $wd) = @_;
	my $error_count = 0;
	unless($superfamily=~ /^\d+\.\d+\.\d+\.\d+$/){
		print "ERROR: CATH superfamily ID format is incorrect: $superfamily\n";
		$error_count++;
	}
	unless($evalthresh_gs_start=~ /e/ && $evalthresh_q3=~ /e/){
		print "ERROR: E-values format is incorrect: $evalthresh_gs_start or/and $evalthresh_q3\n";
		$error_count++;
	}
	unless(-e "$wd/$superfamily/$superfamily.trace"){
		print "ERROR: Superfamily trace file does not exist: $wd/$superfamily/$superfamily.trace\n";
		$error_count++;
	}
	if(-z "$wd/$superfamily/$superfamily.trace"){
		print "ERROR: Superfamily trace file is empty: $wd/$superfamily/$superfamily.trace\n";
		$error_count++;
	}
	unless(-e "$wd"){
		print "ERROR: Working directory does not exist: $wd\n";
		$error_count++;
	}
	unless(-e "$wd/$superfamily"){
		print "ERROR: Superfamily directory does not exist: $wd/$superfamily\n";
		$error_count++;
	}
	if(-e "$wd/$superfamily"){
		my $faa_count=0;
		my $faa_empty_count=0;
		foreach my $fa (glob("$wd/$superfamily/*.faa")) {
			$faa_count++;
			if(-z "$fa"){
				$faa_empty_count++;
			}
		}
		if($faa_count==0){
			print "ERROR: Superfamily folder has $faa_count FAA files\n";
			$error_count++;
		}
		if($faa_empty_count > 0){
			print "ERROR: Superfamily folder has $faa_empty_count empty FAA files\n";
			$error_count++;
		}
		my $aln_count=0;
		foreach my $aln (glob("$wd/$superfamily/*.aln")) {
			$aln_count++;
		}
		if($aln_count > 0){
			print "ERROR: Superfamily folder has $aln_count ALN files before running FFer\n";
			$error_count++;
		}
	}
	return $error_count;
}

=head2 check_output()

...

	check_output($superfamily, $wd)

=cut

sub check_output{
	my ($superfamily, $wd) = @_;
	my @error;
	my $faa_count =0;
	foreach my $fa (glob("$wd/$superfamily/*.faa")) {
		$faa_count++;
	}
	push(@error, $faa_count);
	my $aln_count=0;
	my $aln_empty_count=0;
	foreach my $aln (glob("$wd/$superfamily/*.aln")) {
		$aln_count++;
		if(-z "$aln"){
			$aln_empty_count++;
		}
	}
	push(@error, $aln_count);
	push(@error, $aln_empty_count);
	return @error;
}

1;
