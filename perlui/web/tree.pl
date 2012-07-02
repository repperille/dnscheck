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

my $json = decode_json($file_contents);

# De reference
my @tests = @{ $json->{tests} };
# Build the tree
# Print some for testing
print $dnscheck->json_headers();

my @modules = ();
my $indent = -1;

foreach my $node (@tests) {

	# Assign some variables from the set
	my $module_id = $node->[3];
	my $parent_id = $node->[4];
	my $module = $modules[$module_id];
	my $level = $node->[6];
	my $type = $node->[7];
	my $caption = $node->[22];
	my $desc = $node->[23];

	# Construct caption given the arguments
	$caption = sprintf($caption, $node->[8], $node->[9],
	$node->[10], $node->[11], $node->[12], $node->[13], $node->[14],
	$node->[15], $node->[16], $node->[18]);

	# Clean output somehow
	if(!defined($desc)) {
		$desc = "-";
	}

	# New level
	if($type=~ m/BEGIN$/) {
		$indent++;
	}

	# Actual output
	my $child_module = {
		caption => $caption,
		indent => $indent,
		description => $desc,
		level => lc($level),
	};

	# Pop level
	if($type =~ m/END$/) {
		$indent--;
	}
	push @modules, $child_module;
}
print Dumper(@modules);
#print Dumper(@tests);

1;
