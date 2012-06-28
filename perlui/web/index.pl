#!/usr/bin/perl
use strict;
use warnings;

# Load needed libraries
use DNSCheckWeb;
use CGI;

# Testing
use Data::Dumper;

use constant TYPES => {
	standard => "webgui",
	undelegated => "webgui-undelegated"
};

my $cgi = CGI->new();
my $host = $cgi->param("host");
my $source = TYPES->{$cgi->param("test")};
my $source_data = $cgi->param("parameters");

my $dnscheck = DNSCheckWeb->new();
my $dbo = $dnscheck->get_dbo();

# Variables for giving feedback
my $status;
my $test_id;

# Someone sent a query, no id hence insert in DB.
if(defined($host) && defined($source)) {


	my $running = $dbo->get_running_result($host, $source, $source_data);
	
	if(@$running eq 0) {
		$status = "started new run";	
		# No tests running, fire of new test.
		$dbo->start_check($host, $source, $source_data);
	} 

	if($running->[0][2] eq 'NO') {
		$status = "it's not finished...";
	}
	$test_id = $running->[0][0];
}

# Render result
$dnscheck->render('index.tpl', {
	host => $host,
	version => $dbo->get_version(),
	status => $status,
	id => $test_id,
});

1;
