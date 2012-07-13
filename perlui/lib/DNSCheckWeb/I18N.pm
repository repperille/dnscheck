#!/usr/bin/perl
use warnings;
use strict;

package DNSCheckWeb::I18N;

use Encode;
use Data::Dumper;

# Current language dir, should be changed, and specified through config
# file
my $dir = '../../webui/languages/';

sub new {
	my ($class) = @_;
	my $self = {};

	# Check available languages. Uses the absoulte path given from main
	# module.
	opendir(D, DNSCheckWeb::get_dir().$dir) || die "Can't opedir $dir: $!\n";
	my @list = readdir(D);
	closedir(D);

	# Loop through available files
	my %languages;
	foreach my $file (@list) {
		# Skip if name is short
		next unless length($file) >= 6;
		# Check the suffix
		my $end = substr($file, length($file) - 5, length($file) - 1);
		if($end eq '.yaml') {
			# Reads the whole files (just to list languages)
			my $read_file = DNSCheckWeb::parse_yaml($dir, $file);
			# Add to hash
			$languages{$read_file->{languageId}} = $read_file->{languageName};
		}
	}
	$self->{languages} = \%languages;

	bless $self, $class;
	return $self;
}

# Loads the given local from language files
sub load_language {
	my ($self, $locale, $type) = @_;

	if(!defined($type)) {
		$type = ".yaml";
	}
	$self->{keys} = DNSCheckWeb::parse_yaml($dir . $locale . $type);

	return $self;
}

# If no locale is provided, check the current session and try to load
sub get_stored_locale {
	my ($self, $locale, $session) = @_;

	if(defined($locale) && exists($self->{languages}->{$locale})) {
		$session->param("locale", $locale);
	} else {
		# Try to load locale
		$locale = $session->param("locale");

		# Set default if not loaded from session
		if(!defined($locale)) {
			$locale = "en";
		}
	}
	return $locale;
}

1;
