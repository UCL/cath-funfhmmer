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
    
    NOTE: Run this in /cath/.... environment, not in HPC as it uses CATH db info
    
    perl $0 <CATH_version> <PROJECT_APP_DIR> <LIST NAME> <uniprot annotation: SP/ALL> <force_get_latest_anno: (Y/N)> <LOCAL_RESULT_DIR> <BENCHMARK_DIR>
    perl $0 4.2 /cath/people2/ucbtdas/git/ffer/funfhmmer SF_listname SP N <RESULT_DIR> <BENCHMARKING_DIR>

__USAGE__

if(scalar @ARGV !=7) {
	print $USAGE;
	exit;
}

my $cath_version = $ARGV[0];
my $dirpath  = $ARGV[1];
my $listname = $ARGV[2];
my $anno_type = $ARGV[3];
my $force_get_latest_annotation= $ARGV[4];
my $result_dir = $ARGV[5];
my $benchmark_dir = $ARGV[6];

chomp($dirpath);
chomp($listname);

my $DATADIR= path("/export/sayoni/funfhmmer_v4_2_0/data/trees");
my $ANNODIR = path("/export/sayoni/funfhmmer_v4_2_0/benchmarking/SF_anno");

my $DIR= path("$dirpath");
my $APPSDIR= $DIR->child("apps");
my $RESULTSDIR= path("$result_dir");
my $BENCHDIR = path("$benchmark_dir");

die "! ERROR: Result dir '$RESULTSDIR' does not exist\n"
    unless -e $RESULTSDIR;
    
unless($BENCHDIR->exists){
	$BENCHDIR->mkpath;
}

my $SFLISTFILE= path("$listname");

# connect to the database
my $db = Cath::Schema::Biomap->connect_by_version("$cath_version");

# get SF starting clusters number
my %sc_num =();
my @superfamily_lines=$SFLISTFILE->lines;

my $stats_file = $BENCHDIR->path("FUNFAM.STATS.$anno_type.tsv");

open(STATS, ">$stats_file") or die "Can't open file $stats_file\n";
print STATS "Superfamily\ts90s\tFFs\tDopsHi%\ts90s_HighDops%\tSeqNum_HighDops%\tAvgDOPS\tAvgSeqNum\tSingletons%\tFF_withEC%\tECpurity>80%\tECpurity>90%\tECpurity100%\n";

# add no. of s90s in high DOPS clusters as a percentage of total no. of s90s
# add no. of seqs in high DOPS clusters as a percentage of total no. of seqs

foreach my $line (@superfamily_lines){
    
    chomp($line);
    my $SF = $line;
	
    print "$SF\n";
    
    my $SFBENCHDIR = $BENCHDIR->path("$SF");
    unless($SFBENCHDIR->exists){
        $SFBENCHDIR->mkpath;
    }
    
    my $scnum=0;
    my %sf_hash=();

    my $STARTINGCLUSTERDATA= $DATADIR->path("$SF/simple_ordering.hhconsensus.windowed/starting_cluster_alignments");
    my $SFannofile = path("$ANNODIR/$SF.md5.uniprot.ec.anno");

    #get SF annotations
        
        my %ids=();
    
        foreach my $aln (glob("$STARTINGCLUSTERDATA/*.aln")) {
            
            #print "$aln\n";
            # count no. of starting_clusters
            $scnum++;
            
            my $s90_name = basename($aln, ".aln");
        
            # get the sequences of each aln
                my @seqheaders = `LC_ALL=C fgrep ">" $aln`;
        
                foreach my $id (@seqheaders){
                    
                    $id=~/\>(\w+)/;
                    my $md5 =$1;
                    #print "$md5\n";
                    $ids{$md5}=1;
                    
                }
        }
    if(-z "$SFannofile" || ! -e "$SFannofile" || $force_get_latest_annotation eq "Y"){
        
        my @ffids;
        foreach my $seq (keys %ids){
          
          push(@ffids, $seq);
        
        }
    
        # get list of EC for sequences
        my $rs = $db->resultset("UniprotToEc")->search(
            { sequence_md5 => \@ffids }
        );
        
        my %uniprot_accs=();
        while ( my $row = $rs->next ) {
            
            my $ffmember = $row->sequence_md5;
            my $uniprotid = $row->uniprot_acc;
            $uniprot_accs{$uniprotid}=$ffmember;
            
        }
        
        # Write all uniprot accs to file for fetching annotations
        my $accs_file = path( "$ANNODIR/$SF.accs" );
        my $accs_fh = $accs_file->openw;
        
        foreach my $acc (sort {$uniprot_accs{$a} cmp $uniprot_accs{$b}} keys %uniprot_accs){
            
            chomp($acc);
            my $md5 = $uniprot_accs{$acc};
            print $accs_fh "$md5\t$acc\n";
        
        }
        
        #print Dumper (\%sf_hash);
        
        system("perl $APPSDIR/get-uniprot-annotations-api.pl $accs_file $SFannofile");

    }
	   
    $sc_num{$SF}=$scnum;

	# get the number of FFs and how many have highDOPS, singletons
	my $ffnum=0; my $highdops_ff=0; my $singletons =0; my $ff_ecinfo=0;
	my $p100=0; my $p90=0; my $p80=0; my $sum_dops = 0; my $sum_seqnum = 0;
    my $sum_s90s_high_dops=0; my $tot_s90s=0; my $sum_seqs_high_dops=0; my $tot_seqs=0;
            
	my $ec_purity_file = "$SFBENCHDIR/$SF.FF.ECpurity.$anno_type.csv";
	open(EC_PURITY, ">$ec_purity_file") or die "Can't open file $ec_purity_file\n";
	print EC_PURITY "SF,FF,purity_percent,MD5swithEC,MD5num,DOPS\n";

	foreach my $aln (glob("$RESULTSDIR/$SF/funfam_alignments/*.aln")) {
		
		$ffnum++;
        
		my $alnname = basename($aln,".aln");
        my $dirname = dirname($aln);
        
        print "$SF\tFF $alnname\n";
        
		my @seqheaders = `LC_ALL=C fgrep ">" $aln`;

		my %s90s=();
		foreach my $header (@seqheaders){
			
            chomp($header);
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

        # get EC purity of the clusters
        my ($tot_md5_num,$md5s_with_ec,$uniprots_withec,$ecnum,$mostcommon_ECnum_present_in) = &get_ec_purity($SFBENCHDIR, $aln, $SFannofile, $anno_type);

		if($tot_md5_num){
                    
            $ff_ecinfo++;
			my $mostcommon_ECnum_percentage = ($mostcommon_ECnum_present_in/$uniprots_withec)*100; #$uniq_md5_ec

            print EC_PURITY "$SF\t$alnname\t$ecnum\t$md5s_with_ec\t$uniprots_withec\t$mostcommon_ECnum_present_in\t$mostcommon_ECnum_percentage\n";
            print "$SF\t$alnname\t$ecnum\t$md5s_with_ec\t$uniprots_withec\t$mostcommon_ECnum_present_in\t$mostcommon_ECnum_percentage\n";

            #print "$SF,$alnname,$mostcommon_ECnum_percentage,$uniq_md5_ec,$seqnum\n";
			if($mostcommon_ECnum_percentage == 100 ){
				$p100++;
			}
			if($mostcommon_ECnum_percentage >= 90 ){
				$p90++;
			}
			if($mostcommon_ECnum_percentage >= 80 ){
				$p80++;
			}
		}
###        exit 0;
    }
      
    close EC_PURITY;
    
#calculate cluster aln stats
        
	my $s90_high_dops_percent = ($sum_s90s_high_dops/$tot_s90s)*100;
	my $seqnum_high_dops_percent = ($sum_seqs_high_dops/$tot_seqs)*100;
        my $avg_dops = $sum_dops/$ffnum;
	my $avg_seqnum = $sum_seqnum/$ffnum;
	my $highdops_ff_p = ($highdops_ff/$ffnum)*100;
	$highdops_ff_p = nearest(0.01, $highdops_ff_p);
	my $singletons_p = ($singletons/$ffnum)*100;
	$singletons_p = nearest(0.01, $singletons_p);
            
    # Calculate EC benchmarking stats only if >1 FunFams have EC info
    if ($ff_ecinfo > 0) {

		my $ff_ecinfo_p = ($ff_ecinfo/$ffnum)*100;
		$ff_ecinfo_p = nearest(0.01, $ff_ecinfo_p);
		my $p80_p = ($p80/$ff_ecinfo)*100;
		$p80_p = nearest(0.01, $p80_p);
		my $p90_p = ($p90/$ff_ecinfo)*100;
		$p90_p = nearest(0.01, $p90_p);
        my $p100_p = ($p100/$ff_ecinfo)*100;
		$p100_p = nearest(0.01, $p100_p);

		#print stats
		print STATS "$SF\t$sc_num{$SF}\t$ffnum\t$highdops_ff_p\t$s90_high_dops_percent\t$seqnum_high_dops_percent\t$avg_dops\t$avg_seqnum\t$singletons_p\t$ff_ecinfo_p\t$p80_p\t$p90_p\t$p100_p\n";
        
    }
    else{
            
        print STATS "$SF\t$sc_num{$SF}\t$ffnum\t$highdops_ff_p\t$s90_high_dops_percent\t$seqnum_high_dops_percent\t$avg_dops\t$avg_seqnum\t$singletons_p\tNA\tNA\tNA\tNA\n";
            
    }
    
    #exit 0;
}

close STATS;

sub get_ec_purity{

    my ($dir, $aln, $annofile, $anno_type) = @_;
    my @array;
    
    my $alnname = basename($aln);
    
    my $FF_anno_type_dir = path("$dir/$anno_type");
    unless($FF_anno_type_dir->exists){
        $FF_anno_type_dir->mkpath;
    }
    my $ff_annofile = path( "$FF_anno_type_dir/FF.$alnname.md5.uniprot.ec.$anno_type.anno" );
    my $ffanno_fh = $ff_annofile->openw;
    
    my @seqheaders = `LC_ALL=C fgrep ">" $aln`;
    
    # get list of md5s
    my %ffids=();

    foreach my $id (@seqheaders){
        
        $id=~/\>(\w+)/;
        my $md5 =$1;
        $ffids{$md5}=1;
    
    }

    my $tot_md5_num = keys %ffids;

    # get ECs for list of md5s
    my %ec_hash=();my %uniprot_hash=();my %md5_hash=();

    foreach my $md5 (keys %ffids){
        
        my @lines = `fgrep -w "$md5" $annofile`;
        
        foreach my $line (@lines){
            
            chomp($line);
            my ($md5, $uniprotid, $ecs, $uniprot_entry_type) = split("\t", $line);
            
            if (($anno_type eq "ALL") || ($anno_type eq "SP" && $uniprot_entry_type eq "Swiss-Prot" )) {
                print $ffanno_fh "$line\n";
                my @ec_numbers = split(";", $ecs);
            
                foreach my $ec_num (@ec_numbers){
                    
                    if ($ec_num=~ /\d\.\d+\.\d+\.\d+/) {
                    
                        $ec_hash{$ec_num}++;
                        $uniprot_hash{$uniprotid}=1;
                        $md5_hash{$md5}=1;
                    
                    }
                }
            
            }
            
        }
    }
    
    if(-z "$ff_annofile"){
        unlink("$ff_annofile");
    }

    my $uniprots_withec = keys %uniprot_hash;
    my $md5s_withec = keys %md5_hash;

    #print Dumper (\%md5_hash);
    #print Dumper (\%uniprot_hash);
    #print Dumper (\%ec_hash);

    if($md5s_withec > 1 && $uniprots_withec > 1){

        foreach my $ecnum (sort {$ec_hash{$b} <=> $ec_hash{$a}} keys %ec_hash){

            my $mostcommon_ECnum_present_in = $ec_hash{$ecnum};
            my $md5_with_most_common_ec=0;

            #print "$aln\t$ecnum\t$md5s_with_ec\t$uniprots_withec\t$mostcommon_ECnum_present_in\n";

            return($tot_md5_num,$md5s_withec,$uniprots_withec,$ecnum,$mostcommon_ECnum_present_in);

            last;

        }
    }
    else{
        
        return 0;
    
    }

}

