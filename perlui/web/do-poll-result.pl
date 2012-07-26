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
use Data::Dumper;

# Constants for feedback
use constant TEST_STARTED => "started";
use constant TEST_RUNNING => "running";
use constant TEST_FINISHED => "finished";
use constant TEST_ERROR => "error";

# Some scalars for the state of the no-script check
# If the dispatcher is not running, the script will at most run for
# INITIAL + MAX_RETRIES * SLEEP_TIME seconds
use constant INITIAL => 5;
use constant MAX_RETRIES => 5;
use constant SLEEP_TIME => 2;
my $retries = 0;

my $dnscheck = DNSCheckWeb->new();
my $cgi = $dnscheck->get_cgi();

# Fetch parameters
my $domain = $cgi->param("domain");
my $source_data = $cgi->param("parameters");
my $js = $cgi->param("js");
my $private = $cgi->param("private");

# Check whether this is an ajax call or not
# Will dictate how the rest of the check carries out
unless(defined($js) && ($js == 0 || $js == 1)) {
	$js = 1;
}

# Set source and concenate source data if it was not provided by js
my $source;
if($cgi->param("test") =~ m/undelegated|moved/) {
	if(!$js) {
		$source_data = concat_data($cgi);
	}
	$source = DNSCheckWeb::TYPES->{'undelegated'};;
} else {
	$source = DNSCheckWeb::TYPES->{'standard'};
}

# Final JSON-string containing status and results
my $href_results = {
	domain => $domain,
	source => $source
};

# Try to set the private TLD, if its private at all.
my @parts = split('\.', $domain);
my $private_tld = {
	@parts[@parts-1] => 1
};

# Options to be provided the initial domain validation
my %domain_options = (
	domain_allow_single_label => 1,
	domain_private_tld => $private_tld
);

DO_CHECK:

# Received domain name, check for running tests
eval {
	# Will do these tests for each poll.

	# Try to create databaseobject
	my $dbo = $dnscheck->get_dbo($js);
	# Check if domain is valid
	if(!defined($domain) || !is_domain($domain, \%domain_options)) {
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

		# Initial rescheduling
		if(!$js) {
			sleep INITIAL;
			goto DO_CHECK;
		}
	}
	# A test exists in the database, and it is still in progress
	elsif($running->{finished} eq 'NO' && defined($running->{started})) {
		# Test for domain is running, but not finished
		$href_results->{started} = $running->{started};
		$href_results->{status} = TEST_RUNNING;

		# Try again
		if(!$js) {
			sleep SLEEP_TIME;
			goto DO_CHECK;
		}
	}
	# Test has finished, return results
	elsif($running->{finished} eq 'YES') {
		# Finished test, set id
		my $test_id = $running->{id};
		$href_results->{id} = $test_id;
		$href_results->{key} = $dnscheck->create_hash($test_id);
		$href_results->{status} = TEST_FINISHED;

		# End check
		if(!$js) {
			goto FINISHED;
		}
	}
	# Not running and not finished. Will let browser know the result.
	# Browser may retry after this.
	# No-script will try again for a little while
	else {
		if(!$js) {
			if($retries < MAX_RETRIES) {
				$retries++;
				sleep 2;
				goto DO_CHECK;
			}
		}
		EngineException->throw();
	}
};
# Catch errors
# The error_keys are mapping for a javascript array client side. For the
# specified key, an appopriate error message exist.
my $e;
if ($e = DomainException->caught()) {
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
# Ending up here without javascript means that an error occurred
if(!$js) {
	$dnscheck->render_error($e);
}

# Feed result back to browser
print $dnscheck->json_headers();
print JSON::to_json($href_results);
exit;

# Reaches this section when result is returned for no-script, redirect
# browser
FINISHED:
my $key = $dnscheck->create_hash($href_results->{id});
print "Location: tree.pl?test_id=".$href_results->{id}."&key=".$key."\n\n";
exit;

# Two simple helper routines for concatenating parameters for no-script
# version
sub concat_data {
	my $cgi = shift;
	my $domain0 = concat_domain($cgi->param('host0'), $cgi->param('ip0'));
	my $domain1 = concat_domain($cgi->param('host1'), $cgi->param('ip1'));

	return "$domain0 $domain1";
}

sub concat_domain {
	my ($host, $ip) = @_;
	my $result = '';
	if(length($host) > 0) {
		$result .= $host;
	}
	if(length($ip) > 0) {
		$result .= '/'.$ip;
	}
	return $result;
}
