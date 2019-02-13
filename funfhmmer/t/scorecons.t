#!/usr/bin/env perl

use strict;
use warnings;

# core modules
use FindBin;
FindBin::again();
use Exporter qw(import);
use v5.10;

# core test module
use Test::More;
#use Test::Differences;

# Funfhmmer modules
use lib "$FindBin::Bin/../lib";
use Funfhmmer::Scorecons;

# non-core modules
use Path::Tiny;
use Log::Dispatch;

my $bindir = path($FindBin::Bin, "..", "bin");

use_ok( 'Funfhmmer::Scorecons' );

my $example_datadir = path($FindBin::Bin, "..", "t/example_data");
my $example_funfam_datadir = $example_datadir->child("funfam_alignments");
my $example_funfam_analysis_datadir = $example_funfam_datadir->child("analysis_data");
unless(-e "$example_funfam_analysis_datadir"){
        mkdir($example_funfam_analysis_datadir);
}

my $example_expected_datadir = $example_datadir->child("expected_files");

my $aln_name = "cluster1";

#check test alignment file exists
ok( !-z "$example_funfam_datadir/$aln_name.aln", 'Test aln (non-empty) file exists.');

# run scorecons program to generate scorecons and dops files (inside subfolder ./analysis_data) for test alignment file
my $dops = Funfhmmer::Scorecons::assign_dops_score($aln_name, $example_datadir);

#check test scons and dops file generated

ok( !-z "$example_funfam_analysis_datadir/$aln_name.aln.dops", 'Non-empty Test dops file generated.');
my $test_dops = path("$example_funfam_analysis_datadir/$aln_name.aln.dops")->lines;


ok( !-z "$example_expected_datadir/$aln_name.expected.aln.dops", 'Expected dops file exists.');
my $expected_dops = path("$example_expected_datadir/$aln_name.expected.aln.dops")->lines;

is( $test_dops, $expected_dops, 'DOPS file looks OK.' );

# scorecons files are deleted in funfhmmer as they are not used in funfhmmer
#ok( !-z "$example_datadir/funfam_alignments/analysis_data/$aln_name.aln.scorecons", 'Non-empty Test scorecons file generated.');
#my $test_scons = path("$example_datadir/funfam_alignments/analysis_data/$aln_name.aln.scorecons")->lines;
#check expected scons file exists
#ok( !-z "$example_datadir/expected.aln.scorecons", 'Expected Test scorecons file exists.');
#my $expected_scons = path("$example_datadir/expected.aln.scorecons")->lines;
#eq_or_diff( $test_scons, $expected_scons, 'scorecons file looks ok' );

=head
__TEST_ALN__
>66c9ec71c53d711731af571200f5a5c2/124-235
LVKQEFRTKVEETAKQKAEEALLDILLPFPGENKHGSG-QITGFATSSTLADEEDRKTHF
LETREFMRKKLKTGKLDDQEVELDLPNPSVSQVPMLQVFGAGNLDDLDNQLQN
>296260caf498312cc31f3486e5b73fe7/124-235
LVKQEFRTKVEETAKQKAEEALLDILLPFPGENKHGSG-QITGFATSSTLADEEDRKTHF
LETREFMRKKLKTGKLDDQEVELDLPNPSVSQVPMLQVFGAGNLDDLDNQLQN
>a537db49c8089da45f7c7a64b27f2727/124-233
LVKQEFRTKVEETAKQKAEEVLLDILLPFPGENKHGSTYQITG---SSQFTEEEDRKTHF
LETREFMRKKLKAGKLDDQEVELDLPNPSVSQVPMLQVFGAGNLDDLDNQLQN
>dcc33ac588339221129a304e85ab0769/124-235
LVKQEFRTKVEETAKQKAEEALLDILLPFPGENKHGSG-QITGFATSSTLADEEDRKTHF
LETREFMRKKLKTGKLDDQEVELDLPNPSVSQVPMLQVFGAGNLDDLDNQLQN
>597d8a166408cb27f323762efcb3dd03/124-233
LVKQEFRTKVEETAKQKAEEVLLDILLPFPGENKHGSTHQITG---SSQFTEEEDRKTHF
LETREFMRKKLKAGKLDDQEVELDLPNPSVSQVPMLQVFGAGNLDDLDNQLQN
>c54fe0642f3603eaafc4c25bbd03250b/124-233
LVKQEFRTKVEETAKQKAEEVLLDILLPFPGENKHGSTHQITG---SSQFTEEEDRKTHF
LETREFMRKKLKAGKLDDQEVELDLPNPSVSQVPMLQVFGAGNLDDLDNQLQN
>a1900ac5253db25e6b59fd30f7559ddd/124-233
LVKQEFRTKVEETAKQKAEEVLLDILLPFPGENKHGSTHQITG---SSQFTEEEDRKTHF
LETREFMRKKLKAGKLDDQEVELDLPNPSVSQVPMLQVFGAGNLDDLDNQLQN
>096c52f420044b6ff34a849271c35598/124-235
LVKQEFRTKVEETAKQKAEEALLDILLPFPGENKHGSG-QITGFATSSTLADEEDRKTHF
LETREFMRKKLKTGKLDDQEVELDLPNPSVSQVPMLQVFGAGNLDDLDNQLQN
=cut
