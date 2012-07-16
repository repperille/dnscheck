#!/usr/bin/perl
#
# This script builds the output tree from the dnscheck results.
#
use strict;
use warnings;

use JSON;
use DNSCheckWeb;
use DNSCheckWeb::Exceptions;
use Scalar::Util qw(looks_like_number);

use Data::Dumper;

my $dnscheck = DNSCheckWeb->new();
my $cgi = $dnscheck->get_cgi();
my $dbo = $dnscheck->get_dbo();

my $test_id = $cgi->param('test_id');
my $locale = $cgi->param('locale');

my $result = { };

# Have to load locale beforehand
if(!defined($locale)) {
	my $lng = $dnscheck->get_lng();
	$locale = $lng->get_stored_locale($locale, $dnscheck->{session});
}

# Get results for the given test, or throw exception
eval {
	if(!defined($test_id) || !looks_like_number($test_id)) {
		TestException->throw();
	}

	# Fetch results for the given test_id
	$result->{tests} =  $dbo->get_test_results($test_id, $locale);
	my $tests = @{$result->{tests}};

	# No tests defined, probably wrong test id
	if($tests == 0) {
		TestException->throw();
	}
	# TODO: Not the best method of assigning this data.
	$result->{domain} = $result->{tests}->[0]->[8];
	$result->{started} = $result->{tests}->[0]->[5];
	$result->{finished} = $result->{tests}->[$tests-1]->[5];
	$result->{history} = $dbo->get_history($test_id);

	# This is where most of the magic happens
	$result = $dnscheck->build_tree($result);

	# Extract keys from the tree result to avoid too much HTML clutter
	$dnscheck->render('tree.tpl', {
		id => $test_id,
		domain => $result->{domain},
		class => $result->{class},
		tests => $result->{tests},
		started => $result->{started},
		finished => $result->{finished},
		version => $result->{version},
		history => $result->{history},
		locale => $locale
	});
};
# Catch errors
if( my $e = TestException->caught() ) {
	$dnscheck->render_error($e);
} elsif($e = DBException->caught() ) {
	$dnscheck->render_error($e);
}
