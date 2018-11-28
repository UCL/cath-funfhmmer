package Funfhmmer;

=head1 NAME

Funfhmmer - This is the Funfhmmer algorithm for functional family (FunFam) identification.

=head1 SYNOPSIS

This module identifies CATH Functional Families for a superfamily by optimally partitioning the GeMMA clustering tree for the superfamily.

=head1 DESCRIPTION

The FunFHMMer algorithm is used to identify functional families in protein domain superfamilies
by determining an optimal cut of a hierarchical clustering superfamily tree of sequence relatives
by calculating a novel functional coherence index based on conserved positions and
specificity-determining positions (SDPs) in sequence alignments. 

=head1 VERSION

Version 2.1

=head1 DEPENDENCIES

Path::Tiny, Log::Dispatch, Statistics::Descriptive, Math::Round, Getopt::Long

=head1 AUTHOR

Sayoni Das C<< <sayoni.das.12@ucl.ac.uk> >>

=cut

use 5.006;
use strict;
use warnings;

our $VERSION = '2.1';

=cut

1;
