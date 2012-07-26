DNSCheck perl-frontend
======================
An experimental (and a bit more minimalistic) perl front-end for the
DNSChecker. In its current state it supports both mysql and postgresql
as the database back end (this is dependent on what back end DNSCheck
initially runs on).

Dependencies
------------
The front end depend of a small set of modules:

* CGI
* CGI::Session
* DBI
* Template
* YAML::Tiny
* File::Slurp
* Digest::SHA
* Net::DNS
* JSON
* Data::Validate::Domain

Installation
------------
The database should be up and running, and you should have a dedicated
'web user' which have the following privileges:

SELECT ON results, tests, messages
SELECT, INSERT, UPDATE ON source
SELECT, INSERT, UPDATE DELETE ON queue

Installation instructions

1. Copy or symlink the perlui directory to your web server.
2. Update your webserver to enable the new site. The directory
   perlui/web is the document root.

Copy or move 'config_example.yaml' to 'config.yaml', and edit this file
to reflect your own setup.

