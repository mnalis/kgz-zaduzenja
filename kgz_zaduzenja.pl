#!/usr/bin/perl -T
# Matija Nalis <mnalis-perl@voyager.hr> GPLv3+, started 6.11.2018
#
# cron alarmiranje za zaduzenja za posudbe u Knjiznicama Grada Zagreba
# https://github.com/mnalis/kgz-zaduzenja
#

use utf8;
use warnings;
use strict;
use autodie qw(:all);
use feature 'say';

use HTTP::Cookies;
use WWW::Mechanize;
use DateTime;

my $SANE_DAYS = 90;
my $DEBUG = $ENV{DEBUG} || 0;

binmode STDOUT, ":encoding(UTF-8)";
binmode STDERR, ":encoding(UTF-8)";

my $email = shift @ARGV;
my $lozinka = shift @ARGV;
my $WARN_DAYS = shift @ARGV || 5;
die "Usage: $0 <email> <password> [WARN_DAYS]" if !defined $email or !defined $lozinka;

$0="kgz_zaduzenja.pl";	# clear password from commandline for security (NOTE:there is still a small window of time while it can be seen in ps(1))

$DEBUG && say "WARN_DAYS=$WARN_DAYS SANE_DAYS=$SANE_DAYS";
my $mech	= WWW::Mechanize->new();

my $auth_url = 'https://katalog.kgz.hr/eZaKi/Login';
#$mech->add_header ('Referer' => 'https://katalog.kgz.hr/eZaKi/');
$mech->get( $auth_url );
$DEBUG > 2 && say "Auth login1 $auth_url (" . $mech->status() . ' ' . $mech->res()->message . ') ' . $mech->content_type() . ': >' . $mech->content() . '<';
$DEBUG > 3 && say "Cookie Jar1:\n", $mech->cookie_jar->as_string;

$mech->submit_form (
	form_number => 1, 
	fields => {
		 'ctl00$MainContent$Email' => $email,
		 'ctl00$MainContent$Password' => $lozinka
	},
	button => 'ctl00$MainContent$btnLogIn'
);

$DEBUG > 2 && say "Auth login2 $auth_url (" . $mech->status() . ' ' . $mech->res()->message . ') ' . $mech->content_type() . ': >' . $mech->content() . '<';
$DEBUG > 3 && say "Cookie Jar2:\n", $mech->cookie_jar->as_string;

my $zaduzenja_url = 'https://katalog.kgz.hr/eZaKi/zaduzenja';
$mech->add_header ('Referer' => 'https://katalog.kgz.hr/eZaKi/Home');
$mech->get( $zaduzenja_url );
$DEBUG > 4 && say "Auth login3 $zaduzenja_url Zaduzenja: " . $mech->content();
$DEBUG > 3 && say "Cookie Jar3:\n", $mech->cookie_jar->as_string;


use HTML::TreeBuilder::XPath;
my $tree= HTML::TreeBuilder::XPath->new;
$tree->parse_content( $mech->content() );
# DEBUG -- open my $debug_fh, '<:encoding(UTF-8)', './samples/example.html' || die "Can't open UTF-8 encoded ./a: $!"; $tree->parse_file( $debug_fh );


# check if expected headers match
my @head= $tree->findvalues( '//table/thead/tr/th');
my $real_h = join (':', @head);

# OLD my $expect_h = "Posuđeno:Datum povrata:Knjižnica:Građa:Status:Naslov";
my $expect_h = "Povrat:Naslov:Knjižnica:Građa:Posuđeno";
die "headers mismatch: wanted: $expect_h, got: $real_h" if $real_h ne $expect_h;

# headers ok, go parse the data
$DEBUG > 1 && say "\n\n$real_h";
my @books= $tree->findnodes( '//table/tbody/tr');

my $now = DateTime->today;


foreach my $book (@books) {
	my @td=$book->findvalues( './td');
	#old $expect_h = "Posuđeno:Datum povrata:Knjižnica:Građa:Status:Naslov";
	#my ($datum_pos, $datum_pov, $knjiznica, $vrsta, $status, $naslov) = @td;
	#new $expect_h = "Povrat:Naslov:Knjižnica:Građa:Posuđeno";
	my ($datum_pov, $naslov, $knjiznica, $vrsta, $datum_pos ) = @td;
	$DEBUG > 1 && say "parsed:\n\t$datum_pos\n\t$datum_pov\n\t$knjiznica\n\t$vrsta\n\t$naslov";
	if ($datum_pov =~ m/^(\d{1,2})\.(\d{1,2})\.(\d{4})\./) { $datum_pov = "$1.$2.$3." } else { die "invalid date: $datum_pov"; }
	$DEBUG && say "checking: $datum_pov\t$naslov";

	my $expire = DateTime->new( day => $1, month => $2, year => $3 );
	my $diff_days = $expire->clone()->delta_days($now);			# NB DateTime really sucks, as it can't convert months to hours, so $expire-$now will silently return wrong results!
	$diff_days = $diff_days->in_units('days') * ($now>$expire ? -1 : 1);	# NB DateTime::Duration also sucks as it always returns positive results... Be extra extra careful with big test suite to see it actually works

	$DEBUG && say "\tnow=" . $now->ymd() . ", istek=" . $expire->ymd() . ", diff=$diff_days";

	if (abs($diff_days) > $SANE_DAYS) {
		say "WARNING: days $diff_days is too long (>$SANE_DAYS), check for errors or update \$SANE_DAYS";
	}

	if ($diff_days <= $WARN_DAYS) {
		if ($diff_days <= 0) {
			say "ERROR: prije $diff_days dana (" . $expire->ymd() . ") JE ISTEKLA knjiga:\t$naslov";
		} else {
			say "WARNING: za $diff_days dana (" . $expire->ymd() . ") istjece knjiga:\t$naslov";
		}
	}
}


exit 0;
