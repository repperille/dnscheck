#!/usr/bin/perl
#
# Copyright (c) 2012 UNINETT Norid AS 
#                    All rights reserved.
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

# Load needed libraries
use DNSCheckWeb;
use DNSCheckWeb::Exceptions;
use Data::Dumper;

my $dnscheck = DNSCheckWeb->new();
my $cgi = $dnscheck->get_cgi();
my $locale = $cgi->param('locale');

# Load language, and sets the locale given that it was valid.
my $lng = $dnscheck->get_lng($locale);
$locale = $lng->{locale};

# Check if the config is overriding the about files
my $custom = $dnscheck->{config}->{custom_about};
if(!defined($custom)) {
	$custom = '';
}

# Have to get the current path from our object
# We need to be sure that $locale has been validated before using it,
# otherwise it could lead to some path traversal.
my $path = $dnscheck->get_dir() . $lng->{path};
my $file = "_about.html";

# Try to read the file
my $content;
eval {
	# Read file in using slurp instead of including directly in template
	# toolkit. The latter does not encode properly.
	$content = DNSCheckWeb::read_utf8("$path$locale$custom$file");
};
if(my $e = IOException->caught()) {
	# Output a bit more elaborate error message if debug is on
	if($dnscheck->{config}->{debug}) {
		my $message = $e->{message};
		$e->{message} = "Debug is turned on, to ignore this page
		turn debug off in config.yaml, and the site will fallback to the
		standard about page. To fix this error provide the correct
		language as specified in the config ($message)";
		$dnscheck->render_error($e);
	}
	# Fall back to standard file for this locale. Some would only
	# customize their locale, and let the other files (if any) fall back
	else {
		$content = DNSCheckWeb::read_utf8("$path$locale$file");
	}
}

# Render result
$dnscheck->render('about.tpl', {
	content => $content
});
