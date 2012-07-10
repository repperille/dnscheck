#!/usr/bin/perl
use strict;
use warnings;

use DNSCheckWeb;
use DNSCheckWeb::Exceptions;
use JSON;

use Data::Dumper;


my $dnscheck = DNSCheckWeb->new();
my $cgi = $dnscheck->get_cgi();
my $dbo = $dnscheck->get_dbo();

my $test_id = $cgi->param('test_id');
my $locale = $cgi->param('locale');

my $result = { };

if(!defined($locale)) {
	my $lng = $dnscheck->get_lng();
	$locale = $lng->get_stored_locale($locale, $dnscheck->{session});
}

# Get results for the given test
eval {
	if(!defined($test_id) || $test_id <= 0) {
		TestException->throw();
	}

	# Fetch results for the given test_id
	$result->{tests} =  $dbo->get_test_results($test_id, $locale);
	my $tests = @{$result->{tests}};

	if($tests == 0) {
		TestException->throw();
	}
	# TODO: Not the cleanest way of getting the data
	$result->{domain} = $result->{tests}->[0]->[8];
	$result->{started} = $result->{tests}->[0]->[5];
	$result->{finished} = $result->{tests}->[$tests-1]->[5];
	$result->{history} = $dbo->get_history($test_id);

	# Loop through test set and build (HTML) tree
	$result = $dnscheck->build_tree($result);

	# Extracts keys from result to avoid deep tree
	$dnscheck->render('tree.tpl', {
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
	$dnscheck->render('tree_error.tpl', {
		title => 'Error',
		error => $e->description()
	});
}

1;
