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
use DNSCheckWeb::Exceptions;
use CGI;
use JSON;
use Data::Validate::Domain qw(is_domain);

# Testing
use Data::Dumper;

# Constants for feedback
use constant TEST_STARTED => "started";
use constant TEST_RUNNING => "running";
use constant TEST_FINISHED => "finished";
use constant TEST_ERROR => "error";

# Some important objects
my $dnscheck = DNSCheckWeb->new();
my $cgi = $dnscheck->get_cgi();

# Fetch parameters
my $domain = $cgi->param("domain");
my $source = DNSCheckWeb::TYPES->{$cgi->param("test")};
my $source_data = $cgi->param("parameters");
my $js = $cgi->param("js");

# Final JSON-string containing status and results
my $href_results = {
	domain => $domain,
	source => $source
};

# Check whether this is an ajax call or not
unless(defined($js) && ($js == 0 || $js == 1)) {
	$js = 1;
}

# Received domain name, check for running tests
eval {
	# Will do these tests for each poll.

	# Try to create databaseobject
	my $dbo = $dnscheck->get_dbo(1);
	# Check if domain is valid
	if(!defined($domain) || !is_domain($domain)) {
		DomainException->throw();
	}
	if(!defined($source)) {
		SourceException->throw();
	}

	# Source data can be undefined
	if(!defined($source_data)) {
		$source_data = '';
	}

	# Check if dispatcher is already testing this specific case
	my $running = $dbo->get_running_result($domain, $source, $source_data);

	# There is no record in the database, start new test
	if(!defined($running)) {
		$dbo->start_check($domain, $source, $source_data);
		$href_results->{status} = TEST_STARTED;
	} 
	# A test exists in the database, and it is still in progress
	elsif($running->{finished} eq 'NO' && defined($running->{started})) {
		# Test for domain is running, but not finished
		$href_results->{started} = $running->{started};
		$href_results->{status} = TEST_RUNNING;
	} 
	# Test has finished, return results	
	elsif($running->{finished} eq 'YES') {
		# Finished test, set test_id
		my $test_id = $running->{id};
		$href_results->{test_id} = $test_id;
		$href_results->{key} = $dnscheck->create_hash($test_id);
		$href_results->{status} = TEST_FINISHED;
	} 
	# Not running and not finished. Will let browser know the result.
	# Browser may retry after this result.
	else {
		EngineException->throw();
	}
};
# Catch errors
# The error_keys are mapping for a javascript array client side. For the
# specified key, an appopriate error message exist.
if (my $e = DomainException->caught()) {
	$href_results->{status} = TEST_ERROR;
	$href_results->{error_key} = 0;
} elsif ($e = SourceException->caught()) {
	$href_results->{status} = TEST_ERROR;
	$href_results->{error_key} = 1;
} elsif ($e = DBException->caught()) {
	$href_results->{status} = TEST_ERROR;
	$href_results->{error_key} = 2;
} elsif ($e = EngineException->caught()) {
	$href_results->{status} = TEST_ERROR;
	$href_results->{error_key} = 3;
}

# Feed result back to browser
print $dnscheck->json_headers();
print JSON::to_json($href_results);
