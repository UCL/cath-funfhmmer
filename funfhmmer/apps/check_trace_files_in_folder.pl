#!/usr/bin/env perl
use strict;
use warnings;
use Path::Tiny;
use File::Basename;
use Data::Dumper;

my $dir = shift;
chomp($dir);

foreach my $file (glob("$dir/*/*/tree.trace")) {

    # count the no. of lines in the tracefile
    my $tracefile = path("$file");
    my @lines = $tracefile->lines;
    my $linenum = scalar @lines;

    # find trace lines with 0.00e+00 evalues - are they are present anywhere in tree ?
    # If yes, flag tree as ERROR and print the distance from the root as percentages
    my $tree_evalue0_error_flag=0;
    my @evalue0_lines=();
    my $c=0;

    foreach my $line (@lines){
      my ($childnode1, $childnode2, $node, $evalue) = split("\t", $line);
      $c++;
      if($evalue == "0.00e+00"){
        push(@evalue0_lines, $c);
      }
    }
    my $evalue_errorlines = scalar @evalue0_lines;

    # count the no. of starting clusters
    my $filedirname = dirname($file);
    my $sc_dir = "$filedirname/starting_cluster_alignments";
    my $sc_num = `ls $sc_dir/*.aln | wc -l`;
    chomp($sc_num);
    
    my $file_shortname = $file;
    $file_shortname=~ s/$dir//g;    

    # complete tracefile have one lines less than the no. of starting clusters
    # print the array @evalue0_errorlines to get info the errorlines
    if($linenum == ($sc_num - 1)){
      print "$file_shortname\ttracelines($linenum)\tstarting_clusters($sc_num)\ttrace COMPLETE\t$evalue_errorlines ERROR lines\n";
    }
    else{
      print "$file_shortname\ttracelines($linenum)\tstarting_clusters($sc_num)\ttrace is NOT COMPLETE\t$evalue_errorlines ERROR lines\n";
    }

}
