#!/usr/bin/perl
use strict;
use warnings;

package DNSCheckWeb;

# Standard modules
use CGI;
use CGI::Session;
use DBI;
use Template;
use YAML::Tiny;
use encoding 'UTF-8';

# Custom modules
use DNSCheckWeb::DB;
use DNSCheckWeb::I18N;

# Testing
use Data::Dumper;

# Temporary "fix" for testing mod_perl
use constant DIR => "/var/www/perlui/lib/";

# Constants for the valid types
use constant TYPES => {
	standard => "webgui",
	undelegated => "webgui-undelegated"
};


# "New" instance of this "object"
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
	my $template = Template->new({ENCODING => 'utf8', INCLUDE_PATH =>
	[DIR . '../templates']});

	# Initialize I18N module
	if(!defined($self->{lng})) {
		$self->{lng} = get_lng();
	}

	# Given that locale is defined, and exists in language map store in
	# persistent storage.
	$vars->{locale}= $self->{lng}->get_stored_locale($vars->{locale},
	$self->{session});

	# Load the language strings
	if(!defined($self->{lng}->{keys})) {
		$self->{lng}->load_language($vars->{locale});
	}
	# Assign language to the template
	$vars->{lng} = $self->{lng}->{keys};
	$vars->{locales} = $self->{lng}->{languages};

	# Set cookie and print headers
	print html_headers($self->{cookie});
	$template->process($file, $vars) or die "Template rendering failed",
	$template->error(), "\n";
	exit;
}

sub render_error {
	my ($self, $title, $errors) = @_;	

	my $result = {
		title => $title,
		error => $errors,
	};
	$self->render('error_page.tpl', $result);
}

# Returns the database object.
sub get_dbo {
	my $self = shift;

	unless (defined($self->{dbo})) {
		$self->{dbo} = DNSCheckWeb::DB->new($self->{config}->{dbi});
	}

	return $self->{dbo};
}

# Retuns the I18N object.
sub get_lng {
	my $self = shift;

	unless (defined($self->{lng})) {
		$self->{lng} = DNSCheckWeb::I18N->new(DIR);
	}

	return $self->{lng};
}

# Returns the request interface
sub get_cgi {
	my $self = shift;
	unless(defined($self->{cgi})) {
		$self->{cgi} = CGI->new();
		#$self->{cgi}->charset('UTF-8');
		load_session($self);
	}
	return $self->{cgi};
}
# Load session for the provided cookie
sub load_session {
	my $self = shift;
	my $cgi = $self->{cgi};
	my $sid = $cgi->cookie("CGISESSID");
	my $session;

	# Check whether the user already have a session id
	if(defined($sid)) {
		$session = new CGI::Session(undef, $sid, {Directory=>'/tmp'});
	} else {
		$session = new CGI::Session("driver:File", $cgi, {Directory=>'/tmp'});
	}
	$self->{session} = $session;
	$self->{cookie} = $cgi->cookie(CGISESSID => $session->id);

	return $self->{session};
}

# Print headers to browser
sub html_headers {
	my $cookie = shift;
	if(defined($cookie)) {
		return CGI::header(-type=>'text/html', -expires=>'now',
		charset=>'UTF-8', -cookie=>$cookie);
	} else {
		return CGI::header(-type=>'text/html', -expires=>'now',
		-charset=>'UTF-8');
	}
}
sub json_headers {
	return CGI::header(-type=>'application/json', -expires=>'now', -charset=>'UTF-8');
}
sub plain_headers {
	return CGI::header(-type=>'text/plain', -expires=>'now', -charset=>'UTF-8');
}

# Build output tree.
# This tree mixes HTML and raw output (data structure easier to
# manipulate perl side, but clutters the program flow).
sub build_tree {
	my ($self, $result) = @_;

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
					$result_class = $class;
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

# Parses the yaml file and returns the result
sub parse_yaml {
	my ($rel_dir, $file) = @_;

	my $path;
	if(!defined($file)) {
		$path = get_abs() . $rel_dir;
	} else {
		$path = get_abs() . $rel_dir . $file;
	}
	my $yaml = YAML::Tiny->new();
	$yaml = YAML::Tiny->read($path) or die YAML::Tiny->errstr . " $path";

	return $yaml->[0];
}
# A routine for retrieving the absolute path
sub get_abs {
	return DIR;
}

1;
