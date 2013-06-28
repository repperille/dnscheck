#!/usr/bin/perl
# 
# Copyright (c) 2012 UNINETT Norid AS.
# All rights reserved.
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

use warnings;
use strict;

package DNSCheckWeb::I18N;

use I18N::LangTags::Detect;

use Data::Dumper;

# Language directory relative to lib
my $dir = $ENV{'DNSCHECKWEB_ROOT'}.'/language/';

sub new {
	my $class = shift;
	my $self = {};

	# Check available languages. Uses the absolute path given from main
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
	# Assign the available languages (for language selection)
	$self->{languages} = \%languages;
	# Assign the relative path
	$self->{path} = $dir;

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

		# User could forge cookie, validate again. If no cookie got
		# loaded, set from browser language (given that language is
		# available).

		if(!defined($locale) || !exists($self->{languages}->{$locale})) {
	 		my @user_wants = I18N::LangTags::Detect::detect();
			foreach my $lang (@user_wants) {
				if(exists($self->{languages}->{$lang})) {
					$locale = $lang; last;
				}
			}
			# No suitable languages found, fallback to english
			if(!defined($locale)) {
				$locale = 'en';
			}
		}
	}

	$self->{locale} = $locale;
}

1;
