package Funfhmmer::Filter;

use strict;
use warnings;
use File::Basename;
use File::Copy;
use Path::Tiny;
use FindBin;

# non-core modules
use lib "$FindBin::Bin/../lib/perl5";
use Funfhmmer::Align;
use List::Util qw[min max sum];
use Exporter qw(import);

our @EXPORT_OK = qw(filter_mfastas filter_cluster);

sub filter_mfastas{
	my $dir_path = shift;
	#####
	# Filter starting clusters fragment sequences (length < 80% of avg. sequence length of the cluster)
	#####
	my $dir = path("$dir_path");
	my $filter_dir = $dir->child("filtered");
	unless($filter_dir->is_dir) {
		mkdir $filter_dir;
	}
	foreach my $faa (glob("$dir_path/*.faa")) {
		my $clustername=basename($faa, ".faa");
		my $filtered_clusterfile = $filter_dir->child("$clustername.faa");
		&filter_cluster($faa, $filtered_clusterfile, $clustername);
	}
}

sub filter_cluster{
	my ($faa, $filtered_clusterfile, $clustername) = @_;
	my @seq_lengths;
	#####
	# NOTE: seqfile must not contain whitespace/newlines!
	#####
	open(FILTERED, ">$filtered_clusterfile") or die "cannot open $filtered_clusterfile";
	open(INF, "<$faa") or die "cannot open $faa";
	while (<INF>){
	if (/^\>/) { next; }
		chomp;
		push @seq_lengths, length($_);
	}
	close INF;
	my $avg = sprintf "%.2f", sum(@seq_lengths)/@seq_lengths;
	my $threshold_length = ($avg * 0.8); 
	my $filtered = 0;
	my ($seq_id, $seq);
	#####
	# filter all seqs from MFASTA that have a length outside the accepted range
	#####
	open(INF, "<$faa") or die "cannot open $faa";
	while (<INF>){
		chomp;
		if (/^\>/) { $seq_id = $_; } 
		else{
			$seq = $_;
			my $l = length($seq);
			if($l>=$threshold_length){
				print FILTERED "$seq_id#$clustername\n$seq\n";
			}
			else{ 
				$filtered++;
			     }
			}
	}
	close INF;
	close FILTERED;
	unlink($faa);
	copy($filtered_clusterfile, $faa);
	#unlink("$filtered_clusterfile");
}

1;

# sub filter_align_while_merging{
# 	my ($input_path, $output_path) = @ARGV;
# 	#print OUT "#FILTERING,";
# 	&filter_cluster($input_path);
# 	Funfhmmer::Align::generate_catcluster_align($input_path, $output_path);
# }

# sub filter_mfasta_by_seq_length_mergedfaa{
# 	my $fasta = shift;
# 	chomp($fasta);
# 	my $headers = `fgrep -c ">" $fasta`;
# 	chomp($headers);
# 	# only filter if the aln has >10 sequences
# 	if($headers > 10){
# 		my $new_dir = "$target_sup_cluster_dir/filtered";
# 		unless(-e $new_dir) {
# 			mkdir $new_dir;
# 		}
# 		my @field = split("\/",$fasta);
# 		my $y=pop(@field);
# 		copy("$fasta", "$new_dir/$y.temp");
# 		#change the alignment to fasta equivalent
# 		# create new Bio::SeqIO object    
# 		#my $in = Bio::SeqIO->new( -file   => "<$new_dir/$y.temp",
# 					#-format => "fasta");
# 		my $in_temp = "$new_dir/$y.temp";
# 		open(F0, "<$in_temp") or die "Can't open file $in_temp\n";
# 		my $out_temp = "$new_dir/$y.faa";
# 		open(F1, ">$out_temp") or die "Can't open file $out_temp\n";
# 		my $c=0;
# 		while( my $l =<F0>){
# 			chomp($l);
# 			if($l=~/^\>/){
# 				if($c>0){
# 					print F1 "\n";
# 				}
# 				print F1 "$l\n";
# 				$c++;
# 				
# 			}
# 			else{
# 				$l=~ s/^\s+//g;
# 				$l=~ s/-//g;
# 				print F1 "$l";    
# 			}
# 		}
# 		print F1 "\n";
# 		close F0;
# 		close F1;
# 		system "perl $codes_dir/filter_fragments_in_fasta.pl $new_dir/$y.faa > $new_dir/$y.faa_nofrag"; 
# 		unlink($fasta);
# 		copy("$new_dir/$y.faa_nofrag", $fasta);
# 		unlink("$new_dir/$y.faa");
# 		unlink("$new_dir/$y.faa_nofrag");
# 		unlink("$new_dir/$y.temp");
# 		#print "filtered $fasta\n";
# 		#exit 0;
# 	}
# }