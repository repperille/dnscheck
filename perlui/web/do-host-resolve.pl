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

# This script should look up the A address for the given host and
# return that as json to the browser.
#
use strict;
use warnings;

# Load needed libraries
use DNSCheckWeb;
use JSON;
use Net::DNS;

my $dnscheck = DNSCheckWeb->new();
my $cgi = $dnscheck->get_cgi();

# Params
my $nameservers = $cgi->param('nameservers');

my @results = ();

# Resolve host names
if(defined($nameservers)) {
	# Split by pipe, and traverse each parameter
	my @ns = split(/\|/, $nameservers);
	foreach my $ns (@ns) {
		push @results, $dnscheck->resolve($ns);
	}
}

# Encode and return result
print $dnscheck->json_headers();
print JSON::to_json(\@results);
