#!/usr/bin/perl

use strict;
use warnings;
use Net::SSL;
use LWP::UserAgent;
use version; our $VERSION = qv(1.01);
use EbayApiRequest;

use EbayConfig qw(
    %LWP_OPT
    $API_COMPATIBILITY_LEVEL
    $API_ENDPOINT
    $SITEID
    $RUNAME
    $APP_NAME
    $DEV_NAME
    $CERT_NAME
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
$body =~ s/_TOKEN_/$MAIN_TOKEN/ms;
$body =~ s/_RUNAME_/$RUNAME/ms;

# Apply the content
$req->content($body);

# Pass request to the user agent and get a response back
my $res = $ua->request($req);

# Check the outcome of the response
if($res->is_success){
    print $res->content, "\n";
}else{
    print $res->status_line, "\n";
}

1;