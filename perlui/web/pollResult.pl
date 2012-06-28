#!/usr/bin/perl

#
# This script should basically do the same things as getResult.php.
# Poll for information from the database, and output that info as json
# to the ajax call from the user.
#

use strict;
use warnings;

# Load needed libraries
use DNSCheckWeb;
use CGI;

# Testing
use Data::Dumper;

my $cgi = new CGI;
my $host = $cgi->param("host");
my $sourceId = $cgi->param("host");

# Load config
my $dnscheck = DNSCheckWeb->new();
my $dbo = $dnscheck->get_dbo();

# Feed back result to browser
print DNSCheckWeb::json_headers();

1;
