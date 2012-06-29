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

# Constants for the "legal" types
use constant TYPES => {
	standard => "webgui",
	undelegated => "webgui-undelegated"
};
# Some important objects
my $cgi = new CGI;
my $dnscheck = DNSCheckWeb->new();
my $dbo = $dnscheck->get_dbo();

# Fetch parameters
my $host = $cgi->param("host");
my $source = TYPES->{$cgi->param("test")};
my $source_data = $cgi->param("parameters");
my $locale = 'en';

# Variables for giving feedback
my $test_id; # If test is finished, this will be set
my $href_results = {}; # Final json-string containing status and results

# Received host name, check for running tests
if(defined($host) && defined($source)) {
	my $running = $dbo->get_running_result($host, $source, $source_data);

	if(@$running eq 0) {
		# No tests running, fire of new test.
		$dbo->start_check($host, $source, $source_data);
		$href_results->{status} = "started new run";
	} elsif($running->[0][2] eq 'NO') {
		# Test for domain is running, but not finished
		$href_results->{status} = "Not finished yet..";
	} else {
		# Finished test, set test_id
		$test_id = $running->[0][0];
	}
}

# Fetch the results given that we got a test id
if(defined($test_id) && $test_id > 0 && defined($locale)) {
	my $json =  $dbo->get_test_results($test_id, $locale);
	$href_results->{tests} = $json;
}
# Feed result back to browser
$dnscheck->json_headers();
print encode_json $href_results;

exit;
1;
