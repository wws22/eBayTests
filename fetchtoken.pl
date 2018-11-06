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

use EbayConfig qw(
    %LWP_OPT
    $SIGNIN_ENDPOINT
    $RUNAME
    $MAIN_TOKEN
    $USER_TOKEN_FILE
    $USER_TOKEN
);

use Readonly;
Readonly my $NOT_READY_CODE => '21916017'; # The end user has not completed Auth
Readonly my $STRANGE_NOT_READY_CODE => '16117'; # The end user login but didn't make permission yet
Readonly my $USAGE_CODE => 65; # Status code for exit with USAGE info

if( ! $ARGV[0] ){
    print "Usage: fetchtoken.pl <Session_ID>\n";
    exit $USAGE_CODE;
}
my $sessionID = $ARGV[0];

main();

sub main {
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
    $body =~ s/_TOKEN_/$MAIN_TOKEN/gms;
    $body =~ s/_SESSION_ID_/$sessionID/gms;

    # Apply the content
    $req->content($body);

    # Pass request to the user agent and get a response back
    my $res = $ua->request($req);

    # Check the outcome of the response
    if(! $res->is_success){
        die 'Request failed: '.$res->status_line."\n";
    }

    my $xpa = XML::XPath->new( xml => $res->content );
    my $code = $xpa->getNodeText('/FetchTokenResponse/Ack');
    if( $code ne 'Success' ){
        if( $code eq 'Failure' ){
            my $err = $xpa->getNodeText('/FetchTokenResponse/Errors/ErrorCode');
            if(  $err eq $NOT_READY_CODE ){
                print decode_entities($xpa->getNodeText('/FetchTokenResponse/Errors/ShortMessage'))."\n";
                return 0;
            }elsif( $err eq $STRANGE_NOT_READY_CODE ){
                print "The end user login but didn't make permission yet. That is very strange error!\n";
                print "Really      : The end user has not completed Auth & Auth sign in flow.\n";
                print "But Error is: ".decode_entities($xpa->getNodeText('/FetchTokenResponse/Errors/ShortMessage'))."\n";
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