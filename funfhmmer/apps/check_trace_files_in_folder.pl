#!/usr/bin/env perl
use strict;
use warnings;
use Path::Tiny;
use File::Basename;
use Data::Dumper;

# script usage
my $USAGE = <<"__USAGE__";
Usage:

    $0 <Dir path with GeMMA result folders>

    E.g. $0 /cath/people2/ucbtdas/GeMMA/v4_2_0_trees/hhsearch_branch_local_nocache_96test ../data

    This script takes the path of the GeMMA result folders and checks the GeMMA trace files 
    It also classiffies them into categories based on #starting clusters and allocates
    time/memory requirements for running in bchuckle.
    
    Output files:
    
    PWD/trace_file_check.OUT
    PWD/superfamilies.small.torun.list       # up to 100 starting clusters
    PWD/superfamilies.medium.torun.list      # 101 - 1000
    PWD/superfamilies.large.torun.list       # 1001 - 5000
    PWD/superfamilies.very_large.torun.list  # above 5000 
    
__USAGE__

my ($dir, $outdir) = @ARGV;
chomp($dir);
chomp($outdir);

# exit script if all input data not provided
if(scalar @ARGV !=2) {
    print $USAGE;
    exit;
}

# complete tracefile have one lines less than the no. of starting clusters
# print the array @evalue0_errorlines to get info the errorlines   
# classify the superfamilies with complete trace files into small, medium, large and very large based on the no. of starting clusters
    
my %small =();
my %medium=();
my %large=();
my %very_large=();

my $trace_checkfile = "$outdir/superfamilies.TRACE_CHECK";
open(TRACE_CHECK, ">$trace_checkfile") or die "Can't open file $trace_checkfile\n";

my $count=0;

foreach my $file (glob("$dir/*/*/tree.trace")) {
    
    $count++;
    my $file_shortname = $file;
    $file_shortname=~ s/$dir\///g;
    
    my @tab = split("\/", $file_shortname);
    my $superfamily = shift @tab;
       
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
    
    
    if( $linenum == ($sc_num - 1) ){
      
      print TRACE_CHECK "$superfamily\t$sc_num\t$linenum\ttrace:COMPLETE\t$evalue_errorlines ERROR lines\n";
      print "$superfamily\t$sc_num\t$linenum\ttrace:COMPLETE\t$evalue_errorlines ERROR lines\n";
      
      my $superfamily_path = "$dir/$superfamily/simple_ordering.hhconsensus.windowed";
      
      if ( $sc_num > 1 && $sc_num <=100 ) {
        
        $small{$superfamily} = $superfamily_path;
        
      }
      elsif( $sc_num <=1000 ){
        
        $medium{$superfamily} = $superfamily_path;
        
      }
      elsif( $sc_num <=5000 ){
        
        $large{$superfamily} = $superfamily_path;
        
      }
      elsif ( $sc_num > 5000 ){
        
        $very_large{$superfamily} = $superfamily_path;
        
      }
      else{
        
        print TRACE_CHECK "WARNING: starting cluster of $superfamily is $sc_num\n";
        print "WARNING: starting cluster of $superfamily is $sc_num\n";
        
      }
  
    }
    else{
      
      print TRACE_CHECK "$superfamily\t$sc_num\t$linenum\ttrace:NOT COMPLETE\t$evalue_errorlines ERROR lines\n";
      print "$superfamily\t$sc_num\t$linenum\ttrace:NOT COMPLETE\t$evalue_errorlines ERROR lines\n";
    
    }

}

close TRACE_CHECK;

print "\nOUTPUT Files in $outdir:\n";

print " superfamilies.TRACE_CHECK ($count SFs)\n";

# print out the superfamily lists based on their sizes
    
if (keys %small) {
        
    my $hash_ref   = \%small;
    &print_to_file("small", $outdir, $hash_ref);    
        
}
if(keys %medium){
      
    my $hash_ref   = \%medium;
    &print_to_file("medium", $outdir, $hash_ref);
      
}
if(keys %large){
      
    my $hash_ref   = \%large;
    &print_to_file("large", $outdir, $hash_ref);
      
}
if(keys %very_large){
      
    my $hash_ref   = \%very_large;
    &print_to_file("very_large", $outdir, $hash_ref);
      
}



sub print_to_file{
  
  my ($size, $dir, $hashref_sub) = @_;
  
  my $outfile = "$dir/superfamilies.$size.torun.list";
  open(OUTFILE, ">$outfile") or die "Can't open file $outfile\n";
  
  my %hash = %{ $hashref_sub };
  
  my $sf_count=0;
  
  foreach my $sf (sort keys %hash){
    
    print OUTFILE "$sf\t$hash{$sf}\n";
    $sf_count++;
  }
  
  close OUTFILE;
  
  print " superfamilies.$size.torun.list ($sf_count SFs)\n";
  
}