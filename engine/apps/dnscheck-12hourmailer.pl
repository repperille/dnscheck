#!/usr/bin/perl
#
# $Id: $
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

use strict;
use warnings;

use DNSCheck;
use Net::SMTP;
use DBI;
use MIME::Lite;

my $reggie;
my $dc;
my $source_id;

sub setup {
    $dc = DNSCheck->new({ locale => "en" });
    $reggie = get_reggie_dbh($dc->config->get("reggie"));
    my $source_name = $dc->config->get("12hour")->{sourcestring};
    ($source_id) = $dc->dbh->selectrow_array(q[SELECT id FROM source WHERE name = ?], undef, $source_name);
    die "No source information in database.\n" unless defined($source_id);
}

sub text_for_domain {
    my $tref   = shift;
    my $body   = "";
    my $locale = $dc->locale();
    my $len    = length($tref->{domain});
    $len = 9 if $len < 9;

    my $rref = $dc->dbh->selectall_arrayref(
        q[
        SELECT id,test_id,line,module_id,parent_module_id,
            timestamp,level,message,arg0,arg1,arg2,arg3,
            arg4,arg5,arg6,arg7,arg8,arg9
        FROM results
        WHERE test_id = ? AND (level = 'ERROR' OR level = 'CRITICAL')
        ORDER BY id ASC
    ], undef, $tref->{id}
    );

    $body = sprintf(
        "%${len}s: %d critical problems and %d errors.\n",
        $tref->{'domain'}, $tref->{count_critical},
        $tref->{count_error}
    );

    foreach my $l (@{$rref}) {
        my @tmp = grep { defined($_) } @{$l}[7 .. 999];
        $body .= sprintf("%${len}s: %s\n", $l->[6], $locale->expand(@tmp));
    }

    return $body;
}

sub generate_mail_text_for_registrar {
    my $name = shift;
    my $ref  = shift;
    my $body = "";

    foreach my $d (keys %{ $ref->{domains} }) {
        $body .= text_for_domain($ref->{domains}{$d});
        $body .= "\n\n";
    }

    my $msg = MIME::Lite->new(
        From    => $dc->config->get("12hour")->{from},
        To      => $ref->{mail},
        Subject => $dc->config->get("12hour")->{subject},
        Data    => $body
    );
    $msg->attr('content-type.charset' => 'UTF-8');

    return $msg;
}

sub get_reggie_dbh {
    my $conf = shift;

    my $dsn = sprintf("DBI:mysql:database=%s;hostname=%s;port=%s",
        $conf->{"database"}, $conf->{"host"}, $conf->{"port"});

    my $dbh =
      DBI->connect($dsn, $conf->{"user"}, $conf->{"password"},
        { RaiseError => 1, AutoCommit => 1 });
    die "Failed to connect to Reggie: " . $DBI::errstr unless defined($dbh);

    return $dbh;

}

sub get_registrar_info {
    my $domain = shift;

    my ($email3, $display_name) = $reggie->selectrow_array(
        q[
        select EMAIL3, DISPLAY_NAME
        from REGISTRARS, USERS, DOMAINS
        where DOMAINS.NAME = ? and DOMAINS.CLID = USERS.USER_ID and DOMAINS.CLID = REGISTRARS.EPP_USER_ID
        ], undef, $domain
    );

    return ($email3, $display_name);
}

sub aggregate_registrar_info {
    my @domains = @_;
    my %res;

    foreach my $d (@domains) {
        my ($mail, $name) = get_registrar_info($d);
        $mail = 'no.email.given@iis.se'    unless defined($mail);
        $name = "Unknown registrar for $d" unless defined($name);
        $res{$name}{mail} = $mail;
        $res{$name}{domains}{$d} = get_test_results($d);
    }
    return %res;
}

sub domains_tested_last_day {
    my $aref = $dc->dbh->selectall_arrayref(
        q[
        SELECT DISTINCT domain
        FROM tests
        WHERE begin > subtime(now(),?) 
            AND (count_critical + count_error) > 0
            AND source_id = ?
        ], undef, $dc->config->get("12hour")->{timespan}, $source_id
    );
    return map { $_->[0] } @$aref;
}

sub get_test_results {
    my $domain = shift;

    my $test = $dc->dbh->selectrow_hashref(
        q[
        SELECT * FROM tests WHERE domain = ? ORDER BY id DESC LIMIT 1
        ], undef, $domain
    );
    die "Domain $domain not tested!\n" unless $test;
    return $test;
}

setup();
my %data = aggregate_registrar_info(domains_tested_last_day());

foreach my $reg (keys %data) {
    if ($dc->config->get("12hour")->{debug}) {
        print generate_mail_text_for_registrar($reg, $data{$reg})->as_string;
    } else {
        generate_mail_text_for_registrar($reg, $data{$reg})
          ->send('smtp', $dc->config->get("12hour")->{smtphost});
    }
}

=head1 NAME

dnscheck-12hourmailer - email registrars about problems in their domains

=head1 DESCRIPTION

This script will look through the C<tests> table in the L<DNSCheck> database,
pick out the ones that resulted in problems classified at level C<CRITICAL> or
C<ERROR>, group the domains thus found by registrar and send each registrar an
email listing the problematic zones and some basic information on the problems.

The registrar data is taken from the REGGIE database for the C<.se> domain,
and thus the script will probably be of limited use to other organisations as
is. Other users will almost certainly need to write their own version of the
L<get_registrar_info> function. It expects a single domain name as its input,
and returns C<undef> (if no registrar could be found) or a two-element list
with the contact email address for and name of the relevant registrar (in that
order).

It might be useful to simply make the function return a fixed list with an
email address and a name string, in which case single email with all problems
will be sent to the address given.

=head1 CONFIGURATION

This script uses the same YAML files as the rest of the DNSCheck system. It
looks for its information under the key C<12hour>. The subkeys it uses are the
following.

=over

=item smtphost

The full name of the SMTP server to use for sending emails.

=item from

The string to put in the C<From> line of the sent emails.

=item subject

The string to put in the C<subject> line of the sent emails.

=item timespan

How far into the past the script should look for tests. The value should be a
string that will be understood as a time value by MySQL (for example,
"12:00:00" is twelve hours, zero minutes and zero seconds).

=item debug

A Perl boolean value. If it is true, emails will be printed to standard output
instead of sent.

=item sourcestring

The string identifying the source of the tests to consider mailing about.

=back
