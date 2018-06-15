#!/usr/bin/env perl
use strict;
use warnings;
use Path::Tiny;
use FindBin;
use Cath::Schema::Biomap;
use File::Basename;
use Data::Dumper;

# non-core modules
use lib "$FindBin::Bin/../lib/perl5";
use Funfhmmer::Scorecons;
use List::Util;
use Math::Round;

my $USAGE = <<"__USAGE__";

Usage:

    perl $0 /cath/people2/ucbtdas/git/myproject/funfhmmer

__USAGE__

if (! scalar @ARGV) {
	print $USAGE;
	exit;
}

my $dirpath = $ARGV[0];

my $DIR= path("$dirpath");
my $DATADIR= $DIR->child("data");
my $APPSDIR= $DIR->child("apps");
my $RESULTSDIR= $DIR->child("results");
my $BENCHDIR = $DIR->path("benchmark");
unless($BENCHDIR->exists){
	$BENCHDIR->mkpath;
}
my $SFLISTFILE= $DATADIR->path("superfamilies.list");

#my $STATSDIR = $DIR->path("stats");
#unless($STATSDIR->exists){
#	$STATSDIR->mkpath;
#}
#my $SFTREELISTFILE= $DATADIR->path("superfamilies.gemmatrees.torun.list");
#my $RESULTSFILE= $RESULTSDIR->path("SF_FunFamdata.stats.txt");

# connect to the database
my $db = Cath::Schema::Biomap->connect_by_version("4.2");

# get SF starting clusters number
my %sc_num =();
my @superfamilies = $SFLISTFILE->lines;

my $stats_file = "$BENCHDIR/STATS.tsv";
open(STATS, ">$stats_file") or die "Can't open file $stats_file\n";
print STATS "Superfamily\ts90s\tFFs\tDopsHi%\ts90s_HighDops%\tSeqNum_HighDops%\tAvgDOPS\tAvgSeqNum\tSingletons%\tFF_withEC\tFF_withEC_not_singleton\tECpurity>80%\tECpurity>90%\tECpurity100%\n";

# add no. of s90s in high DOPS clusters as a percentage of total no. of s90s
# add no. of seqs in high DOPS clusters as a percentage of total no. of seqs

foreach my $SF (@superfamilies){

	chomp($SF);
	print "$SF\n";

	my $STARTINGCLUSTERDATA= $DATADIR->path("$SF/starting_cluster_alignments");
	my $SFannofile = path("$BENCHDIR/$SF.anno");

	my $scnum=0;
	my %ec_hash=();
	#print "Calculating S90numbers and EC info\n";

	foreach my $aln (glob("$STARTINGCLUSTERDATA/*.aln")) {
		#print "$aln\n";
		$scnum++;
		my @seqheaders = `LC_ALL=C fgrep ">" $aln`;
		my @ffids;
		foreach my $id (@seqheaders){
			$id=~/\>(\w+)\//;
			my $md5 =$1;
			push(@ffids, $md5);
		}

		unless(-e "$SFannofile"){
			# get list of EC for sequences
			my $rs = $db->resultset("UniprotToEc")->search(
				{ sequence_md5 => \@ffids }
			);

			while ( my $row = $rs->next ) {
				my $ffmember = $row->sequence_md5;
				my $ec = $row->ec_code;
				#my $uniprotid = $row->uniprot_acc;
				#my $ec_num = $row1->get_column("ec_code");
				if($ec=~/^\d\.\d+\.\d+\.[\d+|\-]/){
					$ec=~/^(\d\.\d+\.\d+\.[\d+|\-])/;
					my $ec_number = $1;
					$ec_hash{$ffmember}{$ec_number}=1;
				}
			}
		}
	}
	$sc_num{$SF}=$scnum;

	unless(-e "$SFannofile"){
		open(ANNO, ">$SFannofile") or die "Can't open file $SFannofile\n";
		foreach my $seq (sort keys %ec_hash){
			foreach my $func (keys %{ $ec_hash{$seq} }){
				print ANNO "$seq\t$func\n";
			}
		}
		close ANNO;
	}
	if(-e "$SFannofile"){
		my @lines = $SFannofile->lines;
		foreach my $line (@lines){
			my ($seq, $func) = split(" ", $line);
			$ec_hash{$seq}{$func}=1;
		}
	}
			# get the number of FFs and how many have highDOPS, singletons
			my $ffnum=0;
			my $highdops_ff=0;
			my $singletons =0;
			my $ff_ecinfo=0;
			my $ff_ecinfo_notsamemd5=0;
			my $p100=0;
			my $p90=0;
			my $p80=0;
			my $sum_dops = 0;
			my $sum_seqnum = 0;

			my $sum_s90s_high_dops=0;
			my $tot_s90s=0;

			my $sum_seqs_high_dops=0;
			my $tot_seqs=0;

			my $ec_purity_file = "$RESULTSDIR/$SF/$SF.FF.ECpurity.csv";
			open(EC_PURITY, ">$ec_purity_file") or die "Can't open file $ec_purity_file\n";
			print EC_PURITY "SF,FF,purity_percent,MD5swithEC,MD5num,DOPS\n";

			foreach my $aln (glob("$RESULTSDIR/$SF/funfam_alignments/*.aln")) {
				#print "$aln\n";
				$ffnum++;
				my $alnname = basename($aln,".aln");
				my @seqheaders = `LC_ALL=C fgrep ">" $aln`;

				my %s90s=();
				foreach my $header (@seqheaders){
					chomp($header);
					#print "$header\n";
					$s90s{$header} =1;
				}
				my $s90num = keys %s90s;
				my $seqnum = scalar @seqheaders;
				if($seqnum == 1){
					$singletons++;
				}
				$sum_seqnum=$sum_seqnum+$seqnum;
				my $aln_dops = Funfhmmer::Scorecons::assign_dops_score($alnname,"$RESULTSDIR/$SF");
				if($aln_dops >= 70){
					$highdops_ff++;
					$sum_seqs_high_dops = $sum_seqs_high_dops + $seqnum;
					$sum_s90s_high_dops = $sum_s90s_high_dops + $s90num;
				}
				$tot_s90s = $tot_s90s + $s90num;
				$tot_seqs = $tot_seqs+ $seqnum;
				$sum_dops=$sum_dops+$aln_dops;
				#print "DOPS $aln_dops SEQNUM $seqnum\n";
				my %ffids=();
				foreach my $id (@seqheaders){
					$id=~/\>(\w+)\//;
					my $md5 =$1;
					$ffids{$md5}=1;
				}
				my %aln_ec_hash=();
				# get ecs of all ids in aln

				my %md5swithec=();
				foreach my $ffmd5 (keys %ffids){
					foreach my $ecanno (keys %{ $ec_hash{$ffmd5} }){
						$aln_ec_hash{$ecanno}++;
						$md5swithec{$ffmd5}=1;
					}
				}
				#print Dumper(\%aln_ec_hash);
				#exit ;
				my $uniq_md5_ec= keys %md5swithec;

				my $uniq_ec = keys %aln_ec_hash;

				if($uniq_ec > 0){
					$ff_ecinfo++;
				}
				if($uniq_ec > 0 && $uniq_md5_ec> 1){
					$ff_ecinfo_notsamemd5++;

					foreach my $ecnum (sort {$aln_ec_hash{$b} <=> $aln_ec_hash{$a}} keys %aln_ec_hash){

						my $mostcommon_ECnum_present_in = $aln_ec_hash{$ecnum};
						my $mostcommon_ECnum_percentage = ($mostcommon_ECnum_present_in/$uniq_md5_ec)*100;
						#print "$alnname\t$ecnum\t$aln_ec_hash{$ecnum}\t$mostcommon_ECnum_present_in\t$mostcommon_ECnum_percentage\t$seqnum\n";
						print EC_PURITY "$SF,$alnname,$mostcommon_ECnum_percentage,$uniq_md5_ec,$seqnum,$aln_dops\n";
						#print "$alnname,$mostcommon_ECnum_percentage,$uniq_md5_ec,$seqnum\n";
						if($mostcommon_ECnum_percentage == 100 ){
							$p100++;
						}
						if($mostcommon_ECnum_percentage >= 90 ){
							$p90++;
						}
						if($mostcommon_ECnum_percentage >= 80 ){
							$p80++;
						}
						last;
					}
				#exit;
				}
			}

			close EC_PURITY;

			#calculate percentages
			my $s90_high_dops_percent = ($sum_s90s_high_dops/$tot_s90s)*100;
			my $seqnum_high_dops_percent = ($sum_seqs_high_dops/$tot_seqs)*100;
			my $avg_dops = $sum_dops/$ffnum;
			#print "FFNUM $ffnum\n";
			my $avg_seqnum = $sum_seqnum/$ffnum;
			my $highdops_ff_p = ($highdops_ff/$ffnum)*100;
			$highdops_ff_p = nearest(0.01, $highdops_ff_p);
			my $singletons_p = ($singletons/$ffnum)*100;
			$singletons_p = nearest(0.01, $singletons_p);
			my $ff_ecinfo_p = ($ff_ecinfo/$ffnum)*100;
			$ff_ecinfo_p = nearest(0.01, $ff_ecinfo_p);
			my $ff_ecinfo_notsamemd5_p = ($ff_ecinfo_notsamemd5/$ffnum)*100;
			$ff_ecinfo_notsamemd5_p =  nearest(0.01, $ff_ecinfo_notsamemd5_p);
			my $p80_p = ($p80/$ff_ecinfo_notsamemd5)*100;
			$p80_p = nearest(0.01, $p80_p);
			my $p90_p = ($p90/$ff_ecinfo_notsamemd5)*100;
			$p90_p = nearest(0.01, $p90_p);
			my $p100_p = ($p100/$ff_ecinfo_notsamemd5)*100;
			$p100_p = nearest(0.01, $p100_p);

			#get number of trace lines - this gives how many pairs of clusters were compared to generate the tree
			my $TRACE= path("$RESULTSDIR/$SF/tree.trace");
			my @trace_lines = $TRACE->lines;
			my $trace_comparisons = scalar @trace_lines;

			#print stats
			print STATS "$SF\t$sc_num{$SF}\t$ffnum\t$highdops_ff_p\t$s90_high_dops_percent\t$seqnum_high_dops_percent\t$avg_dops\t$avg_seqnum\t$singletons_p\t$ff_ecinfo_p\t$ff_ecinfo_notsamemd5_p\t$p80_p\t$p90_p\t$p100_p\n";

			#exit;
}

close STATS;
