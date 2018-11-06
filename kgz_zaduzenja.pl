#!/usr/bin/perl -T
use utf8;
use warnings;
use strict;
use autodie qw(:all);
use feature 'say';

use HTTP::Cookies;
use WWW::Mechanize;
use DateTime;

my $WARN_DAYS = 5;
my $DEBUG = $ENV{DEBUG} || 0;

binmode STDOUT, ":encoding(UTF-8)";
binmode STDERR, ":encoding(UTF-8)";


my $iskaznica = shift @ARGV;
my $pin = shift @ARGV;
die "Usage: $0 <broj_iskaznice> <PIN>" if !defined $iskaznica or !defined $pin;

my $mech	= WWW::Mechanize->new();

my $auth_url = 'https://katalog.kgz.hr/include/globalAjax.aspx?action=logMeIn&brojIskaznice=' . $iskaznica . '&pin=' . $pin . '&random=' . rand();
$mech->get( $auth_url );
$DEBUG > 1 && say "Auth login $auth_url: " . $mech->content();

$DEBUG > 1 && say "Cookie Jar:\n", $mech->cookie_jar->as_string;


my $dug_url = "https://katalog.kgz.hr/pages/mojaStranica.aspx";
$mech->post($dug_url, [ 'action' => 'getIspis', 'action2' => 'getZaduzenja']);
$DEBUG > 2 && say $mech->content();

use HTML::TreeBuilder::XPath;
my $tree= HTML::TreeBuilder::XPath->new;
$tree->parse_content( $mech->content() );
# DEBUG -- open my $debug_fh, '<:encoding(UTF-8)', './samples/example.html' || die "Can't open UTF-8 encoded ./a: $!"; $tree->parse_file( $debug_fh );


# check if expected headers match
my @head= $tree->findvalues( '//table/thead/tr/th');
my $real_h = join (':', @head);
my $expect_h = "Datum posudbe:Datum povrata:Knjižnica:Vrsta građe:Status:Naslovni niz";
die "headers mismatch: wanted: $expect_h, got: $real_h" if $real_h ne $expect_h;

# headers ok, go parse the data
$DEBUG && say "\n\n$real_h";
my @books= $tree->findnodes( '//table/tbody/tr');

my $now = DateTime->now;



foreach my $book (@books) {
	my @td=$book->findvalues( './td');
	my ($datum_pos, $datum_pov, $knjiznica, $vrsta, $status, $naslov) = @td;
	$DEBUG && say "checking: $datum_pov\t$naslov";
	if ($datum_pov !~ m/^(\d{1,2})\.(\d{1,2})\.(\d{4})\.$/) { die "invalid date: $datum_pov"; }

	my $expire = DateTime->new( day => $1, month => $2, year => $3 );
	my $diff_days = ($expire - $now)->delta_days();

	$DEBUG && say "\tnow=" . $now->ymd() . ", istek=" . $expire->ymd() . ", diff=$diff_days";

	if ($diff_days <= $WARN_DAYS) {
		if ($diff_days <= 0) {
			say "ERROR: pred $diff_days dana (" . $expire->ymd() . ") JE ISTEKLA knjiga:\t$naslov";
		} else {
			say "WARNING: za $diff_days dana (" . $expire->ymd() . ") istjece knjiga:\t$naslov";
		}
	}
}


exit 0;
