#!/usr/bin/perl

use strict;
use warnings;
use version; our $VERSION = qv(1.01);
use Net::SSL;
use LWP::UserAgent;
use EbayApiRequest;
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

if( !defined($USER_TOKEN) or $USER_TOKEN eq '' ){
    print "You have to fetch the client's identification token at first.\n".
        "Please use fetchtoken.pl\n";
    exit 65;
}

if( ! $ARGV[1] > 0 or ! looks_like_number($ARGV[1]) or $ARGV[1] <= 0  ){
    print "Usage: placeoffer.pl <ItemID> <MaxBid> [CurrencyID]\n";
    exit '65';
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
print $body."\n======================\n";
    # Apply the content
    $req->content($body);

    # Pass request to the user agent and get a response back
    my $res = $ua->request($req);

    # Check the outcome of the response
    if (!$res->is_success) {
        die 'Request failed: ' . $res->status_line . "\n";
    }

    my $xpa = XML::XPath->new(xml => $res->content);
    print $res->content . "\n";
}
__END__

    my $code = $xpa->getNodeText('/FetchTokenResponse/Ack');
    if( $code ne 'Success' ){
        if( $code eq 'Failure' ){
            if( $xpa->getNodeText('FetchTokenResponse/Errors/ErrorCode') == $NOT_READY_CODE ){
                print decode_entities($xpa->getNodeText('FetchTokenResponse/Errors/ShortMessage'))."\n";
                return 0;
            }
        }
        die "Request has no SUCCESS flag:\n".$res->content."\n";
    }
    my $token = $xpa->getNodeText('/FetchTokenResponse/eBayAuthToken');
    if( $token eq q{} ){
        die "Something wrong:\n".$res->content."\n";
    }else{

        if( $USER_TOKEN_FILE ne q{ } ){
            if( open( my $fh, '>', $USER_TOKEN_FILE ) ) {
                print $fh $token;
                close($fh) or croak "Can't close $USER_TOKEN_FILE\n";
                print "Client's token was fetched successfully into: '$USER_TOKEN_FILE'. Token will expire at: ".
                    $xpa->getNodeText('/FetchTokenResponse/HardExpirationTime')."\n";
            }
        }else{
            print STDERR "Client's token was fetched successfully. Token will expire at: ".
                $xpa->getNodeText('/FetchTokenResponse/HardExpirationTime')."\n";
            print $token."\n";
        }
    }
    return 1;
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