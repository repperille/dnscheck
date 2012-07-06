#!/usr/bin/perl
use strict;
use warnings;

package DNSCheckWeb;

use CGI;
#use CGI::Session;
use DBI;
use Template;
use YAML::Tiny;

# Testing
use Data::Dumper;

# Custom modules
use DNSCheckWeb::DB;
use DNSCheckWeb::I18N;

# Config
my $cf_dbh;
my $config_hash;

sub new {
	my $class = shift;
	my $self = {};

	$self->{config} = parse_yaml('../', 'config.yaml');

	bless $self, $class;
}

# Print headers and process the template.
sub render {
	my ($self, $file, $vars) = @_;

	# Setup template and prepare browser
	my $template = Template->new({INCLUDE_PATH => ['../templates']});
	print html_headers();

	# Add some important values 
	$vars->{title} = 'Zone checker!';

	# Checks whether some language have been loaded already
	if(!defined($self->{lng})) {
		$self->{lng} = get_lng();
	}
	# Load the language strings
	if(!defined($self->{lng}->{keys})) {
		$self->{lng}->load_locale($vars->{locale});
	}
	# Assign language to the template
	$vars->{lng} = $self->{lng}->{keys};
	$vars->{locales} = $self->{lng}->{languages};

	# Process the data
	$template->process($file, $vars) or die "Template rendering failed",
	$template->error(), "\n";
	exit;
}

# Returns the database object.
sub get_dbo {
	my $self = shift;

	unless (defined($self->{dbo})) {
		$self->{dbo} = DNSCheckWeb::DB->new($self->{config}->{dbi});
	}

	return $self->{dbo};
}

# Retuns te I18N object.
sub get_lng {
	my $self = shift;

	unless (defined($self->{lng})) {
		$self->{lng} = DNSCheckWeb::I18N->new();
	}

	return $self->{lng};
}

# Print headers to browser
sub html_headers {
	return CGI::header(-type=>'text/html; charset=utf-8', -expires=>'now');
}
sub json_headers {
	return CGI::header(-type=>'application/json; charset=utf-8', -expires=>'now');
}

# Build output tree.
sub build_tree {
	my ($self, $result) = @_;

	#
	# TODO: This "tree" includes HTML, should also have a raw tree?

	# De reference
	my @tests = @{ $result->{tests} };
	my @modules = ();
	my $indent = 0;
	my $result_status = 'OK'; # Presume that everything is ok
	my $version;

	foreach my $node (@tests) {

		# Assign some variables from the set
		my $module_id = $node->[0];
		my $parent_id = $node->[4];
		my $module = $modules[$module_id];
		my $class = $node->[6];
		my $type = $node->[7];
		my $caption = $node->[22];
		my $desc = $node->[23];

		# Construct caption given the arguments
		$caption = sprintf($caption, $node->[8], $node->[9],
		$node->[10], $node->[11], $node->[12], $node->[13], $node->[14],
		$node->[15], $node->[16], $node->[18]);

		# Start to build module
		my $child_module = {
			id => $module_id,
			caption => $caption,
			description => $desc,
			class => lc($class),
			tag_start => '<li>',
			tag_end => '</li>',
		};

		# Format for new class
		if($type=~ m/BEGIN$/) {
			$child_module->{tag_start} = '<li>';
			$child_module->{tag_end} = '<ul>';
			$indent++;
		} 

		# Skip some overhead, and set version
		if($indent == 1) {
			if(!defined($version)) {
				$version = $node->[9];
			}
			next;
		}

		# Format for end class
		if($type =~ m/END$/) {
			$child_module->{tag_start} = '<li></ul>';
			$indent--;
		}

		# Check whether we encountered an error
		if($child_module->{class} eq 'warn') {
			$result_status = $child_module->{class};
		} elsif($child_module->{class} eq 'error') {
			$result_status = $child_module->{class};
		}

		push @modules, $child_module;
	}

	# Assign new reference, and return
	$result->{tests} = \@modules;
	$result->{class} = $result_status;
	$result->{version} = $version;
	return $result;
}


# Resolves the given hostname to an A address
sub resolve {
	my ($self, $ns) = @_;
	
	# Results
	my $result = {
		hostname => $ns
	};

	my $res = Net::DNS::Resolver->new();
	my $query = $res->search($ns);

	if ($query) {
    	foreach my $rr ($query->answer) {
    		next unless $rr->type eq "A";
			$result->{addr} = $rr->address;
    	}
	}
	return $result;
}

# Parses the yaml file and returns the result.
sub parse_yaml {
	my ($dir, $file) = @_;
	my $yaml = YAML::Tiny->new();

	$yaml = YAML::Tiny->read($dir . $file) or die YAML::Tiny->errstr;

	my %values = %{ $yaml->[0] };

	return $yaml->[0];
}

1;
