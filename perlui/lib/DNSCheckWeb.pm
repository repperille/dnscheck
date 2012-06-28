#!/usr/bin/perl
use strict;
use warnings;

package DNSCheckWeb;

use CGI;
use DBI;
use Template;
use File::Spec::Functions;
use Config::Any;

# Custom modules
use DNSCheckWeb::DB;

# Config
my $cf_dbh;
my $config_hash;

sub new {
	my $class = shift;
	my $self = {};

	$self->{config} = config();

	bless $self, $class;
}

# Routine for reading the config (similar to the one in
# DNSCheck/Config.pm)
sub config {
	my $config = _get_with_path(
		_catfile('../', 'config.yaml')
    );
	return $config;
}

# Print headers and process the template.
sub render {
	my ($self, $file, $vars) = @_;

	# Setup template and prepare browser
	my $template = Template->new({INCLUDE_PATH => ['../templates']});
	html_headers();

	# Adding some static variables
	$vars->{title} = 'Zone checker!';

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

# Print headers to browser
sub html_headers {
	print CGI::header(-type=>'text/html; charset=utf-8', -expires=>'now');
}
sub json_headers {
	print CGI::header(-type=>'application/json; charset=utf-8', -expires=>'now');
}

# Only for internal use when loading config.
sub _catfile {
    my @tmp = grep {$_} @_;
    return catfile(@tmp);
}
sub _get_with_path {
    my @files = grep {$_} @_;

    my $cfg = Config::Any->load_files({
        files => \@files,
        use_ext => 1,
    });

    my ($c) = values %{$cfg->[0]};
    return $c;
}

1;
