package EbayConfig;
use strict;
use warnings;
use version; our $VERSION = qv(1.01);
use Carp qw(cluck croak);

use Exporter 'import';
our @EXPORT_OK   = qw(
    %LWP_OPT
    $MY_PUBLIC_IP
    $API_COMPATIBILITY_LEVEL
    $SIGNIN_ENDPOINT
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
our $USER_TOKEN_FILE = './.user_token'; # Temporary storage for user's token

require '.eBay.conf';


use English qw(-no_match_vars);
our $USER_TOKEN;
if( -e $USER_TOKEN_FILE ){
    if( open( my $fh, '<', $USER_TOKEN_FILE ) ) {
        local $RS = undef;
        $USER_TOKEN = <$fh>;
        close($fh) or cluck "Can't close $USER_TOKEN_FILE\n";
        $USER_TOKEN =~ s/\n*$//xms;
    }
}

1;
__END__
# Put these line in .eBay.conf
#
use strict;
use warnings;
#
our $API_COMPATIBILITY_LEVEL = '1031';
our $MY_PUBLIC_IP = 'XXX.XXX.XXX.XXX';  # The public IP address of the machine from which the request is sent.
                                        # Your application captures that IP address and includes it in a call request.
                                        # eBay evaluates requests for safety (also see the BotBlock container
                                        # in the request and response of this call).

our $SIGNIN_ENDPOINT = 'https://signin.sandbox.ebay.com/ws/eBayISAPI.dll';
our $API_ENDPOINT = 'https://api.sandbox.ebay.com/ws/api.dll';
our %LWP_OPT = ( ssl_opts => { verify_hostname => 0 }, # Use 0 for sandbox
                 agent => 'MyApp/0.1'                  # User-Agent string
);
our $SITEID = '0';
our $RUNAME = 'Vicx-Vicxxx-AppName-XXXX';
our $APP_NAME ='VictorS-MyAppNam-SBX-XXXXX-XXXXX';
our $DEV_NAME='XXXX-XXXX-XXXX-XX-XXXXXXXXX';
our $CERT_NAME = 'SBX-XXXXXXXXXXXX-XXXX-XXXX-XXXX-XXXX';
our $MAIN_TOKEN = 'AgAAAA**A ... PFK1PQ5J1SF';
