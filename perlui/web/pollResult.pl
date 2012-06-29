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
use JSON;

# Testing
use Data::Dumper;

my $cgi = new CGI;
my $test_id = $cgi->param("id");
my $locale = $cgi->param("locale");

# Load config
my $dnscheck = DNSCheckWeb->new();
my $dbo = $dnscheck->get_dbo();

my $results;

# Feed back result to browser
print $dnscheck->json_headers();

# Fetch all results on the given test_id 
if(defined($test_id) && $test_id > 0 && defined($locale)) {
	$results = $dbo->get_test_results($test_id, $locale);

	my $json = encode_json $results;
	$json = "{\"results\": ".$json."}";

	print $json;
}

exit;

1;
