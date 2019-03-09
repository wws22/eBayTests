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
    $SIGNIN_ENDPOINT
    $RUNAME
    $MAIN_TOKEN
);

# Create a user agent object
my $ua = LWP::UserAgent->new(%LWP_OPT);

# Prepare the request object
my $req = EbayApiRequest->new( 'GetSessionID' );
my $body=<<'_EOT_';
<?xml version="1.0" encoding="utf-8"?>
<GetSessionIDRequest xmlns="urn:ebay:apis:eBLBaseComponents">
  <RequesterCredentials>
    <eBayAuthToken>_TOKEN_</eBayAuthToken>
  </RequesterCredentials>
    <RuName>_RUNAME_</RuName>
    <MessageID>001</MessageID>
</GetSessionIDRequest>
_EOT_
$body =~ s/_TOKEN_/$MAIN_TOKEN/gms;
$body =~ s/_RUNAME_/$RUNAME/gms;

# Apply the content
$req->content($body);

# Pass request to the user agent and get a response back
my $res = $ua->request($req);

# Check the outcome of the response
if(! $res->is_success){
    die 'Request failed: '.$res->status_line."\n";
}

my $xpa = XML::XPath->new( xml => $res->content );
my $sessionID = $xpa->getNodeText('/GetSessionIDResponse/SessionID');

if( $sessionID eq q{} ){
    die "There are no SessioID in response:\n".$res->content."\n";
}

print $SIGNIN_ENDPOINT.'?SignIn&RUName='.$RUNAME.'&SessID='.$sessionID."\n";

1;