#!/usr/bin/perl

use Test::More;
use lib "t/lib";
use MockResolver 'undelegated';
# use MockBootstrap 'undelegated';
# $MockResolver::verbose = 1;

use File::Temp 'tempfile';
my ($fh, $filename) = tempfile();

use_ok('DNSCheck');

my $dc = new_ok('DNSCheck' => [{configdir => './t/config'}]);

sub has {
    my @tags = @_;
    foreach my $tag (@tags) {
        ok(scalar(grep {$_->[3] eq $tag} @{$dc->logger->export}) > 0, "Has $tag");
    }
    $dc->logger->clear;
}

ok $dc->add_fake_ds('nic.se.	3600	IN	DS	16696  5  2  40079ddf8d09e7f10bb248a69b6630478a28ef969dde399f95bc3b39f8cbacd7');
ok $dc->add_fake_ds('nic.se.	3600	IN	DS	16696  5  1  ef5d421412a5eaf1230071affd4f585e3b2b1a60');

$dc->add_fake_glue('nic.se', 'ns.nic.se');
$dc->add_fake_glue('nic.se', 'ns2.nic.se');
$dc->add_fake_glue('nic.se', 'ns3.nic.se');

$dc->config->{disable}{mail}{test} = 1;

$dc->zone->test('nic.se');

has(qw[DNSSEC:DS_FOUND DNSSEC:DS_ALGORITHM DNSSEC:DS_TO_SEP]);

{
    local *STDERR;
    open STDERR, '>', $filename or die $!;
    ok !$dc->add_fake_ds('gurksallad');
    my $tmpstr = join('',<$fh>);
    like($tmpstr, qr/Malformed DS data \(no fake record added\): gurksallad/);
    unlink $filename or die $!;
}

done_testing();
