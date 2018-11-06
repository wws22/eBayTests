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
    $USER_TOKEN
);

use Readonly;
Readonly my $USAGE_CODE => 65; # Status code for exit with USAGE info

if( not defined($USER_TOKEN) or $USER_TOKEN eq q{} ){
    print "You have to fetch the client's identification token at first.\n".
        "Please use fetchtoken.pl\n";
    exit $USAGE_CODE;
}

if( ! defined($ARGV[0])  ){
    print "Usage: getitemstatus.pl <ItemID>\n";
    exit $USAGE_CODE;
}

my $ItemID = $ARGV[0];

main();

sub main {
    my %user = get_user();   # Fetch the current UserID and another required info
    # It's not necessary to PlaceOffer but this info is needed to analyze the result of the bid.

    # Create a user agent object
    my $ua = LWP::UserAgent->new(%LWP_OPT);

    my $xml=testxml();
    if( $xml eq q{} ) {

        # Prepare the request object
        my $req = EbayApiRequest->new('GetItem');
        # https://developer.ebay.com/DevZone/build-test/test-tool/default.aspx?index=0&api=trading&call=GetItem&variation=xml
        my $body = <<'_EOT_';
<?xml version="1.0" encoding="utf-8"?>
<GetItemRequest xmlns="urn:ebay:apis:eBLBaseComponents">
    <RequesterCredentials>
        <eBayAuthToken>_TOKEN_</eBayAuthToken>
    </RequesterCredentials>
    <MessageID>004</MessageID>
    <ItemID>_ITEM_ID_</ItemID>
</GetItemRequest>
_EOT_
        $body =~ s/_TOKEN_/$USER_TOKEN/gms;
        $body =~ s/_ITEM_ID_/$ItemID/gms;

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

    my $status = $xpa->getNodeText('/GetItemResponse/Ack');
    if( $status ne 'Success' ){

        my $err = $xpa->getNodeText('/GetItemResponse/Errors/ErrorCode');
        my $doc = XMLin $xml, forcearray => 1;

        croak "Something wrong during request!\n".
            "----------------------------------------------\n".
            (XMLout $doc, xmldecl => 1, rootname => 'GetItemResponse').
            "----------------------------------------------\n".
            "LongMessage: ".
                decode_entities($xpa->getNodeText('/GetItemResponse/Errors/LongMessage'))."\n";

    }

    my $CurrentPrice = $xpa->getNodeText('/GetItemResponse/Item/SellingStatus/CurrentPrice');
    my $ListingStatus =  $xpa->getNodeText('/GetItemResponse/Item/SellingStatus/ListingStatus');

    if( $xpa->getNodeText('/GetItemResponse/Item/SellingStatus/ReserveMet') eq 'false' ){
        print 'Reserve not meet! ListingStatus: <'.$ListingStatus.'> '.
            'Current price: '.$CurrentPrice."\n";
        return 0;
    }

    if( $xpa->getNodeText('/GetItemResponse/Item/SellingStatus/HighBidder/UserID') eq $user{UserID} ){
        # We almost win
        print 'We are the highest bidder! ListingStatus: <'.$ListingStatus.'> '.
            'Current price: '.$CurrentPrice."\n";

        # Check the finish
        if( $ListingStatus ne 'Completed' && $ListingStatus ne 'Ended' ){
            return 0;
        }

    }else{
        # Another bidder win
        print 'You are not the highest bidder! ListingStatus: <'.$ListingStatus.'> '.
            'Current price: '.$CurrentPrice."\n";
        return 0;
    }
    #my $doc = XMLin $xml, forcearray => 1;
    #print XMLout $doc, xmldecl => 1, rootname => 'GetItemResponse';

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
<?xml version="1.0" encoding="UTF-8"?>
<GetItemResponse
xmlns="urn:ebay:apis:eBLBaseComponents">
<Timestamp>2018-11-05T08:46:24.612Z</Timestamp>
<Ack>Success</Ack>
<Version>1069</Version>
<Build>E1069_CORE_API_18753429_R1</Build>
<Item>
    <ItemID>110385114130</ItemID>
    <SellingStatus>
        <BidCount>16</BidCount>
        <CurrentPrice currencyID="USD">10.0</CurrentPrice>
        <HighBidder>
            <UserID>t***s</UserID>
        </HighBidder>
        <ListingStatus>Active</ListingStatus>
    </SellingStatus>
</Item>
</GetItemResponse>
_EOT_
