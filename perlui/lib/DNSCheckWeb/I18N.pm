#!/usr/bin/perl
use warnings;
use strict;

package DNSCheckWeb::I18N;

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
sub load_locale {
	my ($self, $locale, $type) = @_;

	if(!defined($type)) {
		$type = ".yaml";
	}
	$self->{keys} = DNSCheckWeb::parse_yaml($dir . $locale . $type);

	return $self;
}

1;
