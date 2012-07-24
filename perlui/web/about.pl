#!/usr/bin/perl
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
my $suffix = $dnscheck->{config}->{suffix_about};
if(!defined($suffix)) {
	$suffix = '';
}

# Have to get the current path from our object
# We need to be sure that $locale has been validated before using it,
# otherwise it could lead to some path traversal.
my $path = $dnscheck->get_dir() . "../lng/";
my $post = "_about.html";

# Read file in using slurp instead of including directly in template
# toolkit. The latter does not encode properly.
my $content;

# Try to read the file
eval {
	$content = DNSCheckWeb::read_utf8("$path$locale$suffix$post");
};
if(my $e = IOException->caught()) {
	# Die if debug is turned on
	if($dnscheck->{config}->{debug}) {
		$dnscheck->render_error($e);
	}
	# Fall back to standard file. Some would only customize their locale.
	else {
		$content = DNSCheckWeb::read_utf8("$path$locale$post");
	}
}

# Render result
$dnscheck->render('about.tpl', {
	content => $content
});
