#!/usr/bin/perl -w

use strict;

# this script is going to create an alignment features file
# to feed into jalview applet. 

# lets declare some variables

my ($domain, @ResCounts);

my $CONSfile = shift; # the residue conservation (scorecons) file


# now lets get the conservation score data
open(CONSFILE, $CONSfile) || die "Can't read $CONSfile: $!\n";

# print the header
print STDOUT "JALVIEW_ANNOTATION\n";

# print the graph data
print STDOUT "BAR_GRAPH\tScoreCons\tAlignment conservation based on scorecons\t";

my $first = 0;

while(<CONSFILE>) # reading conservation score file
{
    my ($score) = (split)[0];

    if ($first == 0) { # Doesn't prepend on the first field.
        $first = 1;
    } else {
        print "|"; # Prepend a pipe as the field separator.
    }

    # Hack to deal with a bug in the current scorecons
    if ($score == 50) {
    	$score = 0;
    }

    print STDOUT "$score,$score";
}

print STDOUT "\n";
