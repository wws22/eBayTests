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

if( ! $ARGV[0] ){
    print "Usage: fetchtoken.pl <Session_ID>  >.user_token\n";
    exit '65';
}
my $sessionID = $ARGV[0];

# Create a user agent object
my $ua = LWP::UserAgent->new(%LWP_OPT);

# Prepare the request object
my $req = EbayApiRequest->new( 'FetchToken' );
my $body=<<'_EOT_';
<?xml version="1.0" encoding="utf-8"?>
<FetchTokenRequest xmlns="urn:ebay:apis:eBLBaseComponents">
    <RequesterCredentials>
        <eBayAuthToken>_TOKEN_</eBayAuthToken>
    </RequesterCredentials>
    <MessageID>002</MessageID>
    <SessionID>_SESSION_ID_</SessionID>
</FetchTokenRequest>
_EOT_
$body =~ s/_TOKEN_/$MAIN_TOKEN/ms;
$body =~ s/_SESSION_ID_/$sessionID/ms;

# Apply the content
$req->content($body);

# Pass request to the user agent and get a response back
my $res = $ua->request($req);

# Check the outcome of the response
if(! $res->is_success){
    die 'Request failed: '.$res->status_line."\n";
}

my $xpa = XML::XPath->new( xml => $res->content );
if( $xpa->getNodeText('/FetchTokenResponse/Ack') ne 'Success' ){
    die "Request has no SUCCESS flag:\n".$res->content."\n";
}
my $token = $xpa->getNodeText('/FetchTokenResponse/eBayAuthToken');
if( $token eq q{} ){
    die "Something wrong:\n".$res->content."\n";
}else{
    print STDERR "Client's token was fetched successfully. Expired at:".
        $xpa->getNodeText('/FetchTokenResponse/HardExpirationTime')."\n";
    print $xpa->getNodeText('/FetchTokenResponse/eBayAuthToken')."\n";
}

1;
__END__
<FetchTokenResponse
  xmlns="urn:ebay:apis:eBLBaseComponents">
  <Timestamp>2018-11-04T09:06:54.082Z</Timestamp>
  <Ack>Success</Ack>
  <Version>1031</Version>
  <Build>E1031_CORE_APISIGNIN_18564253_R1</Build>
  <eBayAuthToken>...</eBayAuthToken>
<HardExpirationTime>2020-04-27T09:02:02.000Z</HardExpirationTime>
</FetchTokenResponse>