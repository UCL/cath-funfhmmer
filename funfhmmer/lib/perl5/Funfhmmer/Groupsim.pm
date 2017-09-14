package Funfhmmer::Groupsim;
use strict;
use warnings;
use FindBin;
FindBin::again();
use File::Basename;
use Statistics::Descriptive;
use File::Copy;

# added #new lines on 10082017 to see if new distribution features can be used to split trees

# non-core modules
use lib "$FindBin::Bin/../lib/perl5";
use File::Slurp;
use Path::Tiny;
use Exporter qw(import);

our $bindir = path($FindBin::Bin, "..", "bin");

our @EXPORT_OK = qw(gs_process);

sub gs_process{
	my ($input1,$input2,$dir) = @_;
	my $inputfile1 = $dir->path("$input1.aln");
	my $inputfile2 = $dir->path("$input2.aln");
	&add_cluster_num_in_aln_headers($inputfile1,$inputfile2,$dir);
	my $input_cat_num= $dir->path("$input1.$input2");
	my $input_aln = $dir->path("$input1.$input2.aln");
	Funfhmmer::Align::generate_catcluster_align($input_cat_num,$input_aln);
	
	#unlink ($input_cat_num);
	#get GROUPSIM_SCORE FILE
	my $analysis_subfolder = $dir->child("analysis_data");
	my $groupsim_rawscores = $analysis_subfolder->path("$input1.$input2.GS.rawscores");
	my $groupsim_scorefile = $analysis_subfolder->path("$input1.$input2.GS.rawscores.processed.quantitate");
	&groupsim_rollon_general($input_aln,$input1,$input2,$groupsim_rawscores,$groupsim_scorefile,$dir,$analysis_subfolder);
	# GET GROUPSIM SCORES from groupsim file!
	my @lines = $groupsim_scorefile->lines;
	my @score = split (/\t/,$lines[2]);
	return @score;
}


sub groupsim_rollon_general{
	my ($align,$grp1,$grp2,$gs_rawfile,$gs_file,$dir) = @_; 
	my $analysis_subfoldername = "analysis_data";
	#print "$FindBin::Bin\nBin Dir: $bindir\n";
	#system("ls -rtl $bindir");
	unless(-e "$gs_file"){
		#print "$grp1 $grp2\n";
		system ("python2 $bindir/group_sim_sdp.py -c 0.3 -g 0.5 $align $grp1 $grp2 > $gs_rawfile");
		if (-z "$gs_rawfile"){
			system ("python2 $bindir/group_sim_sdp_without_cons.py -c 0.3 -g 0.5 $align $grp1 $grp2 > $gs_rawfile");
		}
		&groupsim_rawscores_process_quantitate($gs_rawfile);
		unlink($gs_rawfile);
		my $gs_mergealn_name= basename("$align");
		copy($align,"$dir/$analysis_subfoldername/$gs_mergealn_name");
		unlink($align);
	}
	
} 

sub add_cluster_num_in_aln_headers{
	my ($funfam1path,$funfam2path,$dir) = @_; 
	my $funfam1 = basename($funfam1path, ".aln");
	my $funfam2 = basename($funfam2path, ".aln");
	my $filename1="$dir/$funfam1.$funfam2";
	open(INFILE, "<$funfam1path") or die "Can't open file $funfam1path\n";
	open(OUTFILE, ">$filename1") or die "Can't open file $filename1\n";
	while(my $line = <INFILE>) { 
		chomp ($line);
		if($line=~ /\>/){
			print OUTFILE "$line|$funfam1\n";
			#print "$line|$funfam\n";
			}
		else{	
			print OUTFILE "$line\n";
		}
	}
	close(INFILE);
	open(INFILE, "<$funfam2path") or die "Can't open file $funfam2path\n";
	while(my $line = <INFILE>) { 
		chomp ($line);
		if($line=~ /\>/){
			print OUTFILE "$line|$funfam2\n";
			#print "$line|$funfam\n";
			}
		else{	
			print OUTFILE "$line\n";
		}
	}
	close(INFILE);
	close(OUTFILE);
}

sub groupsim_rawscores_process_quantitate{
	my $CONSfile = shift; # the GroupSim file
	my $file = "$CONSfile.processed";
	my $bug = "# col_num	score	column";
	# now lets get the groupsim score data
	my $p=0;
	open(CONSFILE, "<$CONSfile") or die "Can't open file $CONSfile\n";
	open(OUTFILE, ">$file") or die "Can't open file $file\n";
	while(my $line = <CONSFILE>) {  # reading conservation score file
		chomp($line);
		unless($line=~ /\#/){
			#print "$line\n";
			if($line=~ /(\d*)\t(\w\w\w\w|\-?\d\.\d*)/){
				my $num = $1 + 1;
				$line =~ s/$1/$num/;
				if($p==0){
					$p++;
				}
				else{
					print OUTFILE "$line\n";
				}
			}
		}
	}
	close CONSFILE;
	close OUTFILE;
	#print "$CONSfile\n$file\n";
	#exit;

	my $x1=0; my $x2=0; my $x3=0; my $x4=0; my $x5=0;  my $none=0; my $tot=0;
	my @score_array;
	
	open(INFILE, "<$file") or die "Can't open file $file\n";
	while(my $line = <INFILE>) {  # reading groupsim score file
		$tot++;
		if($line=~ /(\d*)\t(\-?\d\.\d*)\t([\-|\w]*)\s\|\s([\-|\w]*)/){
			my $num =$1;my $score = $2; #our $a=$3;our $b=$4; chomp($a);chomp($b);
			
			if($score <= 0.3){
				$x1++;
			}
			elsif($score > 0.3 && $score <= 0.4){
				$x2++;
			}
			elsif($score >= 0.7 && $score < 0.8){
				$x4++;
			}
			elsif($score >= 0.8 && $score <= 1){
				$x5++;
			}
			else{
				$x3++;
			}
			push(@score_array,$score);
		}
		elsif($line=~ /\d*\t\w*/){
			$none++;
			push(@score_array,1.1);
		}
	}
	
	my $stat = Statistics::Descriptive::Full->new();
	$stat->add_data(@score_array);
	my $min = $stat->quantile(0);
	my $q1 = $stat->quantile(1);
	my $median = $stat->quantile(2);
	my $q3 = $stat->quantile(3);
	my $max = $stat->quantile(4);
	my ($least_squares_fit_q, $least_squares_fit_m, $least_squares_fit_r, $least_squares_fit_rms) = $stat->least_squares_fit(@score_array);
	my @linefit;
	
	#my $file3 = "$file.linefit";
	#open(OUTFILE2, ">$file3") or die "Can't open file $file3\n";
	foreach (my $x = 0; $x < 1.05; $x=$x+0.05){
		my $y = ($least_squares_fit_m * $x) + $least_squares_fit_q;
		my $point = "[$x,$y]";
		#print OUTFILE2 "$x\t$y\n";
		push(@linefit,$point);
	}
	#close OUTFILE2;
	
	my $file2 = "$file.quantitate";
	open(OUTFILE1, ">$file2") or die "Can't open file $file2\n";
	print OUTFILE1 "#No. of residues more than these Groupsim Scores:\n<=.3\t<=.4\t.4~.7\t.7<.8\t.8=1\tNone\tTot\tq1\tmedian\tq3\n";#
	print OUTFILE1 "$x1\t$x2\t$x3\t$x4\t$x5\t$none\t$tot\t$q1\t$median\t$q3\n";#
	print OUTFILE1 "#q1\tmedian\tq3\tmax\n";#new
	print OUTFILE1 "$q1\t$median\t$q3\t$max\n";#new
	print OUTFILE1 "#q\tm\tr\trms\t#linefit: y=mx+q,r,rms\n";
	print OUTFILE1 "$least_squares_fit_q\t$least_squares_fit_m\t$least_squares_fit_r\t$least_squares_fit_rms\n";
	#print OUTFILE1 "y = $least_squares_fit_m *x + $least_squares_fit_q\n";
	print OUTFILE1 "#Scorecons Line Fit\n@linefit\n";#new
	print OUTFILE1 "#Scorecons distribution (None positions as 1.1)\n@score_array\n";#new
	close OUTFILE1;
	close INFILE;
}

1;