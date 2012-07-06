#!/usr/bin/perl
use strict;
use warnings;

# Load needed libraries
use DNSCheckWeb;

# Testing
use Data::Dumper;

my $dnscheck = DNSCheckWeb->new();
my $dbo = $dnscheck->get_dbo();
my $cgi = $dnscheck->get_cgi();

# Parameters
my $type = $cgi->param('type');
my $locale = $cgi->param('locale');

if(defined($type) && ($type eq 'standard' || $type eq 'undelegated')) {
	# TODO: Do something
} else {
	$type = 'standard';
}

# Render result
$dnscheck->render('index.tpl', {
	version => $dbo->get_version(),
	type => $type,
	page_title => "Test domain",
	locale => $locale,
});
