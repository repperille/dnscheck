#!/usr/bin/perl
use warnings;
use strict;

package DNSCheckWeb::I18N;

use File::Spec::Functions;
use Config::Any;

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

	my @languages = ();

	foreach my $file (@list) {
		my $end = substr($file, 2, 5);
		if($end eq '.yaml') {
			# Reads the whole files (just to list languages)
			my $read_file = _get_with_path(_catfile($dir, "en.yaml"));
			my $language = {
				name => $read_file->{languageName},
				id => $read_file->{languageId}
			};
			push @languages, $language;
		}
	}
	$self->{languages} = \@languages;

	bless $self, $class;
	return $self;
}

sub load_locale {
	my ($self, $locale, $type) = @_;

	if(!defined($type)) {
		$type = ".yaml";
	}

	my $read_lng = _get_with_path(_catfile($dir, $locale . $type));
	$self->{keys} = $read_lng;

	return $self;
}


# Non public functions,
# Duplicate from DNSCheckWeb ..
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
