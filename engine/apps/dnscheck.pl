#!/usr/bin/perl
#
# $Id$
#
# Copyright (c) 2007 .SE (The Internet Infrastructure Foundation).
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

require 5.8.0;
use warnings;
use strict;

use Getopt::Long;
use Pod::Usage;
use YAML qw(LoadFile Dump);
use Data::Dumper;
use DNSCheck;

use vars qw[$CONFIG_DIR $POLICY_DIR $LOCALE_DIR];

$CONFIG_DIR = '@@CONFIG_DIR@@';
$POLICY_DIR = '@@POLICY_DIR@@';
$LOCALE_DIR = '@@LOCALE_DIR@@';

######################################################################

sub main {
    my $help    = 0;
    my $debug   = 0;
    my $timeout = 5;
    my $raw     = 0;

    my $config_file = $CONFIG_DIR . "/config.yaml";
    my $policy_file = $POLICY_DIR . "/policy.yaml";
    my $locale      = 'en';

    GetOptions(
        'help|?'   => \$help,
        'raw'      => \$raw,
        'debug+'   => \$debug,
        'config=s' => \$config_file,
        'policy=s' => \$policy_file,
        'locale=s' => \$locale,
    ) or pod2usage(2);
    pod2usage(1) if ($help);

    my $zone = shift @ARGV;

    unless ($zone) {
        pod2usage(2);
    }

    my $extras = {};
    $extras->{logging}->{interactive} = 1;
    $extras->{debug} = $debug;

    my $check = new DNSCheck(
        {
            configfile => $config_file,
            policyfile => $policy_file,
            extras     => $extras,
            locale     => ($raw ? undef : $locale),
        }
    );

    $check->zone($zone);
}

main();

__END__

=head1 NAME

dnscheck - DNSCheck Tool

=head1 SYNOPSIS

dnscheck [options] zone

Options:

 --help                brief help message
 --debug               enable debugging. use twice for dns packet dump.
 --raw                 raw log output, suitable for automatic processing
 --config              specify a configuration file
 --policy              specify a policy file
 --locale              specify a locale
