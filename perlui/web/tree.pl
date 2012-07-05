#!/usr/bin/perl
use strict;
use warnings;

use DNSCheckWeb;
use CGI;
use JSON;

use Data::Dumper;


my $cgi = CGI->new();
my $dnscheck = DNSCheckWeb->new();
my $dbo = $dnscheck->get_dbo();

my $test_id = $cgi->param('test_id');
my $result = { };

# Get results for the given test
eval {
	if(!defined($test_id) || $test_id <= 0) {
		die "Invalid test id provided";
	}
	# Fetch results for the given test_id
	$result->{tests} =  $dbo->get_test_results($test_id, 'en');
	my $tests = @{$result->{tests}};

	if($tests == 0) {
		die "No results for the domain";
	}
	# TODO: Not the cleanest way of getting the data
	$result->{domain} = $result->{tests}->[0]->[8];
	$result->{started} = $result->{tests}->[0]->[5];
	$result->{finished} = $result->{tests}->[$tests-1]->[5];

	# Loop through test set and build (HTML) tree
	$result = $dnscheck->build_tree($result);

	#print $dnscheck->json_headers;
	#print Dumper($result);
	#exit;

	# Render result
	$dnscheck->render('tree.tpl', {
		page_title => 'Results',
		domain => $result->{domain},
		class => $result->{class},
		tests => $result->{tests},
		started => $result->{started},
		finished => $result->{finished},
		locale => "en",
	});
};
if($@) {
	print $dnscheck->html_headers();
	print $@;
}

1;
