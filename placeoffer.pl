#!/usr/bin/perl

use strict;
use warnings;
use version; our $VERSION = qv(1.01);
use Net::SSL;
use LWP::UserAgent;
use EbayApiRequest;
use XML::Simple;
use XML::XPath;
use XML::XPath::XMLParser;
use HTML::Entities;
use Carp qw(croak cluck);
use Scalar::Util qw(looks_like_number);

use EbayConfig qw(
    %LWP_OPT
    $MY_PUBLIC_IP
    $USER_TOKEN
);

use Readonly;
Readonly my $SOME_CODE => 000; # TODO!

if( not defined($USER_TOKEN) or $USER_TOKEN eq q{} ){
    print "You have to fetch the client's identification token at first.\n".
        "Please use fetchtoken.pl\n";
    exit 65;
}

if( not $ARGV[1] > 0 or not looks_like_number($ARGV[1]) or $ARGV[1] <= 0  ){
    print "Usage: placeoffer.pl <ItemID> <MaxBid> [CurrencyID]\n";
    exit 65;
}
my $ItemID = $ARGV[0];
my $MaxBid = $ARGV[1];
my $CurrencyID = 'USD';
if( defined($ARGV[2]) ){
    $CurrencyID = $ARGV[2];
}

main();

sub main {
    # Create a user agent object
    my $ua = LWP::UserAgent->new(%LWP_OPT);

    # Prepare the request object
    my $req = EbayApiRequest->new('PlaceOffer');
    # https://developer.ebay.com/DevZone/build-test/test-tool/default.aspx?index=0&api=trading&call=PlaceOffer&variation=xml
    my $body = <<'_EOT_';
<?xml version="1.0" encoding="utf-8"?>
<PlaceOfferRequest xmlns="urn:ebay:apis:eBLBaseComponents">
<!-- This call works only in Sandbox. To use this call in Production, the APPID needs to be whitelisted-->
    <RequesterCredentials>
        <eBayAuthToken>_TOKEN_</eBayAuthToken>
    </RequesterCredentials>
    <MessageID>003</MessageID>
    <EndUserIP>_END_USER_IP_</EndUserIP>
    <ItemID>_ITEM_ID_</ItemID>
    <Offer>
        <Action>Bid</Action>
        <Quantity>1</Quantity>
        <MaxBid currencyID="_CURRENCY_ID_">_MAX_BID_</MaxBid>
    </Offer>
</PlaceOfferRequest>
_EOT_
    $body =~ s/_TOKEN_/$USER_TOKEN/gms;
    $body =~ s/_ITEM_ID_/$ItemID/gms;
    $body =~ s/_END_USER_IP_/$MY_PUBLIC_IP/gms;
    $body =~ s/_CURRENCY_ID_/$CurrencyID/gms;
    $body =~ s/_MAX_BID_/$MaxBid/gms;

    # Apply the content
    $req->content($body);

    # Pass request to the user agent and get a response back
    my $res = $ua->request($req);

    # Check the outcome of the response
    if (!$res->is_success) {
        die 'Request failed: ' . $res->status_line . "\n";
    }

    my $xpa = XML::XPath->new(xml => $res->content);
    my $code = $xpa->getNodeText('/FetchTokenResponse/Ack');
    if( $code ne 'Success' ){

    }

    my $doc = XMLin $res->content, forcearray => 1;
    print XMLout $doc, xmldecl => 1, rootname => 'PlaceOfferResponse';

    return 1;
}

1;
__END__


