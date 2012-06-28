#!/usr/bin/perl
use warnings;
use strict;

package DNSCheckWeb::DB;

use Carp;

# Constants
use constant TYPE_PG => "postgresql";
use constant TYPE_MYSQL => "mysql";

my $dbo;

sub new {
	my $class = shift;

	# We expect some database info.
	my $db_info = shift;
	# Create empty object, will be filled.
	my $self = {};

	if(!defined($db_info)) {
		croak "No database information given";
	}

	# Initialize variables, should load database depending on what type.
	if($db_info->{type} eq TYPE_PG) {
		$self = {
			connect =>
			"DBI:Pg:database=%s;host=%s;port=%s",
			tbl_begin => "started",
			tbl_end => "finished",
			tbl_level => "degree"
		};
	} elsif($db_info->{type} eq TYPE_MYSQL) {
		$self = {
			connect =>
			"DBI:Pg:database=%s;host=%s;port=%s",
			tbl_begin => "started",
			tbl_end => "finished",
			tbl_level => "degree"
		};
	} else {
		croak "\'$db_info->{type}\' is not a known database type";
	}

	#Setup actual connection
	my $dsn  = sprintf($self->{connect}, $db_info->{database}, $db_info->{host}, $db_info->{port});
	my $dbh;
	eval {
	    $dbh =
	      DBI->connect($dsn, $db_info->{user}, $db_info->{password},
	        { RaiseError => 1, AutoCommit => 1, PrintError => 0 });
	};
	if ($@) {
		carp "Failed to connect to database: $@";
	}

	if(defined($dbh)) {
		$self->{dbh} = $dbh;
	} else {
		croak "Cannot connect to database";
	}

	bless $self, $class;
	return $self;
}

# Fire of a new check, return id.
sub start_check {
	my $self = shift;
	my $domain = shift;

	my $dbh = $self->{dbh};
	my $query = $dbh->prepare(q{
		INSERT INTO queue (domain, priority) VALUES (?, 10)})
		or die "Could not prepare statement";
	$query->execute($domain);
	#$query = "INSERT INTO queue (domain, priority, source_id, source_data, fake_parent_glue) VALUES ('" . DatabasePackage::escape($domain) . "', 10, $id, '" . DatabasePackage::escape($sourceData) . "', '" . DatabasePackage::escape($sourceData) . "')";
}

# Fetches the version of DNSChecker that we are running.
sub get_version {
	my $self = shift;

	my $dbh = $self->{dbh};
	my $query = $dbh->prepare(q{
		SELECT arg1 FROM results WHERE message = 'ZONE:BEGIN' and test_id = (select max(test_id) from results)
		ORDER BY test_id DESC LIMIT 1;});
	$query->execute();
	return $query->fetchrow_arrayref;
}

1;
