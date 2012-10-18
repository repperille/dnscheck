DNSCheck perl-frontend
======================
An experimental (and a bit more minimalistic) perl front-end for the
DNSChecker. In its current state it supports both mysql and postgresql
as the database back end (this depends on what back end DNSCheck
initially runs on).

Dependencies
------------
The front end depends of a small set of modules:

* CGI
* CGI::Session
* DBI
* Template
* YAML::Tiny
* File::Slurp
* Digest::SHA
* Net::DNS
* JSON
* IDNA::Punycode
* Exception::Class

Prerequisites
-------------

The database should be up and running, and you should have a dedicated
'web user' which have the following privileges:

* SELECT ON results, tests, messages
* SELECT, INSERT, UPDATE ON source
* SELECT, INSERT, UPDATE DELETE ON queue

The language files from the 'engine/locale/' should have been inserted
into the messages (use 'engine/util/load_locales.pl').

Installation
------------

Installation instructions

0. Copy or symlink the perlui directory to the root of your web server.
1. Update your webserver to enable the new site. The directory
   perlui/web is the document root. Take a look at the file
   'perlui/vhost_example'.
2. Copy or move 'config_example.yaml' to 'config.yaml', and edit that file
   to reflect your own setup.

Optional:

If you are running mod_perl, you have to make the virtual host point to
the file: 'perlui/startup.pl' and also set the absolute path to the
library in the file 'perlui/lib/DNSCheckWeb.pm'.

