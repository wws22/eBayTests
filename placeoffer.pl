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
Readonly my $USAGE_CODE => 65; # Status code for exit with USAGE info
Readonly my $BID_TOO_LOW => '12210'; # Bid Too Low

if( not defined($USER_TOKEN) or $USER_TOKEN eq q{} ){
    print "You have to fetch the client's identification token at first.\n".
        "Please use fetchtoken.pl\n";
    exit $USAGE_CODE;
}

if( not $ARGV[1] > 0 or not looks_like_number($ARGV[1]) or $ARGV[1] <= 0  ){
    print "Usage: placeoffer.pl <ItemID> <MaxBid> [CurrencyID]\n";
    exit $USAGE_CODE;
}
my $ItemID = $ARGV[0];
my $MaxBid = $ARGV[1];
my $CurrencyID = 'USD';
if( defined($ARGV[2]) ){
    $CurrencyID = $ARGV[2];
}

main();

sub main {
    my %user = get_user();   # Fetch the current UserID and another required info
    # It's not necessary to PlaceOffer but this info is needed to analyze the result of the bid.

    # Create a user agent object
    my $ua = LWP::UserAgent->new(%LWP_OPT);

    my $xml=testxml();
    if( $xml eq q{} ) {

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
        $xml = $res->content;
    }
    my $xpa = XML::XPath->new(xml => $xml);

    my $status = $xpa->getNodeText('/PlaceOfferResponse/Ack');
    if( $status ne 'Success' ){

        my $err = $xpa->getNodeText('/PlaceOfferResponse/Errors/ErrorCode');
        if( $err eq $BID_TOO_LOW ){
            print "Bid too low\n";
            return 0;
        }else{
            # Cluck
            my $doc = XMLin $xml, forcearray => 1;

            cluck "Something wrong during request!\n".
                "----------------------------------------------\n".
                (XMLout $doc, xmldecl => 1, rootname => 'PlaceOfferResponse').
                "----------------------------------------------\n".
                "LongMessage: ".
                    decode_entities($xpa->getNodeText('/PlaceOfferResponse/Errors/LongMessage'))."\n";

            # Check bidder
            if( $xpa->getNodeText('/PlaceOfferResponse/SellingStatus/HighBidder/UserID') ne $user{UserID} ) {
                return 0;
            }
        }
    }

    my $CurrentPrice = $xpa->getNodeText('/PlaceOfferResponse/SellingStatus/CurrentPrice');

    if( $xpa->getNodeText('/PlaceOfferResponse/SellingStatus/ReserveMet') eq 'false' ){
        print 'Reserve not meet! Current price: '.$CurrentPrice."\n";
        return 0;
    }

    if( $xpa->getNodeText('/PlaceOfferResponse/SellingStatus/HighBidder/UserID') eq $user{UserID} ){
        # We almost win
        print 'We are the highest bidder! Current price: '.$CurrentPrice."\n";
    }else{
        # Another bidder win
        print 'You are not the highest bidder! Current price: '.$CurrentPrice."\n";
        return 0;
    }
    #my $doc = XMLin $xml, forcearray => 1;
    #print XMLout $doc, xmldecl => 1, rootname => 'PlaceOfferResponse';

    return 1;
}

sub get_user {
    my $ua = LWP::UserAgent->new(%LWP_OPT);
    my $req = EbayApiRequest->new('GetUser');
    my $body = <<'_EOT_';
<?xml version="1.0" encoding="utf-8"?>
<GetUserRequest xmlns="urn:ebay:apis:eBLBaseComponents">
  <RequesterCredentials>
    <eBayAuthToken>_TOKEN_</eBayAuthToken>
  </RequesterCredentials>
</GetUserRequest>
_EOT_
    $body =~ s/_TOKEN_/$USER_TOKEN/gms;
    $req->content($body);

    my $res = $ua->request($req);
    if (!$res->is_success) {
        die 'GetUser request failed: ' . $res->status_line . "\n";
    }
    my $xpa = XML::XPath->new(xml => $res->content);
    if( $xpa->getNodeText('/GetUserResponse/Ack') ne 'Success' ){
        my $doc = XMLin $res->content, forcearray => 1;
        die "GetUser request failed:\n".(XMLout $doc, xmldecl => 1, rootname => 'GetUserResponse')."\n";
    }
    my %user;
    $user{Email} = $xpa->getNodeText('/GetUserResponse/User/Email').q{};
    $user{UserID} = $xpa->getNodeText('/GetUserResponse/User/UserID').q{};
    return %user;
}

sub testxml(){
    return q{};
}

1;
__END__
    return << '_EOT_';
<?xml version='1.0' standalone='yes'?>
<PlaceOfferResponse xmlns="urn:ebay:apis:eBLBaseComponents">
  <Ack>Failure</Ack>
  <Errors>
    <ErrorClassification>RequestError</ErrorClassification>
    <ErrorCode>21916658</ErrorCode>
    ...
    <LongMessage>Your bid amount should be higher than your last bid.</LongMessage>
    <SeverityCode>Error</SeverityCode>
    <ShortMessage>Invalid bid for high bidder</ShortMessage>      !!! OK
  </Errors>
  ...
</PlaceOfferResponse>
_EOT_

