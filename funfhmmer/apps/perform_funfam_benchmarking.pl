#!/usr/bin/env perl
use strict;
use warnings;
use Path::Tiny;
use FindBin;
use Cath::Schema::Biomap;
use File::Basename;
use Data::Dumper;

# non-core modules
use lib "$FindBin::Bin/../lib";
use Funfhmmer::Scorecons;
use Funfhmmer::Anno;
use Getopt::Long;
use List::Util;
use Math::Round;

#####################################################################################################################################################
#
# 							Benchmarking FunFams
#
# This perl script takes in a project_id, starting_cluster_alignments dir and funfam_alignments dir
# to generate benchmarking stats regarding EC purity of funfams, #singletons, #funfams with high DOPs etc. 
#
#
#####################################################################################################################################################


my $USAGE = <<"__USAGE__"; 

Usage:
    
	perl $0 --project_id <project_id> --project_s90_aln_dir <s90 dir> --project_funfam_aln_dir <funfam dir> --use_uniprot_review_type <swissprot/all> --force_get_latest_anno <y/n> --outdir <output dir for benchmarking result>

	E.g.: perl perform_funfam_benchmarking.pl --project_id 3.40.50.620-mda-10 --project_s90_aln_dir /cath/people2/ucbtdas/test_funfhmmer/results/local_run/3.40.50.620-mda-10/starting_cluster_alignments --project_funfam_aln_dir /cath/people2/ucbtdas/test_funfhmmer/results/local_run/3.40.50.620-mda-10/funfam_alignments --use_uniprot_review_type all --force_get_latest_anno y --outdir /cath/people2/ucbtdas/test_funfhmmer/results/local_run_benchmark
	
    Note: --project_s90_aln_dir should point to a 'starting_cluster_alignments' directory
          --project_funfam_aln_dir should point to a 'funfam_alignments' directory 
    
__USAGE__

if(! scalar @ARGV) {
	print $USAGE;
	exit;
}

my ($project_id, $project_s90_aln_dir, $project_funfam_aln_dir, $anno_type, $force_get_latest_anno, $outdir);

GetOptions (
                "project_id=s"                => \$project_id,
                "project_s90_aln_dir=s"       => \$project_s90_aln_dir,
                "project_funfam_aln_dir=s"    => \$project_funfam_aln_dir,
                "use_uniprot_review_type=s"   => \$anno_type,    
                "force_get_latest_anno=s"     => \$force_get_latest_anno,
                "outdir=s"                    => \$outdir,
            )
            or die("Error in command line arguments\n");

$force_get_latest_anno = lc($force_get_latest_anno);
$anno_type = lc($anno_type);

my $S90_DIR     = path("$project_s90_aln_dir");
my $FUNFAM_DIR  = path("$project_funfam_aln_dir");
my $BENCHMARK_DIR     = path("$outdir");

die "! ERROR: S90 dir '$S90_DIR' does not exist\n"
    unless -e $S90_DIR;
    
die "! ERROR: FunFam dir '$FUNFAM_DIR' does not exist\n"
    unless -e $FUNFAM_DIR;
    
unless($BENCHMARK_DIR->exists){
	$BENCHMARK_DIR->mkpath;
}

my $PROJECT_BENCHMARK_DIR = $BENCHMARK_DIR->path("$project_id");
unless($PROJECT_BENCHMARK_DIR->exists){
    $PROJECT_BENCHMARK_DIR->mkpath;
}

# get SF starting clusters number
my %sc_num =();

# add no. of s90s in high DOPS clusters as a percentage of total no. of s90s
# add no. of seqs in high DOPS clusters as a percentage of total no. of seqs

my $stats_file = $PROJECT_BENCHMARK_DIR->path("$project_id.FUNFAM.STATS.$anno_type.tsv");

unless(-e "$stats_file"){
	
    print "Getting benchmark stats for $project_id\n";
    
    my $scnum=0;
    my %sf_hash=();
    
    my $annofile = $PROJECT_BENCHMARK_DIR->path("$project_id.uniprot.ec.anno");

    #get SF annotations
        
    my %ids=();
    
	open(STATS, ">$stats_file") or die "Can't open file $stats_file\n";
	print STATS "Project_ID\ts90s\tFFs\tFF%_HighDops\ts90%_inHighDopsFFs\tSeqNum%_HighDopsFFs\tAvgDops_FFs\tAvgSeqNum_FFs\tSingleton%_FFs\tFF%_withECs\tECpurity>80%\tECpurity>90%\tECpurity100%\n";
	
    foreach my $aln (glob("$S90_DIR/*.aln")) {
        
        # count no. of starting_clusters (s90)
        $scnum++;
            
        my $s90_name = basename($aln, ".aln");
        
        #print "$s90_name: $aln\n";
        
        # get the uniprot sequence headers of each aln
        my @seqheaders = `LC_ALL=C fgrep ">" $aln`;
        
        foreach my $id (@seqheaders){
            
            $id=~/\>(\w+)/;
            my $uniprot_acc =$1;
            #print " -- $uniprot_acc\n";
            $ids{$uniprot_acc}=$s90_name;
                    
        }
    }
    
    # get list of EC annotations for uniprot_accs
    
    if((-z "$annofile") || (!-e "$annofile") || ($force_get_latest_anno eq "y")){
        
        # Write all uniprot accs to file for fetching annotations
        my $accs_file = $PROJECT_BENCHMARK_DIR->path( "$project_id.accs" );
        my $accs_fh = $accs_file->openw;
        
        foreach my $acc (sort {$ids{$a} cmp $ids{$b}} keys %ids){
            
            chomp($acc);
            print $accs_fh "$acc\n";
        
        }
            
        Funfhmmer::Anno::get_uniprot_anno_for_uniprot_list( $accs_file, $annofile );
		
        #system("perl $APPSDIR/get-uniprot-annotations-api.pl $accs_file $annofile");

    }
	   
    $sc_num{$project_id}=$scnum;

	# get the number of FFs and how many have highDOPS, singletons
	my $ffnum=0; my $highdops_ff=0; my $singletons =0; my $ff_ecinfo=0;
	my $p100=0; my $p90=0; my $p80=0; my $sum_dops = 0; my $sum_seqnum = 0;
    my $sum_s90s_high_dops=0; my $tot_s90s=0; my $sum_seqs_high_dops=0; my $tot_seqs=0;
            
	my $ec_purity_file = $PROJECT_BENCHMARK_DIR->path( "$project_id.FF.ECpurity.$anno_type.csv" );
    
	open(EC_PURITY, ">$ec_purity_file") or die "Can't open file $ec_purity_file\n";
	print EC_PURITY "PROJECT_ID\tfunfam\tdops\tecnum\tuniprots_with_ec (total_uniprot_num)\tmostcommon_ECnum_present_in\tmostcommon_ECnum_percentage\n";

	foreach my $aln (glob("$FUNFAM_DIR/*.aln")) {
		
		$ffnum++;
        
		my $alnname = basename($aln,".aln");
        my $dirname = dirname($aln);
        
        print "$project_id\tFF $alnname\n";
        
		my @seqheaders = `LC_ALL=C fgrep ">" $aln`;

		my %s90s=();
		foreach my $header (@seqheaders){
			
            chomp($header);
            
            $header=~/\>(\w+)/;
            my $acc =$1;
            
            if($ids{$acc}){
                
                 my $s90_name=$ids{$acc};
                 $s90s{$s90_name}=1;
            
            }
		}
				
        my $s90num = keys %s90s;
		my $seqnum = scalar @seqheaders;
        
        if($seqnum == 1){
            
			$singletons++;
		
        }
		
        $sum_seqnum=$sum_seqnum+$seqnum;
		
        my $aln_dops = Funfhmmer::Scorecons::assign_dops_score( $alnname, $FUNFAM_DIR );
		
        if($aln_dops >= 70){
			
            $highdops_ff++;
			$sum_seqs_high_dops = $sum_seqs_high_dops + $seqnum;
			$sum_s90s_high_dops = $sum_s90s_high_dops + $s90num;
		
        }
				
        $tot_s90s = $tot_s90s + $s90num;
		$tot_seqs = $tot_seqs+ $seqnum;
		$sum_dops=$sum_dops+$aln_dops;

        # get EC purity of the clusters
        my ($tot_uniprot_num, $uniprots_withec, $ecnum, $mostcommon_ECnum_present_in) = &get_ec_purity($PROJECT_BENCHMARK_DIR, $aln, $annofile, $anno_type);

		if($tot_uniprot_num){
                    
            $ff_ecinfo++;
			my $mostcommon_ECnum_percentage = ( $mostcommon_ECnum_present_in / $uniprots_withec ) * 100; #$uniq_md5_ec

            print EC_PURITY "$project_id\t$alnname\t$aln_dops\t$ecnum\t$uniprots_withec ($tot_uniprot_num)\t$mostcommon_ECnum_present_in\t$mostcommon_ECnum_percentage\n";
            
            print "$project_id\t$alnname\t$aln_dops\t$ecnum\t$uniprots_withec ($tot_uniprot_num)\t$mostcommon_ECnum_present_in\t$mostcommon_ECnum_percentage\n";

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
    }
      
    close EC_PURITY;
    
#calculate cluster aln stats
        
	my $s90_high_dops_percent = ($sum_s90s_high_dops/$tot_s90s) * 100;
	$s90_high_dops_percent = nearest(0.01, $s90_high_dops_percent);
	
	my $seqnum_high_dops_percent = ($sum_seqs_high_dops/$tot_seqs) * 100;
	$seqnum_high_dops_percent = nearest(0.01, $seqnum_high_dops_percent);
    
    my $avg_dops = $sum_dops/$ffnum;
	$avg_dops = nearest(0.01, $avg_dops);
	
	my $avg_seqnum = $sum_seqnum/$ffnum;
	$avg_seqnum = nearest(0.01, $avg_seqnum);
	
    my $highdops_ff_p = ($highdops_ff/$ffnum) * 100;
	$highdops_ff_p = nearest(0.01, $highdops_ff_p);
	
    my $singletons_p = ($singletons/$ffnum) * 100;
	$singletons_p = nearest(0.01, $singletons_p);
            
    # Calculate EC benchmarking stats only if >1 FunFams have EC info
    if ($ff_ecinfo > 0) {

		my $ff_ecinfo_p = ($ff_ecinfo/$ffnum) * 100;
		$ff_ecinfo_p = nearest(0.01, $ff_ecinfo_p);
		
		my $p80_p = ($p80/$ff_ecinfo) * 100;
		$p80_p = nearest(0.01, $p80_p);
		
		my $p90_p = ($p90/$ff_ecinfo) * 100;
		$p90_p = nearest(0.01, $p90_p);
		
        my $p100_p = ($p100/$ff_ecinfo) * 100;
		$p100_p = nearest(0.01, $p100_p);

		#print stats
		print STATS "$project_id\t$sc_num{$project_id}\t$ffnum\t$highdops_ff_p\t$s90_high_dops_percent\t$seqnum_high_dops_percent\t$avg_dops\t$avg_seqnum\t$singletons_p\t$ff_ecinfo_p\t$p80_p\t$p90_p\t$p100_p\n";
        
    }
    else{
            
        print STATS "$project_id\t$sc_num{$project_id}\t$ffnum\t$highdops_ff_p\t$s90_high_dops_percent\t$seqnum_high_dops_percent\t$avg_dops\t$avg_seqnum\t$singletons_p\tNA\tNA\tNA\tNA\n";
            
    }
    
	print "Benchmarking results can be found here: $PROJECT_BENCHMARK_DIR/\n\n";
}

close STATS;

sub get_ec_purity{

    my ($dir, $aln, $annofile, $anno_type) = @_;
    my @array;
    
	$anno_type= lc($anno_type);
    my $alnname = basename($aln);
    
    my $FF_anno_type_dir = path("$dir/$anno_type");
    
    unless($FF_anno_type_dir->exists){
        $FF_anno_type_dir->mkpath;
    }
    
    my $ff_annofile = path( "$FF_anno_type_dir/FF.$alnname.uniprot.ec.$anno_type.anno" );
    my $ffanno_fh = $ff_annofile->openw;
    
    my @seqheaders = `LC_ALL=C fgrep ">" $aln`;
    
    # get list of uniprot_accs
    my %ffids=();

    foreach my $id (@seqheaders){
        
        $id=~/\>(\w+)/;
        my $acc =$1;
        $ffids{$acc}=1;
    
    }

    my $tot_uniprot_num = keys %ffids;

    # get ECs for list of md5s
    my %ec_hash=();my %uniprot_hash=();

    foreach my $id (keys %ffids){
        
        my @lines = `fgrep -w "$id" $annofile`;
        
        foreach my $line (@lines){
            
            chomp($line);
            my ($uniprotid, $ecs, $uniprot_entry_type) = split("\t", $line);
            
            if (($anno_type eq "all") || ($anno_type eq "swissprot" && $uniprot_entry_type eq "Swiss-Prot" )) {
                
                print $ffanno_fh "$line\n";
                my @ec_numbers = split(";", $ecs);
            
                foreach my $ec_num (@ec_numbers){
                    
                    if ($ec_num=~ /\d\.\d+\.\d+\.\d+/) {
                    
                        $ec_hash{$ec_num}++;
                        $uniprot_hash{$uniprotid}=1;
                    
                    }
                }
            
            }
            
        }
    }
    
    #delete empty EC annotation file incase of no EC annotations
    if(-z "$ff_annofile"){
        unlink("$ff_annofile");
    }

    my $uniprots_withec = keys %uniprot_hash;

    #print Dumper (\%uniprot_hash);
    #print Dumper (\%ec_hash);

    if($uniprots_withec > 1){

        foreach my $ecnum (sort {$ec_hash{$b} <=> $ec_hash{$a}} keys %ec_hash){

            my $mostcommon_ECnum_present_in = $ec_hash{$ecnum};

            return($tot_uniprot_num, $uniprots_withec, $ecnum, $mostcommon_ECnum_present_in);

            last;

        }
    }
    else{
        
        return 0;
    
    }

}

