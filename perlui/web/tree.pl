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

	# Dereference to check length
	if(@{$result->{tests}} == 0) {
		die "No results for the domain";
	}
	$result->{domain} = $result->{tests}->[0]->[8];
	$result = $dnscheck->build_tree($result);

	$dnscheck->render('tree.tpl', {
		page_title => 'Results',
		domain => $result->{domain},
		status => $result->{status},
		tests => $result->{tests}
	});

};
if($@) {
	print $dnscheck->html_headers();
	print $@;
}

1;
