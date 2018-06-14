#!/usr/bin/env perl
use strict;
use warnings;
use Path::Tiny;
use FindBin;
use File::Basename;
use Data::Dumper;

my $dir = shift;
chomp($dir);

foreach my $file (glob("$dir/*/*/tree.trace")) {

    # count the no. of lines in the tracefile
    my @lines = read_file("$file");
    my $linenum = scalar @lines;

    # find trace lines with 0.00e+00 evalues - are they are present anywhere in tree ?
    # If yes, flag tree as ERROR and print the distance from the root as percentages
    my $tree_evalue0_error_flag=0;
    my @evalues0_distancefromroot=();
    my $c=0;

    foreach my $line (@lines){
      my ($childnode1, $childnode2, $node, $evalue) = split("\t", $line);
      $c++;
      if($evalue == "0.00e+00"){

        my $distancefromroot = $linenum - $c;
        my $distancefromroot_percent = ($distancefromroot/$linenum) * 100;
        push(@evalues0_distancefromroot, $distancefromroot_percent);
      }
    }
    my $evalue_errorlines = scalar @evalues0_distancefromroot;

    # count the no. of starting clusters
    my $filedirname = dirname($file);
    my $sc_dir = "$filedirname/starting_cluster_alignments";
    my $sc_num = `ls $sc_dir/*.aln | wc -l`;
    chomp($sc_num);

    # complete tracefile have one lines less than the no. of starting clusters
    if($linenum == ($sc_num - 1)){
      print "$file\ttracelines($linenum)\tstarting_clusters($sc_num)\ttrace COMPLETE\t$evalue_errorlines ERROR lines (@evalues0_distancefromroot)\n";
    }
    else{
      print "$file\ttracelines($linenum)\tstarting_clusters($sc_num)\ttrace is NOT COMPLETE\t$evalue_errorlines ERROR lines (@evalues0_distancefromroot)\n";
    }

}
