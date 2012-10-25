#!/usr/bin/perl

use warnings;
use strict;
use Data::Dumper;

use File::Basename;
use YAML qw{LoadFile DumpFile};
use open qw(:std :utf8);

unless (@ARGV == 2 || @ARGV == 3) {
    print "usage: $0 locale_source to_file\n";
    print "or: $0 locale_source locale_id locale_name\n";
    exit(1);
}

my $blueprint = LoadFile($ARGV[0]);
my $replica;
my $to_file;

# When creating a new file
if(@ARGV == 3) {
	$replica = {
		locale_id => $ARGV[1],
		locale_name => $ARGV[2],
		messages => {}
	};
	$to_file = to_filename($ARGV[0])."/$ARGV[1].yaml";
}
# Load existing file
else {
	$replica = LoadFile($ARGV[1]);
	$to_file = $ARGV[1];
}

# Ensure that we have a hash
if(!defined($replica->{messages}) || ref($replica->{messages}) ne "HASH") {
	$replica->{messages} = {};
}

# Some simpler references
my $blueprint_msg = $blueprint->{messages};
my $replica_msg = $replica->{messages};
my $update_count = 0;

# Some information
print "From locale '$blueprint->{locale_id}' to '$replica->{locale_id}'\n";
print "($blueprint->{locale_name} to $replica->{locale_name})\n";
print "Commands:\n";
print "	skip: skip current message\n";
print "	save: saves and exit.\n";
print "	quit: quit without saving.\n\n";

# Iterate over the 'source', and add non-existing elements
foreach my $l (keys %{ $blueprint_msg }) {

	if(!defined($replica->{messages}{$l})) {
		my $ref = $blueprint_msg->{$l};
		my $input;
		print "Message: $l (args: $ref->{args})\n";

		# Format
		if(defined($ref->{format})) {
			print "Format: $ref->{format}\n";
			print "Input: ";
			chop ($input = <STDIN>);
			action($input);
			$ref->{format} = $input;
		}

		# Description
		if(defined($ref->{descr})) {
			print "Description: $ref->{descr}\n";
			print "Input: ";
			chop ($input = <STDIN>);
			action($input);
			$ref->{descr} = $input;
		}
		$update_count++;
		$replica_msg->{$l} = $ref;
		# Regular flow, continue to next message
		next;

		# Typed save, save to file and redo last message
		CURR_SAVE:
		save($to_file, $replica);
		print "\nSaved current progress. Continue with last message.\n\n";
		redo;

		# Skipped current message
		SKIP:
	}

}

# Save to file
SAVE:
print "\n Saving to file: $ARGV[1] (added $update_count message(s)).\n";
save($to_file, $replica);
exit;

EXIT:
print "\n Did not save to file.\n";
exit;

# Do something based on input
sub action {
	my $action = shift;
	if(!defined($action)) {
		return;
	} elsif ($action =~ m/^skip/) {
		goto SKIP;
	} elsif ($action =~ m/^save|^w$/) {
		goto CURR_SAVE;
	} elsif ($action =~ m/^wq/) {
		goto SAVE;
	} elsif ($action =~ m/^quit|^q/) {
		goto EXIT;
	}
}
# Save to file
sub save {
	my ($to_file, $replica) = @_;
	DumpFile($to_file, $replica);
}
