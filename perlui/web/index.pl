#!/usr/bin/perl
use strict;
use warnings;

# Load needed libraries
use DNSCheckWeb;
use DNSCheckWeb::DNSCheckDB;
use CGI;

# Testing
use Data::Dumper;

my $cgi = new CGI;
my $host = $cgi->param("host");

# Load config
my $config = DNSCheckWeb::config();
my $dbo = DNSCheckWeb::DNSCheckDB->new($config->{'dbi'});

# Someone sent a query, no id hence insert in DB.
if(defined($host)) {
	my $result = $dbo->start_check($host);
}

# Render result
DNSCheckWeb::render('index.tpl', {
	host => $host,
	version => $dbo->get_version(),
});

1;
