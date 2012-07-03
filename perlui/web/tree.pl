#!/usr/bin/perl
use strict;
use warnings;

use DNSCheckWeb;
use CGI;
use JSON;

use Data::Dumper;

my $dnscheck = DNSCheckWeb->new();

# Read json
open FILE, "json" or die $!;
my $file_contents = do { local $/; <FILE> };

# Should not be necessary
my $json = decode_json($file_contents);

#print $dnscheck->json_headers();
my $tree = $dnscheck->build_tree($json);

$dnscheck->render('tree.tpl', {
	page_title => 'Results',
	domain => $tree->{domain},
	status => $tree->{status},
	tests => $tree->{tests}
});

#print $dnscheck->json_headers();
#print Dumper($tree);

1;
