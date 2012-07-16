#!/usr/bin/perl
#
# This script is intended for users who do not have javascript enabled.
# It will first create or fetch a test id, and then loop to check if
# results are ready.
#
use strict;
use warnings;

# Load needed libraries
use CGI;
use DNSCheckWeb;
use DNSCheckWeb::Exceptions;
use Data::Validate::Domain qw(is_domain);

# Testing
use Data::Dumper;

use constant TEST_ERROR => "Error";
use constant TIMER_MAX => 120; # Stop checking for results after 2 minutes
use constant TIMER_INIT => 5; # Seconds to wait before trying to poll test_id

my $dnscheck = DNSCheckWeb->new();
my $cgi = $dnscheck->get_cgi();
my $dbo = $dnscheck->get_dbo();

# If a test id was provided, continue to the polling state
# Else, continue to the start state, and fire of new check.
my $test_id = $cgi->param("test_id");
if(defined($test_id) && $test_id > 0) {
	goto RUNNING;
} else {
	goto START;
}

#
# Start state
# This state will fire of a new DNS check test, and redirect browser to itself
START:
# Parameters
my $source = DNSCheckWeb::TYPES->{$cgi->param("test")};
my $domain = $cgi->param("domain");

# Concatenate source data if it was provided
my $source_data;
if($cgi->param("test") eq "undelegated") {
	$source_data = concat_data($cgi);
}

my $generated_id;
my $running;

# Checks whether provided domain is valid
eval {
	if(!defined($domain) || !is_domain($domain)) {
		DomainException->throw( error=> "Failed on: $domain");
	}
	if(!defined($source)) {
		SourceException->throw();
	}
	if(!defined($source_data)) {
		$source_data = '';
	}

	# TODO: Clean into something simple ..
	# TODO: Not sure if all cases are covered

	# Check if dispatcher is already testing this specific case
	# TODO: Use get_running_result instead
	$running = $dbo->get_running_test_id($domain, $source, $source_data);

	# No tests running, fire of new test.
	if(!defined($running)) {
		$dbo->start_check($domain, $source, $source_data);
		# Immediately check for results
		$running = $dbo->get_running_test_id($domain, $source, $source_data);
		if(!defined($running)) {
			# Highly experimental
			sleep TIMER_INIT;
			$running = $dbo->get_last_test_id($domain, $source, $source_data);
		}
	}
	$generated_id = $running->{id};

	if(!defined($generated_id)) {
		# No way to continue, get out
		TestException->throw( error => "Failed on: $domain, source: $source, source_data: $source_data");
	} else {
		# Redirects to itself, with the test_id parameter
		print "Location: do-noscript-lookup.pl?test_id=" . $generated_id . "\n\n";
	}
};
# Catch errors
if (my $e = DomainException->caught()) {
	$dnscheck->render_error($e);
} elsif($e = SourceException->caught()) {
	$dnscheck->render_error($e);
} elsif($e = TestException->caught()) {
	$dnscheck->render_error($e);
} elsif($e = DBException->caught()) {
	$dnscheck->render_error($e);
}
# Script should not "naturally" progress to this section.
exit;

#
# Running state
# This section will poll the database to check whether test results are ready.
RUNNING:
# Autoflush, not sure if..
$| = 1;
for (0 .. TIMER_MAX) {
	my $running = $dbo->get_running_result_on_id($test_id);
	if(defined($running)) {
		if($running->{finished} eq 'YES') {
			print "Location: tree.pl?test_id=" . $test_id . "\n\n";
			exit;
		}
	} else {
		$dnscheck->render_error("Error", "No results on id");
	}
	sleep 2;
}

# Two simple helper routines for concatenating the parameters
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
