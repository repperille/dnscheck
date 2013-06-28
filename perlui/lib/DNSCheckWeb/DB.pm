#!/usr/bin/perl
# 
# Copyright (c) 2012 UNINETT Norid AS.
# All rights reserved.
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

#
# Module for all database interaction.
#
use warnings;
use strict;

package DNSCheckWeb::DB;

my $dbo;

sub new {
	my ($class, $config) = @_;

	# Check that we have database information
	unless(defined($config) || defined($config->{dbi})) {
		die DBException->throw( error => "No database information provided.");
	}

	# Assign database meta information on the specified type
	my $dbi = $config->{dbi};
	my $db_meta = $config->{$dbi->{type}};

	# Check that given database type matches one in config
	unless(defined($db_meta)) {
		die DBException->throw( error => "Could not load db information for the type: $dbi->{type}");
	}

	# Construct connect statement
	my $dsn  = sprintf($db_meta->{driver}, $dbi->{database}, $dbi->{host}, $dbi->{port});
	# Do connection
	my $dbh = DBI->connect($dsn, $dbi->{user}, $dbi->{password}, {
		RaiseError => 0, AutoCommit => 1, PrintError => 1, pg_enable_utf8 => 1
	})
	or die DBException->throw( error=> $DBI::errstr);

	# Assign reference if everything worked out
	my $self = { };
	if(defined($dbh)) {
		$self->{dbh} = $dbh;
	} else {
		DBException->throw( error => "Could not connect to the database");
	}

	# Assign meta information
	# Tables
	$self->{begin} = $db_meta->{tbl_begin};
	$self->{end} = $db_meta->{tbl_end};
	$self->{level} = $db_meta->{tbl_level};
	# Functions
	$self->{time} = $db_meta->{fun_time};
	$self->{now} = $db_meta->{fun_now};
	$self->{format} = $db_meta->{fun_time_format};

	bless $self, $class;
	return $self;
}

# Fires of a new check
sub start_check {
	my ($self, $domain, $source, $source_data) = @_;

	# Check that source already exist
	my $source_id = $self->get_source_id($source);

	my $dbh = $self->{dbh};
	my $query = $dbh->prepare(q{
		INSERT INTO
		queue (domain, priority, source_id, source_data, fake_parent_glue)
		VALUES (?, 10, ?, ?, ?)})
		or die DBException->throw( error => $self->{dbh}->errstr);
	$query->execute($domain, $source_id, $source_data, $source_data)
	or die DBException->throw( error => $self->{dbh}->errstr);
}

# Returns id for the given source, or creates a new one.
sub get_source_id {
	my($self, $source) = @_;

	my $dbh = $self->{dbh};
	my $query = $dbh->prepare(q{
		SELECT id FROM source WHERE name = ?})
		or die "Could not prepare statement";
	$query->execute($source);

	my $result = $query->fetchrow_arrayref;
	# Insert new source
	if(!defined($result)) {
		$query = $dbh->prepare(q{ INSERT INTO source (name) VALUES (?) })
		or die DBException->throw( error => $self->{dbh}->errstr);
		$query->execute($source)
		or die DBException->throw( error => $self->{dbh}->errstr);

		return $dbh->last_insert_id(undef, undef, qw(source id));
	} else {
		# Dereference and return result
		return @$result[0];
	}
}

# Checks the queue for a running result
sub get_running_result {
	my ($self, $domain, $source, $source_data) = @_;

	my $query = $self->{dbh}->prepare("
		(SELECT
			NULL AS id, NULL AS time, 'NO' AS finished,
			source_data AS source_data,
			inprogress AS started
		FROM queue
			INNER JOIN
				source ON source.id = queue.source_id
				AND source.name = ?
		WHERE
			queue.domain = ? AND queue.source_data = ?)
		UNION
		(SELECT
			tests.id AS id,
			".$self->time("tests.$self->{end}")." AS TIME,
			CASE tests.$self->{end}
				WHEN NULL THEN 'NO'
				ELSE 'YES'
				END AS finished,
			source_data AS source_data,
			NULL AS started
		FROM tests
			INNER JOIN
				source ON source.id = tests.source_id AND source.name = ?
		WHERE
			tests.domain = ? and tests.source_data = ?
			AND (
				tests.$self->{end} = NULL
				OR
				(".$self->time()." - ".$self->time("tests.$self->{end}")." < 300))
		LIMIT 1)")
	or die DBException->throw( error => $self->{dbh}->errstr);
	$query->execute($source, $domain, $source_data, $source, $domain, $source_data)
	or die DBException->throw( error => $self->{dbh}->errstr);

	return $query->fetchrow_hashref;
}

# Returns all test results for a given test id. Joins on messages for those
# results (using the locale).
# TODO: Optimize, add custom fall back language?
sub get_test_results {
	my ($self, $test_id, $locale) = @_;

	my $query = $self->{dbh}->prepare("
		SELECT *
		FROM results LEFT JOIN messages
		ON results.message = messages.tag
		AND messages.language IN (
			SELECT COALESCE(o.language, e.language)
			FROM messages e LEFT OUTER JOIN messages o
			ON o.tag = e.tag AND o.language = ?
			WHERE e.language = 'en'
			AND e.tag = messages.tag
		)
		WHERE
		results.test_id = ?
		AND results.$self->{level} != 'DEBUG'
		ORDER BY results.id;")
	or die DBException->throw( error => $self->{dbh}->errstr);
	$query->execute($locale, $test_id)
	or die DBException->throw( error => $self->{dbh}->errstr);

	return $query->fetchall_arrayref;
}

# Returns the latest test history for the given test id
sub get_history {
	my ($self, $test_id) = @_;

	my $dbh = $self->{dbh};
	my $query = $dbh->prepare("
		SELECT
			test2.id AS id,
			" . $self->time_present("test2.$self->{begin}") ." AS TIME,
			CASE
				WHEN test2.count_error > 0 THEN 'error'
				WHEN test2.count_warning > 0 THEN 'warning'
				ELSE 'ok'
			END AS class
		FROM tests AS test1
			INNER JOIN tests AS test2 ON test1.domain = test2.domain
			AND test1.source_id = test2.source_id
			AND test1.source_data = test2.source_data
			AND test1.id != test2.id
		WHERE test1.id = ?
		ORDER BY id DESC
		LIMIT 5;
	")
	or die DBException->throw( error => $self->{dbh}->errstr);
	$query->execute($test_id)
	or die DBException->throw( error => $self->{dbh}->errstr);

	return $query->fetchall_arrayref;
}

# A tiny bit of statistics for the showing result
sub get_test_data {
	my ($self, $test_id) = @_;

	my $dbh = $self->{dbh};
	my $query = $dbh->prepare("
		SELECT
			".$self->time_present($self->{begin})." AS started,
			".$self->time_present($self->{end})." AS finished,
			count_critical AS critical,
			count_error AS error,
			count_warning AS warning,
			count_notice AS notice,
			count_info AS info
		FROM tests
		WHERE id = ?
	")
	or die DBException->throw( error => $self->{dbh}->errstr);
	$query->execute($test_id)
	or die DBException->throw( error => $self->{dbh}->errstr);

	return $query->fetchrow_hashref;
}

# Returns the version of DNSChecker that we are running.
sub get_version {
	my $self = shift;

	my $dbh = $self->{dbh};
	my $query = $dbh->prepare(q{
		SELECT arg1 AS version
		FROM results
		WHERE message = 'ZONE:BEGIN' and test_id = (select max(test_id) from results)
		ORDER BY test_id DESC LIMIT 1;})
	or die DBException->throw( error => $self->{dbh}->errstr);
	$query->execute()
	or die DBException->throw( error => $self->{dbh}->errstr);

	return $query->fetchrow_hashref;
}

# Routines for cross database compability

# Returns the timestamp for the specified table relative to epoch, or
# now() relative to epoch.
sub time {
	my ($self, $field) = @_;
	if(defined($field)) {
		return sprintf($self->{time}, $field);
	}
	return $self->{now};
}

# Formats the date to be human readable.
sub time_present {
	my ($self, $field) = @_;
	sprintf($self->{format}, $field);
}

1;
