#!/usr/bin/perl
use strict;
use warnings;

# Load needed libraries
use DNSCheckWeb;
use CGI;

# Testing
use Data::Dumper;

my $cgi = CGI->new();
my $host = $cgi->param("host");
my $sourceId = $cgi->param("host");

my $dnscheck = DNSCheckWeb->new();
my $dbo = $dnscheck->get_dbo();

# Someone sent a query, no id hence insert in DB.
if(defined($host)) {
	my $result = $dbo->start_check($host);
}

# Render result
$dnscheck->render('index.tpl', {
	host => $host,
	version => $dbo->get_version(),
});

1;
