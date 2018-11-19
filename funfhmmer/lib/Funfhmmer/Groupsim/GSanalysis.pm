package Funfhmmer::Groupsim::GSanalysis;

=head1 NAME

Funfhmmer::Groupsim::GSanalysis - object to analyse GroupSim scores for cluster alignment files

=head1 SYNOPSIS

	use Funfhmmer::Groupsim::GSanalysis

=head1 DESCRIPTION

This is used to analyze GroupSim files for sequence cluster alignments.

=cut

use strict;
use warnings;

# core modules
use FindBin;
use File::Basename;
use List::Util qw( min max );
use Exporter qw(import);

# Funfhmmer modules
use lib "$FindBin::Bin/../lib";

our @EXPORT_OK = qw( );

=head1 METHODS

=head2 scoreanalysis()

...

	scoreanalysis( $scores_array_ref, $dops1, $dops2, $e, $e_q1, $e_q3 )

=cut

sub scoreanalysis{

	my ($scores_array_ref, $dops1, $dops2, $e, $e_q1, $e_q3) = @_;

	#default is 1, i.e Merge
	my $merge=1;
	my $case = "default";

	if( $e > 0.001 ){

	  # Keep nodes separate when E-values > 0.001
		$merge=0;
		$case = "E>0.001";

		return ($merge,$case);
	}

	my @scores_array = @{ $scores_array_ref };

	my $col_thresh1_3 = $scores_array[0]; 	# percent <=.3_col.s in MSA
	my $col_thresh3_4 = $scores_array[1]; 	# percent <=.4_col.s in MSA
	my $col_thresh4_7 = $scores_array[2]; 	# percent .4~.7_col.s in MSA
	my $col_thresh7_8 = $scores_array[3]; 	# percent .7<.8_col.s in MSA
	my $col_thresh8_10 = $scores_array[4]; 	# percent .8=1_col.s in MSA
	my $col_none = $scores_array[5]; 	# percent None_col.s in MSA
	my $total_cols = $scores_array[6];	# tot = Total_col.s in MSA

	my $quartile1= $scores_array[7]; # first quartile of MSA groupsim score range
	my $median = $scores_array[8]; 	 # median of MSA groupsim score range
	my $quartile3= $scores_array[9]; # second quartile of MSA groupsim score range

	my $col_thresh1_4 = $col_thresh1_3 + $col_thresh3_4; 			# percent <=.4_col.s in MSA
	my $col_thresh7_10 = $col_thresh7_8 + $col_thresh8_10; 			# percent .7=1_col.s in MSA
	my $col_thresh1_10 = $col_thresh1_4 + $col_thresh4_7 + $col_thresh7_10; # percent 0=1_col.s in MSA
	my $col_thresh1_4_7_10 = $col_thresh1_4 + $col_thresh7_10; 		# percent 0.4=1_col.s in MSA

	# @scores1 = @scores_array without the last element 'none'
	my $last_entry = pop @scores_array;
	my @scores1 = @scores_array;
	my @scores2 = ($col_thresh1_4, $col_thresh4_7, $col_thresh7_10, $col_none);
	my $max_gs_scores1 = max @scores1;
	my $max_gs_none_scores2 = max @scores2;

	if($total_cols==0){

		$merge=0;
		$case = "All zero";

		return ($merge,$case);

	}
	if($col_none > 0 && $total_cols > 0){

		if($col_none == 100 ){ # All NONE i.e.

			$merge=0;
			$case = "All None, All relevent 0";

			return ($merge,$case);

		}

		if($col_none >= 30){

			$merge=0;
			$case = "Majority (>30%) None";

			return ($merge,$case);

		}
		elsif($max_gs_scores1 == $col_none){ #none in @score1 & @score2

			if($max_gs_none_scores2 == $col_none){

				if($col_none > $col_thresh1_10){

					$merge=0; $case="Max_none";

					return ($merge,$case);
				}
			}
		}
	}
	if($max_gs_scores1==$col_thresh8_10 || $col_thresh8_10 > $col_thresh1_3){ #0.8=0.1 max in @score1

		$merge=0;
		$case="Max >=0.8 OR High >=0.8";

		return ($merge,$case);
	}
	elsif($max_gs_none_scores2 == $col_thresh7_10 || $col_thresh7_10 > $col_thresh1_3){ #0.7=0.1 max in @score2

		$merge=0;
		$case="Max>0.7 OR High >=0.7";

		return ($merge,$case);
	}
	if($col_thresh7_10 > 0 && $col_thresh1_4_7_10 > 0){

		if($dops1 >= 70 || $dops2 >= 70){

			if($e < $e_q1){

					if($col_thresh7_10 > 50){

						$merge=0;
						$case=">50% 0.7";

						return ($merge,$case);

					}
				}
			elsif($e >= $e_q1 || $e >= $e_q3){

				if($col_thresh7_10 > 20){

					$merge=0;
					$case=">20% 0.7";

					return ($merge,$case);
				}
			}
		}
	}
	if($dops1 >= 70 || $dops2 >= 70){

		if($quartile3 > 0.7){
			$merge=0;
			$case="q3 > 0.7";

			return ($merge,$case);

		}
		if($quartile1 > 0.3){

			$merge=0;
			$case="q1 > 0.3";

			return ($merge,$case);
		}
	}
	# Added in Nov
	if ($dops1 < 70 && $dops2 < 70) {
       if($max_gs_none_scores2 == $col_thresh4_7 || $max_gs_scores1 == $col_thresh4_7){
		
			$merge=0;
			$case="Max cols: 0.4-0.7, not enough similar";

			return ($merge,$case);
			
	   }
    }

	return ($merge,$case);
}

1;
