#!/usr/bin/perl

package DNSCheckWeb::Exceptions;

# Some simple exception classes
use Exception::Class (
	DomainException => {
		description => 'Domain name was not valid.',
	},
	TestException => {
		description => 'Test data was not valid.',
	},
	SourceException => {
		description => 'Source was not valid.',
	},
	DBException => {
		description => 'A database error occurred.',
	},
	YAMLException => {
		description => 'Could not read the specified YAML file.',
	},
	EngineException => {
		description => 'Dispatcher is not running, could not carry out check.',
	},

);

1;
