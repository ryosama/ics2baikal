#!/usr/bin/perl

my $VERSION = 1.0;

use strict;
use Digest::MD5 qw(md5_hex);
use Getopt::Long;
use Time::Local;
use DBI qw(:sql_types); #sqlite

my ($ics,$sqlite,$calendarid,$dry_run,$help,$quiet);
GetOptions('ics:s'=>\$ics, 'sqlite:s'=>\$sqlite, 'calendarid:i'=>\$calendarid, 'dry-run!'=>\$dry_run, 'help|usage!'=>\$help, 'quiet!'=>\$quiet) ;
die <<EOT if ($help || length($ics)<=0 || length($sqlite)<=0 || $calendarid<=0);
Parameters :
--ics=xxx
	ICS file to import (require)

--sqlite=xxx
	Baikal SQLite DB (require)

--calendarid=x
	Calendar ID to import event (require)

--dry-run
	Only do a simulation

--usage or --help
	Display this message

--quiet
	No output
EOT

die "Unable to find ics file '$ics'" unless -e $ics;
open(ICS,"<$ics") or die "Unable to open ics file '$ics' ($!)";
my $content = join('',<ICS>);
close(ICS);

die "Unable to find sqlite DB '$sqlite'" unless -e $sqlite;
my $sqlite = DBI->connect("dbi:SQLite:$sqlite",'','',{ RaiseError => 0, AutoCommit => 0 }) or die("Unable to open SQLite DB '$sqlite'");
my $sql_col = "INSERT INTO calendarobjects (calendardata,uri,calendarid,lastmodified,etag,size,componenttype,firstoccurence,lastoccurence) VALUES ";

if ($dry_run) {
	print "I'm running in dry-run mode, I won't do anything\n" unless $quiet;
}

while($content =~ /(BEGIN:VEVENT.+?END:VEVENT)/gis) { # match an event
	my $event = "BEGIN:VCALENDAR\n$1\nEND:VCALENDAR";
	my ($uid) = ($event =~ m/^UID:(.+)$/im);
	my ($lastmodified) 	= ($event =~ m/^LAST-MODIFIED:(.+)$/im);
	my ($eventstart) 	= ($event =~ m/^DTSTART:(.+)$/im);
	my ($eventend) 		= ($event =~ m/^DTEND:(.+)$/im);
	print "EVENT detected : $uid\n" unless $quiet;

	my $sql  = 	$sql_col.
				"('".quotify($event)."','$uid','$calendarid','".icaldate2epoch($lastmodified)."','".md5_hex($event)."','".length($event)."','VEVENT','".icaldate2epoch($eventstart)."','".icaldate2epoch($eventend)."');";
	$sqlite->do($sql) unless $dry_run; # record event in database
}

$sqlite->commit;
$sqlite->disconnect();

############################################ USEFUL ##########################################################################
sub quotify($) {
	my $str = shift;
	$str =~ s/'/''/g;
	return $str;
}

sub icaldate2epoch($) {
	my $ical = shift;
	if ($ical =~ /^.*?:?(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2})(\d{2}))?/i) { # valid ical date	20110915T084903Z or 20110915 or Europe/Paris:20110916T163000
		return timelocal($6,$5,$4,$3,$2 - 1, $1);
	} else {
		return 0;
	}
}