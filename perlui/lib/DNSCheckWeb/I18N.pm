#!/usr/bin/perl
use warnings;
use strict;

package DNSCheckWeb::I18N;

use YAML::Tiny;
use Encode;
use Data::Dumper;

# Current language dir, should be changed.
my $dir = '../../webui/languages/';

sub new {
	my ($class) = @_;

	my $self = {};

	# Check available languages, should handle proper error messages
	opendir(D, "$dir") || die "Can't opedir $dir: $!\n";
	my @list = readdir(D);
	closedir(D);

	# Loop through available files
	my %languages;
	foreach my $file (@list) {
		my $end = substr($file, 2, 5);
		if($end eq '.yaml') {
			# Reads the whole files (just to list languages)
			my $read_file = parse_yaml($file);
			# Add to hash
			$languages{$read_file->{languageId}} = $read_file->{languageName};
		}
	}
	$self->{languages} = \%languages;

	bless $self, $class;
	return $self;
}

# Loads the give local from languge files
sub load_locale {
	my ($self, $locale, $type) = @_;

	if(!defined($type)) {
		$type = ".yaml";
	}

	my $read_lng = parse_yaml($locale . $type);

	$self->{keys} = $read_lng;

	return $self;
}

# Parses the yaml file and returns the result.
sub parse_yaml {
	my $file_name = shift;
	my $yaml = YAML::Tiny->new();

	$yaml = YAML::Tiny->read($dir . $file_name) or die YAML::Tiny->errstr;

	#TODO: Get some weird encoding here?
	my %values = %{ $yaml->[0] };

	return $yaml->[0];
}

1;
