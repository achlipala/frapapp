.PHONY: testing.exe redb extendb

testing.exe:
	urweb -protocol fastcgi testing

redb:
	-sudo -u www-data dropdb frap
	sudo -u www-data createdb frap
	sudo -u www-data psql -f testing.sql frap

extendb:
	sudo -u www-data psql -f testing.sql frap
