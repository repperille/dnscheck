#!/usr/bin/perl
#
# This script builds the output tree from the dnscheck results.
#
use strict;
use warnings;

use JSON;
use DNSCheckWeb;
use DNSCheckWeb::Exceptions;
use Scalar::Util qw(looks_like_number);

use Data::Dumper;

my $dnscheck = DNSCheckWeb->new();
my $cgi = $dnscheck->get_cgi();
my $dbo = $dnscheck->get_dbo();

my $test_id = $cgi->param('test_id');
my $key = $cgi->param('key');
my $locale = $cgi->param('locale');

my $result = { };

# Have to load locale beforehand
if(!defined($locale)) {
	my $lng = $dnscheck->get_lng();
	$locale = $lng->get_stored_locale($locale, $dnscheck->{session});
}

# Get results for the given test, or throw exception
eval {
	if(!defined($test_id) || !looks_like_number($test_id)) {
		TestException->throw( error => "ID is not valid (\'$test_id\')");
	}
	if(!defined($key)) {
		TestException->throw( error => "Key was not defined ($key)");
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
	my $result_hash = $dnscheck->create_hash($result->{domain}.$test_id);
	if($key ne $result_hash) {
		TestException->throw( error => "Hash mismatch:\nkey: $key \nfetched: $result_hash");
	}

	# Get statistics
	my $stats = $dbo->get_test_data($test_id);

	# Retrieve history, generate key and append
	my @history = @{ $dbo->get_history($test_id) };

	# Need to iterate through once to generate hash structure output a
	# bit as well.
	for my $item (@history) {
		$item = {
			id => $item->[0],
			time => $item->[1], 
			class => $item->[2],
			key => $dnscheck->create_hash($result->{domain}.$item->[0])};
	}

	# This routine builds the output tree
	$result = build_tree($result);

	# Extract keys from the tree result to avoid too much HTML clutter
	$dnscheck->render('tree.tpl', {
		id => $test_id,
		domain => $result->{domain},
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
			$caption = sprintf($caption, $node->[8], $node->[9],
			$node->[10], $node->[11], $node->[12], $node->[13], $node->[14],
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
			}
		}
		# Very special case..
		if($type eq 'DNSSEC:SKIPPED_NO_KEYS') {
			$class = 'skipped';
		}

		# Cases for end tags
		if($type =~ m/END$/) {
			# Stepping out of module, pop
			pop(@ancestors);
			# End this list tag
			$child_module->{tag_start} = '</ul>';
			# Level 1 node, clean output
			if(@ancestors == 1) {
				$child_module->{caption} = undef;
			}
			# Skip to next module (there should not be one)
			elsif(@ancestors == 0) {
				next;
			}
		}
		# Propagate 'important' flags to ancestor modules
		unless($class eq 'ok' || $class eq 'info' || $class eq 'notice') {
			foreach my $parent_node (@ancestors) {
				unless ($parent_node->{class} eq 'error') {
					$parent_node->{class} = $class;
					unless($class eq 'skipped') {
						$result_class = $class;
					}
				}
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
