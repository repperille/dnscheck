#!/usr/bin/perl
use warnings;
use strict;

package DNSCheckWeb::I18N;

use Data::Dumper;

# Language directory relative to lib
my $dir = '../lng/';

sub new {
	my $class = shift;
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

# Load the given locale from language files
sub load_language {
	my ($self, $type) = @_;

	if(!defined($type)) {
		$type = ".yaml";
	}
	$self->{keys} = DNSCheckWeb::parse_yaml($dir . $self->{locale} . $type);

	return $self;
}

# If no locale is provided, load from the provided session, else
# fallback to English.
sub update_locale {
	my ($self, $locale, $session) = @_;

	# Check that locale is defined and that it exists in the language map
	if(defined($locale) && exists($self->{languages}->{$locale})) {
		$session->param("locale", $locale);
	} else {
		# Try to load locale
		$locale = $session->param("locale");

		# User could forge cookie, validate again
		if(!defined($locale) || !exists($self->{languages}->{$locale})) {
			$locale = "en";
		}
	}

	$self->{locale} = $locale;
}

1;
