#!/usr/bin/perl

use strict;
use warnings;
use version; our $VERSION = qv(1.01);
use Net::SSL;
use LWP::UserAgent;
use EbayApiRequest;
use XML::XPath;
use XML::XPath::XMLParser;
use XML::Simple;

use EbayConfig qw(
    %LWP_OPT
    $USER_TOKEN
);

# Create a user agent object
my $ua = LWP::UserAgent->new(%LWP_OPT);

# Prepare the request object
my $req = EbayApiRequest->new( 'GetApiAccessRules' );
my $body=<<'_EOT_';
<?xml version="1.0" encoding="utf-8"?>
<GetApiAccessRulesRequest xmlns="urn:ebay:apis:eBLBaseComponents">
  <RequesterCredentials>
    <eBayAuthToken>_TOKEN_</eBayAuthToken>
  </RequesterCredentials>
	<ErrorLanguage>en_US</ErrorLanguage>
	<WarningLevel>High</WarningLevel>
</GetApiAccessRulesRequest>
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
my $usage = $xpa->getNodeText('//ApiAccessRule[CallName="ApplicationAggregate"]/DailyUsage');

if( $usage ne q{} ){
    print "Timestamp   : ".$xpa->getNodeText('/GetApiAccessRulesResponse/Timestamp')."\n";
    print "ModTime     : ".$xpa->getNodeText('//ApiAccessRule[CallName="ApplicationAggregate"]/ModTime')."\n";
    print "Hourly usage: ".$xpa->getNodeText('//ApiAccessRule[CallName="ApplicationAggregate"]/HourlyUsage')."\n";
    print "Daily  usage: $usage\n";
}else{
    die XMLout( XMLin($res->content, forcearray => 1), xmldecl => 1, rootname => 'GetApiAccessResponse');
}

1;