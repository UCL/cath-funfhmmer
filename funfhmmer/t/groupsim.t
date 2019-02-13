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
use Test::Files;
use Test::Differences;

# Funfhmmer modules
use lib "$FindBin::Bin/../lib";

# non-core modules
use Path::Tiny;
use Log::Dispatch;

my $bindir = path($FindBin::Bin, "..", "bin");

use_ok( 'Funfhmmer::Groupsim' );

my $example_datadir = path($FindBin::Bin, "..", "t/example_data");
my $example_funfam_datadir = $example_datadir->path("funfam_alignments");
my $example_funfam_analysis_datadir = $example_funfam_datadir->path("analysis_data");
unless(-e "$example_funfam_analysis_datadir"){
        mkdir($example_funfam_analysis_datadir);
}
my $example_expected_datadir = $example_datadir->child("expected_files");

my $aln_name1 = "cluster1";
my $aln_name2 = "cluster2";

#check test alignment files exists
ok( !-z "$example_funfam_datadir/$aln_name1.aln", 'Test aln 1 (non-empty) file exists.');
ok( !-z "$example_funfam_datadir/$aln_name2.aln", 'Test aln 2 (non-empty) file exists.');

# run groupsim program to generate groupsim files (inside subfolder ./analysis_data) for test alignment files
my $groupsim_matrix = "id";
my @gs_score = Funfhmmer::Groupsim::gs_process($aln_name1, $aln_name2, $example_funfam_datadir, $groupsim_matrix);

#check files generated
ok( !-z "$example_funfam_analysis_datadir/$aln_name1.$aln_name2.aln", 'Test merged aln (non-empty) file exists.');
ok( !-z "$example_funfam_analysis_datadir/$aln_name1.$aln_name2.GS.processed", 'Test GS (non-empty) file exists.');
ok( !-z "$example_funfam_analysis_datadir/$aln_name1.$aln_name2.GS.processed.quantitate", 'Test processed GS (non-empty) file exists.');

ok( !-z "$example_expected_datadir/$aln_name1.$aln_name2.expected.GS.processed", 'Expected processed GS (without comments) file exists.');
ok( !-z "$example_expected_datadir/$aln_name1.$aln_name2.expected.GS.processed.quantitate", 'Expected GS quantitate file exists.');

compare_ok( "$example_funfam_analysis_datadir/$aln_name1.$aln_name2.GS.processed", "$example_expected_datadir/$aln_name1.$aln_name2.expected.GS.processed", 'processed GS file looks ok' );

print("The calculation of Groupsim quantitation scores have not been checked in this test as they can be optimised/improved.");