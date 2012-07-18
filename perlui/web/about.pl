#!/usr/bin/perl
use strict;
use warnings;

# Load needed libraries
use DNSCheckWeb;
use Data::Dumper;

my $dnscheck = DNSCheckWeb->new();
my $cgi = $dnscheck->get_cgi();
my $locale = $cgi->param('locale');

# Load language, and sets the locale given that it was valid.
my $lng = $dnscheck->get_lng($locale);
$locale = $lng->{locale};

# Render result
$dnscheck->render('about.tpl', {
	about_path => "../lng/".$locale."_about.html"
});
