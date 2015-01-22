PERL = /usr/bin/perl
INSTALL = /usr/bin/install
MOD_INSTALL = $(PERL) -MExtUtils::Install -e 'install([ from_to => {@ARGV} ]);' --
LN = /bin/ln

WWWDEST = /var/www/dnscheck
APPDEST = /usr/local/share/dnscheck
VHOSTS = /etc/apache2/sites-available

install:
	umask 022; 
	$(MOD_INSTALL) web $(WWWDEST)
	$(MOD_INSTALL) web/css $(WWWDEST)/css
	$(MOD_INSTALL) web/js $(WWWDEST)/js
	$(MOD_INSTALL) lib $(APPDEST)/lib
	$(MOD_INSTALL) language $(APPDEST)/language
	$(MOD_INSTALL) templates $(APPDEST)/templates
#	$(INSTALL) config-prod.yaml $(APPDEST)/config.yaml
	$(INSTALL) startup.pl $(APPDEST)
#	$(INSTALL) vhost_dnscheck $(VHOSTS)/dnscheck

install-test:
	$(INSTALL) vhost_dnscheck_test $(VHOSTS)/dnscheck-test
