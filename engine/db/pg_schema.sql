-- $Id$

-- DNSCheck Primary Data

/*! SET FOREIGN_KEY_CHECKS=0 */;

CREATE TABLE messages (
  id SERIAL PRIMARY KEY NOT NULL,
  tag TEXT NOT NULL default '',
  arguments smallint NOT NULL default 0,
  language varchar(16) NOT NULL default 'en-US',
  formatstring TEXT default NULL,
  description text default NULL,
  UNIQUE (tag,language)
);

-- source_id should reference an entry in the source table.
-- source_data is some piece of data private to a particular source.
-- It will be copied to the tests table by the dispatcher.
-- fake_parent_glue gives necessary data to run tests on undelegated
-- domains. The content of the field must be nameserver specifikations
-- separated by spaces. Each nameserver is either simply a name, which
-- will be looked up in DNS as usual, or a name, a slash and an IP
-- address. Example: "ns.example.com ns2.example.com/127.0.0.2"

CREATE TABLE queue (
  id SERIAL PRIMARY KEY NOT NULL,
  domain TEXT default NULL,
  priority smallint NOT NULL default '0',
  inprogress timestamp default NULL,
  tester_pid integer  NULL,
  source_id integer  NULL,
  source_data TEXT NULL,
  fake_parent_glue text NULL
);

CREATE TABLE tests (
  id SERIAL PRIMARY KEY NOT NULL,
  domain TEXT NOT NULL default '',
  started timestamp default NULL, -- started instead of begin
  finished timestamp default NULL, -- finished instead of end
  count_critical integer  default '0',
  count_error integer  default '0',
  count_warning integer  default '0',
  count_notice integer  default '0',
  count_info integer  default '0',
  source_id integer  NULL,
  source_data TEXT NULL
);

CREATE TABLE results (
  id SERIAL PRIMARY KEY NOT NULL,
  test_id integer  NOT NULL,
  line integer  NOT NULL,
  module_id integer  NOT NULL,
  parent_module_id integer  NOT NULL,
  timestamp timestamp default NULL,
  degree TEXT  default NULL, -- degree ? instead of level
  message TEXT NOT NULL default '',
  arg0 TEXT default NULL,
  arg1 TEXT default NULL,
  arg2 TEXT default NULL,
  arg3 TEXT default NULL,
  arg4 TEXT default NULL,
  arg5 TEXT default NULL,
  arg6 TEXT default NULL,
  arg7 TEXT default NULL,
  arg8 TEXT default NULL,
  arg9 TEXT default NULL,
  CONSTRAINT tests FOREIGN KEY (test_id) REFERENCES tests (id) ON DELETE CASCADE
);


-- Name Service Providers

CREATE TABLE nameservers (
  id SERIAL PRIMARY KEY NOT NULL,
  nsp_id integer  NULL,
  nameserver TEXT UNIQUE NOT NULL default ''
);

CREATE TABLE nsp (
  id SERIAL PRIMARY KEY NOT NULL,
  name TEXT default '',
  email TEXT default ''
);


-- Domains and History

CREATE TABLE domains (
  id SERIAL PRIMARY KEY NOT NULL,
  domain TEXT NOT NULL default '',
  last_test timestamp default NULL,
  UNIQUE (domain)
);

CREATE TABLE delegation_history (
  id SERIAL PRIMARY KEY NOT NULL,
  domain TEXT NOT NULL default '',
  nameserver TEXT NOT NULL default '',
  UNIQUE (domain,nameserver)
);

-- Source is supposed to be a list of all sources requesting tests.
-- The recommended procedure is that a program that wants to add
-- tests adds its name and possible some contact information to this table,
-- checks what id number it got and then uses that number when inserting
-- into the queue table and selecting from the tests table.
--
-- The easiest way for a source to use this, is to do an INSERT IGNORE of a
-- string unique for that source and then SELECT the id for that string.
-- For most sources, this need only be done once on startup and then the
-- numeric id can be used to insert into the queue or select from tests.

CREATE TABLE source (
    id SERIAL PRIMARY KEY NOT NULL,
    name TEXT NOT NULL,
    contact TEXT,
    UNIQUE (name)
);
