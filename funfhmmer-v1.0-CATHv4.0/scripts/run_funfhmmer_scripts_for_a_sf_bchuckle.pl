#!/usr/bin/env perl
use strict;
use warnings;

my ($projectdir,$sf,$q1,$q3,$wd)= @ARGV;

chomp($projectdir);
chomp($sf);
chomp($q1);
chomp($q3);
chomp($wd);

my $time = localtime();
print " -- Running FunFHMMer on $sf..\n";
system "perl $projectdir/bin/funfhmmer-bchuckle.pl $sf $q1 $q3 $projectdir $wd" ;

print " -- Checking $sf completion..\n";
system "perl $projectdir/bin/check_funfhmmer_run_bchuckle.pl $sf $wd" ;

print "[$time] Finished running FFer $sf.\n";
