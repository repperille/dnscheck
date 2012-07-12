#!/usr/bin/perl

package DNSCheckWeb::Exceptions;

# Some simple exception classes
use Exception::Class (
	DomainException => {
		description => 'Domain name was not valid.',
	},
	TestException => {
		description => 'Test id was not valid.',
	},
	SourceException => {
		description => 'Source was not valid.',
	},
	DBException => {
		description => 'A database error occurred.',
	},
);

1;
