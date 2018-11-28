#!/usr/bin/env perl
#use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Funfhmmer',
  VERSION_FROM => 'lib/Funfhmmer.pm',
  PREREQ_PM    => {
        
      'Path::Tiny'              => '0.106',
      'Statistics::Descriptive' => 0,
      'Log::Dispatch' => 0,
      'DateTime' => 0,
      'File::Copy' => 0,
      'Getopt::Long' => 0,
      'Math::Round' => 0,
      'Data::Dumper' => 0,
      'File::Basename' => 0,
      'File::Copy' => 0,
      'List::Util' => 0,
  },
  BUILD_REQUIRES => {
    'Test::More' => '0.88'
  },
);
