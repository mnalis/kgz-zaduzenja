USER=$(shell find . -maxdepth 1 -name Makefile -printf %u)

nothing:
	@echo Doing nothing as user=$(USER)...

update:
	umask 077; if [ "`id -un`" = "$(USER)" ] ; then git pull; else env -i setuidgid $(USER) git pull; fi
	chmod -R a=rX COPYING
	chmod 700 *.cgi kgz_zaduzenja.pl .git

publish:
	git commit -a || true
	git push --all
