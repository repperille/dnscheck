#!/usr/bin/perl
#
# Copyright (c) 2012 UNINETT Norid AS 
#                    All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
# GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
# IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
# IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
######################################################################

# This script builds the output tree from the dnscheck results.
#
use strict;
use warnings;

use JSON;
use DNSCheckWeb;
use DNSCheckWeb::Exceptions;
use Scalar::Util qw(looks_like_number);

my $dnscheck = DNSCheckWeb->new();
my $cgi = $dnscheck->get_cgi();
my $dbo = $dnscheck->get_dbo();

my $test_id = $cgi->param('test_id');
my $key = $cgi->param('key');
my $locale = $cgi->param('locale');

my $result = { };

# Have to load locale beforehand
my $lng = $dnscheck->get_lng($locale);
$locale = $lng->{locale};

# Get results for the given test, or throw exception
eval {
	if(!defined($test_id) || !looks_like_number($test_id)) {
		TestException->throw( error => "ID is not valid (\'$test_id\')");
	}
	if(!defined($key)) {
		TestException->throw( error => "Key was not defined");
	}

	# Fetch results for the given test_id
	$result->{tests} =  $dbo->get_test_results($test_id, $locale);


	my $tests = @{ $result->{tests} };
	# No tests defined, probably wrong test id
	if($tests == 0) {
		TestException->throw();
	}

	#
	# TODO: Not the best method of assigning this data.
	#
	# Set and check domain
	$result->{domain} = $result->{tests}->[0]->[8];
	my $result_hash = $dnscheck->create_hash($test_id);
	if($key ne $result_hash) {
		TestException->throw( error => "Hash mismatch:\ngot: $key
		\nexpected: $result_hash");
	}

	# Get statistics
	my $stats = $dbo->get_test_data($test_id);

	# Retrieve history, generate key and append
	my @history = @{ $dbo->get_history($test_id) };

	# Need to iterate through once to generate hash structure output
	# (is not that bad considering there are at most 5 items)
	for my $item (@history) {
		$item = {
			id => $item->[0],
			time => $item->[1],
			class => $item->[2],
			key => $dnscheck->create_hash($item->[0])};
	}

	# This routine builds the output tree
	$result = build_tree($result);

	# At this point we are fairly certain that there exists a tree,
	# cache result in session
	$dnscheck->last_result($test_id, $key);

	# Extract keys from the tree result to avoid too much HTML clutter
	$dnscheck->render('tree.tpl', {
		id => $test_id,
		domain => $dnscheck->idna_transform($result->{domain}, 0),
		class => $result->{class},
		tests => $result->{tests},
		version => $result->{version},
		history => \@history,
		stats => $stats,
		locale => $locale,
		server_name => $ENV{SERVER_NAME},
		key => $key
	});
};
# Catch errors
if( my $e = TestException->caught() ) {
	$dnscheck->render_error($e);
} elsif($e = DBException->caught() ) {
	$dnscheck->render_error($e);
}

# Build output tree. This tree mixes HTML and the raw output. Easier to
# manipulate data perl side.
# TODO: Should consider using hashref instead of arrayref
sub build_tree {
	my $result = shift;

	my @tests = @{ $result->{tests} };
	my @modules = ();
	my $indent = 0;
	my $version;
	my @ancestors = ();
	my $parent;
	my $result_class = 'ok';

	# Build the tree
	foreach my $node (@tests) {

		# Assign some variables from the set
		my $module_id = $node->[0];
		my $class = lc($node->[6]); # We want class definition in lowercase
		my $type = $node->[7];
		my $caption = $node->[22];
		my $desc = $node->[23];

		# Construct caption given the arguments
		if(defined($caption)) {
			$caption = sprintf($caption,
			$dnscheck->idna_transform($node->[8], 0),
			$node->[9],
			$dnscheck->idna_transform($node->[10], 0),
			$node->[11], $node->[12], $node->[13], $node->[14],
			$node->[15], $node->[16], $node->[18]);
		}

		# Start to build module
		my $child_module = {
			id => $module_id,
			caption => $caption,
			description => $desc,
			class => $class,
			tag_end => '</li>',
		};

		# Cases for begin tags
		if($type=~ m/BEGIN$/) {
			# Stepping into module, push
			push @ancestors, $child_module;
			# Start building new list
			$child_module->{tag_end} = '<ul>';
			# Root node, set version and then skip to next module
			if(@ancestors == 1) {
				$version = $node->[9];
				next;
			}
			# Level 1 node, clean output
			elsif(@ancestors == 2) {
				$child_module->{class} = 'ok';
				my @test = split(':', $node->[7]);
				$child_module->{caption} = lc($test[0]);

				# For nameservers we also want to display the hostname.
				# Builds a hash instead, and handles this in the
				# template
				if($test[0] =~ m/NAMESERVER/) {
					$child_module->{caption} = {
						type => lc($test[0]),
						ns => $node->[8]
					};
				}
			}
		}
		# Very special case..
		if($type eq 'DNSSEC:SKIPPED_NO_KEYS') {
			$class = 'skipped';
		}

		# Cases for end tags
		if($type =~ m/END$/) {
			# Stepping out of module
			pop(@ancestors);
			# End this list tag
			$child_module->{tag_start} = '</ul>';
			# Level 1 node, clean output
			if(@ancestors == 1) {
				$child_module->{caption} = undef;
			}
			# Skip to next module (there should be none)
			elsif(@ancestors == 0) {
				next;
			}
		}
		# Propagate 'important' flags to ancestor modules
		unless($class eq 'ok' || $class eq 'info' || $class eq 'notice') {
			# Update parents
			foreach my $parent_node (@ancestors) {
				unless ($parent_node->{class} =~ m/error|critical/) {
					$parent_node->{class} = $class;
				}
			}
			# Update the main result
			unless($class eq 'skipped' || $result_class =~ m/error|critical/) {
				$result_class = $class;
			}
		}
		# Remember "last" parent
		$parent = $child_module;
		push @modules, $child_module;
	}

	$result->{tests} = \@modules;
	$result->{version} = $version;
	$result->{class} = $result_class;
	return $result;
}
