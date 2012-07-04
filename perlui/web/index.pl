#!/usr/bin/perl
use strict;
use warnings;

# Load needed libraries
use DNSCheckWeb;
use CGI;

# Testing
use Data::Dumper;

my $cgi = CGI->new();
my $dnscheck = DNSCheckWeb->new();
my $dbo = $dnscheck->get_dbo();

my $type = $cgi->param('type');

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
});
