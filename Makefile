USER=$(shell find . -maxdepth 1 -name Makefile -printf %u)
PREFIX=/usr/local
BINDIR=$(PREFIX)/bin
SCRIPT=$(BINDIR)/kgz_zaduzenja

nothing:
	@echo Doing nothing as user=$(USER)...

update:
	umask 077; if [ "`id -un`" = "$(USER)" ] ; then git pull; else env -i setuidgid $(USER) git pull; fi
	chmod -R a=rX LICENSE
	chmod 700 kgz_zaduzenja.pl .git

publish:
	git commit -a || true
	git push --all

install:
	install -o root -g root -m 755 kgz_zaduzenja.pl $(SCRIPT)
	@echo
	@echo "Remember to setup 'crontab -e' like this:"
	@echo "15 1 * * *	$(SCRIPT) MY_ID MY_PIN WARN_DAYS"

uninstall:
	rm -f $(SCRIPT)
	@echo
	@echo "Remember to remove $(SCRIPT) from 'crontab -e'"

clean:
	find . -iname "*~" -delete

.PHONY: nothing update publish install uninstall clean
