#!/usr/bin/perl

package DNSCheckWeb::Exceptions;

use Exception::Class (
	DomainException => {
		description => 'Domain name was invalid.',
	},
	TestException => {
		description => 'The test id was invalid.',
	},
	SourceException => {
		description => 'Specified source is not valid.',
	},
);

1;
