#!/usr/bin/perl
use strict;
use warnings;

# Load needed libraries
use DNSCheckWeb;
use Data::Dumper;

use File::Slurp;

my $dnscheck = DNSCheckWeb->new();
my $cgi = $dnscheck->get_cgi();
my $locale = $cgi->param('locale');

# Load language, and sets the locale given that it was valid.
my $lng = $dnscheck->get_lng($locale);
$locale = $lng->{locale};

# Have to get the current path from our object
# We need to be sure that $locale has been properly tainted, since it is
# part of the built relative path.
my $path = $dnscheck->get_dir() . "../lng/" . $locale . "_about.html";

# Read file in using slurp instead of including directly in template
# toolkit. The latter does not encode properly.
my $content = DNSCheckWeb::read_utf8($path);


# Render result
$dnscheck->render('about.tpl', {
	content => $content
});
