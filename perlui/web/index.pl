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

# Render result
$dnscheck->render('index.tpl', {
	version => $dbo->get_version()
});

1;
