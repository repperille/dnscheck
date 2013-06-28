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

use strict;
use warnings;

package DNSCheckWeb;

our $VERSION = 0.1;

# Standard modules
use CGI;
use CGI::Session;
use DBI;
use Template;
use YAML::Tiny;
use File::Slurp;
use Digest::SHA qw(sha256_hex);
use IDNA::Punycode;
use Encode;

# Custom modules
use DNSCheckWeb::DB;
use DNSCheckWeb::I18N;

# When running mod_perl DIR needs to be pointed to the directory
# containing this library.
use constant DIR => undef;
# Example:
#use constant DIR => "/var/www/dnscheck/lib/";

# Constants for the valid types
use constant TYPES => {
	standard => "webgui",
	undelegated => "webgui-undelegated"
};

# Load config and create a "new" instance
sub new {
	my $class = shift;
	my $self = {};

	$self->{config} = parse_yaml($ENV{DNSCHECKWEB_ROOT}.'/config.yaml');

	bless $self, $class;
}

# Set locale, load language, print headers and processes the specified
# template
sub render {
	my ($self, $file, $vars) = @_;

	# Check whether we are running mod_perl or not.
	# Mod perl requires absolute paths while standard requires relative.
	my $abs = 1;
	if(defined(DIR)) {
		$abs = 0;
	}

	# Setup template and prepare browser
	my $template = Template->new({
		INCLUDE_PATH => [$ENV{DNSCHECKWEB_ROOT}.'/templates'],
		RELATIVE => $abs,
		ABSOLUTE => !$abs,
	});

	# Initialize I18N module, and verify/set locale.
	if(!defined($self->{lng})) {
		$self->{lng} = $self->get_lng($vars->{locale});
	}

	# Assign values to the template variables
	$vars->{lng} = $self->{lng}->{keys};
	$vars->{locales} = $self->{lng}->{languages};
	$vars->{locale} = $self->{lng}->{locale};
	$vars->{last} = $self->last_result();
	$vars->{title} = $self->{config}->{title};

	# Specify encoding for reading files
	binmode( STDOUT, ":utf8" );
	# Set cookie and print headers
	print html_headers($self->{cookie});
	$template->process($file, $vars) or die "Template rendering failed",
	$template->error(), "\n";
	exit;
}

# Creates a generic error page with stack trace etc, if debug is turned on
sub render_error {
	my ($self, $e) = @_;

	# Error is the specific error, while trace is the stack trace for that error
	my $error;
	my $trace;

	# Add some more verbose output given that we are debugging
	if($self->{config}->{debug}) {
		$trace = $e->trace();
		$error = $e->error();
	}
	# A description is the "high level" description for the user
	my $result = {
		description => $e->description(),
		trace => $trace,
		error => $error,
	};
	$self->render('error_page.tpl', $result);
}

# Returns the database object.
sub get_dbo {
	my ($self, $json) = @_;

	unless (defined($self->{dbo})) {
		eval {
			$self->{dbo} = DNSCheckWeb::DB->new($self->{config});
		};
		if(my $e = DBException->caught()) {
			if(defined($json) && $json) {
				# If json is passed to routine, we are handling the
				# exception in the outer context.
				DBException->throw();
			} else {
				# Display error page
				$self->render_error($e);
			}
		}
	}

	return $self->{dbo};
}

# Load and set the I18N module. Will load the given locale, or English
sub get_lng {
	my ($self, $locale) = @_;

	unless (defined($self->{lng})) {
		# Loads in available languages
		$self->{lng} = DNSCheckWeb::I18N->new();
		# Updates the chosen locale
		$self->{lng}->update_locale($locale, $self->{session});
		# Loads the actualy literals from the language files
		$self->{lng}->load_language();
	}

	return $self->{lng};
}

# Returns the request interface
sub get_cgi {
	my $self = shift;

	unless(defined($self->{cgi})) {
		$self->{cgi} = CGI->new();

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
	# Assign session
	$self->{session} = $session;
	$self->{cookie} = $cgi->cookie(CGISESSID => $session->id);

	return $self->{session};
}

# Print headers to browser
sub html_headers {
	my $cookie = shift;
	if(defined($cookie)) {
		return CGI::header(-type=>'text/html', -expires=>'now', -charset=>'UTF-8', -cookie=>$cookie);
	} else {
		return CGI::header(-type=>'text/html', -expires=>'now', -charset=>'UTF-8');
	}
}
sub json_headers {
	return CGI::header(-type=>'application/json', -expires=>'now', -charset=>'UTF-8');
}
sub plain_headers {
	return CGI::header(-type=>'text/plain', -expires=>'now', -charset=>'UTF-8');
}

# Resolves the given hostname to an A address
sub resolve {
	my ($self, $ns) = @_;

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

# Will store last visited/result in session, and retrieve
sub last_result {
	my ($self, $test_id, $key) = @_;

	my $session = $self->{session};

	# Given that we have something to store
	if(defined($test_id) && defined($key)) {
		$session->param("test_id", $test_id);
		$session->param("key", $key);
		# Set expiration
		$session->expires("test_id" => '+30m');
		$session->expires("key" => '+30m');
	} else {
		$test_id = $session->param("test_id");
		$key = $session->param("key");
	}

	# Return the result
	my $result = {
		test_id => $test_id,
		key => $key
	};

	return $result;
}

# Parses the yaml file and returns the result
sub parse_yaml {
	my ($rel_dir, $file) = @_;

	my $path;
	if(!defined($file)) {
		$path = get_dir() . $rel_dir;
	} else {
		$path = get_dir() . $rel_dir . $file;
	}

	# Read UTF-8 properly
	my $content = read_utf8($path);

	# TODO: Some error detection here, whether the file was found etc.
	my $yaml = YAML::Tiny->new();
	$yaml = YAML::Tiny->read_string($content) or die YAML::Tiny->errstr . " $path";

	return $yaml->[0];
}

# Simple helper routine for properly slurping UTF-8 files
sub read_utf8 {
	my ($path) = @_;
	my $file; 
	$file = read_file($path, binmode => ':utf8', err_mode => 'carp');
	unless($file) {
		die IOException->throw( error=>"File: $path not found");
	}
	return $file;
}

# This routine should return the path to this package. If we are running
# mod_perl this path needs to be absolute.
sub get_dir {
	if(defined(DIR)) {
		return DIR;
	} else {
		return '';
	}
}

# Creates a hash of the value salted with salt from config
sub create_hash {
	my ($self, $value) = @_;
	return sha256_hex($self->{config}->{salt} . $value);
}

# Encode or decodes a literal from or to an IDNA.
sub	idna_transform  {
	my ($self, $domain, $encode) = @_;

	# When we encode the literal, we must first properly decode from
	# UTF8.
	if($encode) {
		$domain = decode utf8=>$domain;
	}

	if(!defined($domain)) {
		return;
	}

	my @fqdm = split(/\./, $domain);
	my $encoded;

	# Probably not a domain, return the literal.
	if(@fqdm <= 1) {
		return $domain;
	}

	# Pop the TLD for this FQDM
	my $tld = pop(@fqdm);

	# Encode or decode each part of the sub domain(s).
	foreach my $item(@fqdm) {
		my $next;

		if($encode) {
			$next = encode_punycode($item);
		} else {
			$next = decode_punycode($item);
		}

		if(defined($encoded)) {
			$encoded = "$encoded.$next";
		} else {
			$encoded = $next;
		}
	}

	# Return the domain concatenated with the TLD.
	return "$encoded.$tld";
}

1;
