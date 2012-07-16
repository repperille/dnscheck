#!/usr/bin/perl
#
# This script should look up the A address for the given host and
# return that as json to the browser.
#
use strict;
use warnings;

# Load needed libraries
use DNSCheckWeb;
use JSON;
use Net::DNS;

my $dnscheck = DNSCheckWeb->new();
my $cgi = $dnscheck->get_cgi();

# Params
my $nameservers = $cgi->param('nameservers');

my @results = ();

# Resolve host names
if(defined($nameservers)) {
	# Split by pipe, and traverse each parameter
	my @ns = split(/\|/, $nameservers);
	foreach my $ns (@ns) {
		push @results, $dnscheck->resolve($ns);
	}
}

# Encode and return result
print $dnscheck->json_headers();
print JSON::to_json(\@results);
