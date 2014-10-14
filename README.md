ics2baikal
==========
Transform ICS calendar file to Baikal database

Usage
=====
--ics=xxx
	ICS file to import (require)

--sqlite=xxx
	Baikal SQLite DB (require)

--calendarid=x
	Calendar ID to import event (require)

--usage ou --help
	Display this message

--quiet
	No output

Example
=======
perl ics2baikal.pl --ics=bob.ics --sqlite=db.sqlite --calendarid=15