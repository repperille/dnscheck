#!/usr/bin/perl

package DNSCheckWeb::Exceptions;

use Exception::Class (
	DomainException => {
		description => 'Domain name was invalid.',
	},
	TestException => {
		description => 'The test id was invalid.',
	},
);

1;
