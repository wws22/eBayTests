#!/usr/bin/perl

use strict;
use warnings;
use version; our $VERSION = qv(1.01);
use Net::SSL;
use LWP::UserAgent;
use EbayApiRequest;
use XML::XPath;
use XML::XPath::XMLParser;

use EbayConfig qw(
    %LWP_OPT
    $USER_TOKEN
    $MAIN_TOKEN
);

my $forced = ( defined($ARGV[0])  ?  ( $ARGV[0] eq '--force' ) : 0 );
unless( are_tokens_different($forced) or $forced ){
    die "The MAIN_TOKEN is the same as USER_TOKEN. Use --force to revoke it\n";
}

# Create a user agent object
my $ua = LWP::UserAgent->new(%LWP_OPT);

# Prepare the request object
my $req = EbayApiRequest->new( 'RevokeToken' );
my $body=<<'_EOT_';
<?xml version="1.0" encoding="utf-8"?>
<RevokeTokenRequest xmlns="urn:ebay:apis:eBLBaseComponents">
  <RequesterCredentials>
    <eBayAuthToken>_TOKEN_</eBayAuthToken>
  </RequesterCredentials>
	<ErrorLanguage>en_US</ErrorLanguage>
	<WarningLevel>High</WarningLevel>
</RevokeTokenRequest>
_EOT_
$body =~ s/_TOKEN_/$USER_TOKEN/gms;

# Apply the content
$req->content($body);

# Pass request to the user agent and get a response back
my $res = $ua->request($req);

# Check the outcome of the response
if(! $res->is_success){
    die 'Request failed: '.$res->status_line."\n";
}

my $xpa = XML::XPath->new( xml => $res->content );
my $status = $xpa->getNodeText('/RevokeTokenResponse/Ack');

if( $status ne q{Success} ){
    die $res->content."\n";
}else{
    print "Token revoked successfully.\n";
}

sub are_tokens_different {
    # Return 1 when tokens are different
    my $forced = shift;
    if($MAIN_TOKEN ne $USER_TOKEN){
        my $msg =
              "======================= Main ==========================\n"
            . $MAIN_TOKEN."\n"
            . "======================= User ==========================\n"
            . $USER_TOKEN."\n"
            . "======================= Diff ==========================\n";
        my $count = 0;
        for(my $i=0;$i<=length($MAIN_TOKEN);$i++){
            if( substr($MAIN_TOKEN,$i,1) eq substr($USER_TOKEN,$i,1) ){
                $msg .= substr($MAIN_TOKEN,$i,1);
            }else{
                $msg .= "\n!";
                $count++;
            }
        }
        if($count < 30 ){
            print STDERR $msg."\n" unless $forced;
            return 0;
        }
        return 1;
    }else{
        return 0;
    }
}

1;