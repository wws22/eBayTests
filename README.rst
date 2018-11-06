===================
README for eBayTests
===================

This is the samples for using eBay API during auctions

Installing
==========

Install the newest version from github::

    git clone https://github.com/wws22/eBayTests.git

Briefing
========

Create your own .eBay.conf file as described in EbayConfig.pm

It was looked like:

.. code-block:: perl

    use strict;
    use warnings;
    #
    our $API_COMPATIBILITY_LEVEL = '1031';
    our $MY_PUBLIC_IP = 'XXX.XXX.XXX.XXX';  # The public IP address of the machine from which the request is sent.
                                            # Your application captures that IP address and includes it in a call request.
                                            # eBay evaluates requests for safety (also see the BotBlock container
                                            # in the request and response of this call).
    #
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

Put your credential in each line. Check up which URLs You would like to use: 'sandbox' or  '' for the production.
You have to use different credentials for the sandbox and production environment.

Use the scripts:

    getsessionid.pl

Log in as the buyer by given URL and fetch the token:

    fetchtoken.pl <Session_ID>

Your token will be stored in the .user_token file. The good idea is to do a copy of the user's token file to .user_token1, .user_token2 etc
You can repeat steps get session and fetch token for the different users as many times as You wish.
For a change the bidder, You have to copy actual user's token into .user_token file.

Make a bid through:

    placeoffer.pl <ItemID> <MaxBid> [CurrencyID]

Check the status of your bid:

    getitemstatus.pl

Authors and contact info
========================

Victor Selukov <victor [dot] selukov [at] gmail.com>
