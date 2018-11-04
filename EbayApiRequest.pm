package EbayApiRequest;

use strict;
use warnings;
use version; our $VERSION = qv(1.01);
use base qw(HTTP::Request);

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
    $USER_TOKEN
    $USER_TOKEN_FILE
);

sub new {
    my @p = @_;
    my $proto = shift(@p);
    my $class = ref($proto) || $proto;
    my $call; # X-EBAY-API-CALL-NAME
    my $self;
    if(@p){   # Additional params reached
        if(scalar( @p ) % 2 == 0){ # Looks good
            my %hash = @p;
            die "Missed X-EBAY-API-CALL-NAME in $proto\n" if ! exists($hash{CALL});
            $call=$hash{CALL};
            delete $hash{CALL};
            $hash{POST}=$API_ENDPOINT;
            $self = $class->SUPER::new(%hash);
        }else{
            $call = shift(@p);
            push @p, (POST => $API_ENDPOINT);
            $self = $class->SUPER::new(@p);
        }
    }else{
        die "Missed X-EBAY-API-CALL-NAME in $proto\n";
    }
    bless $self, $class;
    $self->addHeaders;
    $self->header('X-EBAY-API-CALL-NAME',$call);
    return $self;
}

sub addHeaders { # Internal method
    my $req =  shift;
    $req->header( 'X-EBAY-API-SITEID' => $SITEID);
    $req->header( 'X-EBAY-API-COMPATIBILITY-LEVEL' => $API_COMPATIBILITY_LEVEL);
    $req->header( 'X-EBAY-API-APP-NAME' => $APP_NAME);
    $req->header( 'X-EBAY-API-DEV-NAME' => $DEV_NAME);
    $req->header( 'X-EBAY-API-CERT-NAME' => $CERT_NAME);
    return 1;
}

sub DESTROY {
    my $self = shift;
    return 1;
}

1;

__END__

=pod

=head1 NAME

EbayApiRequest

=head1 VERSION

1.01

=head1 DESCRIPTION

eBay API request handler. Based on HTTP::Request

=head1 SYNOPSIS

    use EbayApiRequest;
    use LWP::UserAgent;
    use eBayConfig qw(
        %LWP_OPT
        $RUNAME
        $MAIN_TOKEN
    );
    # Create a user agent object
    my $ua = LWP::UserAgent->new( %LWP_OPT );

    # Create Ebay Api Request object
    my $req = EbayApiRequest->new( CALL => 'GetSessionID' );
    # or my $req = EbayApiRequest->new( 'GetSessionID' );
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

    # Apply the content
    $req->content($body);

    # Pass request to the user agent and get a response back
    my $res = $ua->request($req);

=head1 METHODS

=head2 DESTROY

  Destructor. Unused at this time

=head1 AUTHOR

Victoras-LT <noname@unknown.org>

=cut
