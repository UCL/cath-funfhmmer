package Funfhmmer::Anno;

=head1 NAME

Funfhmmer::Anno - module to annotate sequence cluster files

=head1 SYNOPSIS

	use Funfhmmer::Anno

=head1 DESCRIPTION

This is used to get EC annotations for uniprot accessions from EBI Proteins API

=cut

use strict;
use warnings;

# modules
use FindBin;
use File::Basename;
use File::Copy;
use Exporter qw(import);
use Path::Tiny;
use HTTP::Tiny;
use JSON::MaybeXS;
use List::MoreUtils qw(uniq);

# Funfhmmer modules
use lib "$FindBin::Bin/../lib";

our @EXPORT_OK = qw(get_uniprot_anno_for_uniprot_list get_api_response get_SP_data get_ec_data);

=head1 METHODS

=head2 get_uniprot_anno_for_uniprot_list()


	get_uniprot_anno_for_uniprot_list( $uniprot_list_filepath, $output_annofile )

=cut

sub get_uniprot_anno_for_uniprot_list{
	
	my ($uniprot_list_filepath, $output_annofile) = @_;
	
    # get the uniprot accessions to query
    my $accslist = path( $uniprot_list_filepath );
    my $out_file = path( $output_annofile );

    my $listname = basename( $accslist );

    my $results_fh = $out_file->openw;
    print "Getting latest UniProtKB annotations for $listname\n";

    my @lines = path( $accslist )->lines( { chomp => 1 } );

    # store response data if acc has an EC number
    my %response_data;

    # feed each accession into API
    my %ec_numbers;
    my %lines_to_print;
    
    foreach my $acc ( @lines ) {
        
        chomp($acc);
    
        #print "Getting API response for: $acc...\n";
        my $response_data = get_api_response( $acc  );

        #print Dumper $response_data;

        # get any EC data out
        my @ec_numbers = get_ec_data( $response_data );
        my @uniq_ecs = uniq(@ec_numbers);
        my $ec_string = join(';', @uniq_ecs);
        
        # get Swiss-Prot or not data
        my $review = get_SP_data( $response_data );
        
        if ($ec_string) {
            
            if($review){
                
                print $results_fh "$acc\t$ec_string\t$review\n";
            
            }
            
        }
                
    }

    print "\n\nCompleted generating EC and Swiss-Prot annotations.\nAnno file: $out_file\n\n";
    
}

sub get_api_response {
    my $acc = shift ;
	
	# create http and json data objects
    my $http = HTTP::Tiny->new();
    my $json = JSON->new;
	
	# API base url
    my $base_url = "https://www.ebi.ac.uk/proteins/api/proteins/";
	
    my $request_url = $base_url . $acc;

    my $response = $http->get($request_url, {
        headers => { 'Accept' => 'application/json' }
    });

    # do not die if failed response, move on
    if ( ! $response->{success} ) {
        my $status = $response->{status};
        my $reason = $response->{reason};
        my $msg = "API response failed for '$acc' (URL: $request_url, STATUS: $status, REASON: $reason)";
        print( "-- WARNING: $msg\n" );
        return;
    }

    # parses JSON text and returns a simple scalar or reference
    my $response_data = $json->decode( $response->{content} );

    return $response_data;
}

sub get_SP_data {
  my $response_data = shift;
  if($response_data->{info}->{type}){
    my $entry_type = $response_data->{info}->{type};
    return $entry_type;
  }
  return 0;
}

sub get_ec_data {
    my $response_data = shift;

    # INFO Dumper $response_data;

    # INFO Dumper $response_data->{dbReferences};
    # check whether the protein accession has a recommended or submitted name
    my @ec_numbers;my @ecs;
    if ( $response_data->{protein}->{recommendedName}->{ecNumber} ) {

        @ecs = @{ $response_data->{protein}->{recommendedName}->{ecNumber} };
          foreach my $f ( @ecs ) {
              push(@ec_numbers, $f->{"value"});
            }


    }
    if ( $response_data->{protein}->{submittedName} ) {
        # if there is an EC number field, extract the information, otherwise return nothing
        # INFO Dumper $response_data->{protein}->{submittedName};
        my $submitted_name = $response_data->{protein}->{submittedName};

        foreach my $submitted_name_entry ( @$submitted_name ) {
            if ( $submitted_name_entry->{ecNumber} ) {
                @ecs = @{ $submitted_name_entry->{ecNumber} };

                foreach my $f ( @ecs ) {
                    unless( grep( /^$f$/, @ec_numbers ) ){
                      push(@ec_numbers, $f->{"value"});
                    }
                  }

            }
        }
      }

    return @ec_numbers;
}

1;
