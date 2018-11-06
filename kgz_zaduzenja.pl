#!/usr/bin/perl
use warnings;
use strict;
use autodie qw(:all);
use utf8;

use HTTP::Cookies;
use WWW::Mechanize;
use DateTime;

my $WARN_DAYS = 5;
my $DEBUG = $ENV{DEBUG} || 0;

binmode STDOUT, ":encoding(UTF-8)";
binmode STDERR, ":encoding(UTF-8)";


my $cookie_jar	= HTTP::Cookies->new;

sub add_cookie ($$) {
	my ($key, $value) = @_;
#    	$cookie_jar->set_cookie( $version, $key, $val, $path, $domain, $port, $path_spec, $secure, $maxage, $discard, \%rest )
#       The set_cookie() method updates the state of the $cookie_jar. The $key, $val, $domain, $port and $path arguments are strings. The $path_spec, $secure, $discard arguments are boolean values. 
#	The $maxage value is a number indicating number of seconds that this cookie will live. A value <= 0 will delete this cookie. %rest defines various other attributes like "Comment" and "CommentURL".

	$cookie_jar->set_cookie (3, $key, $value, '/',  'katalog.kgz.hr', undef, 1, 0, undef, 1);
}



my $iskaznica = shift @ARGV;
my $pin = shift @ARGV;
die "Usage: $0 <broj_iskaznice> <PIN>" if !defined $iskaznica or !defined $pin;

my $mech	= WWW::Mechanize->new( cookie_jar => $cookie_jar );

add_cookie ('ASP.NET_SessionId', 'qukhyk0cma0rovbciwzyyyf0');	# FIXME hardcoded? pass in @ARGV, or try autologin with $iskaznica / $pin ?
#add_cookie ('patronid', $iskaznica);
#add_cookie ('pin', $pin);

$DEBUG > 1 && print "Cookie Jar:\n", $mech->cookie_jar->as_string, "\n";


my $url = "https://katalog.kgz.hr/pages/mojaStranica.aspx";
#FIXME reenable -- $mech->post($url, [ 'action' => 'getIspis', 'action2' => 'getZaduzenja']);

#$mech->submit_form(
#		form_id	=> 'form1',
#		fields	=> { txtBrojIskaznice  => $iskaznica, txtPin => $pin },
##            button    => 'btnLogin'
#        );

$DEBUG > 2 && print $mech->content();


use HTML::TreeBuilder::XPath;
my $tree= HTML::TreeBuilder::XPath->new;
#$tree->parse_content( $mech->content() );
# FIXME DEBUG - DELME
open my $debug_fh, '<:encoding(UTF-8)', './samples/example.html' || die "Can't open UTF-8 encoded ./a: $!"; $tree->parse_file( $debug_fh );


# check if expected headers match
my @head= $tree->findvalues( '//table/thead/tr/th');
my $real_h = join (':', @head);
my $expect_h = "Datum posudbe:Datum povrata:Knjižnica:Vrsta građe:Status:Naslovni niz";
die "headers mismatch: wanted: $expect_h, got: $real_h" if $real_h ne $expect_h;

# headers ok, go parse the data
$DEBUG && print "\n\n$real_h\n";
my @books= $tree->findnodes( '//table/tbody/tr');

my $now = DateTime->now;



foreach my $book (@books) {
	my @td=$book->findvalues( './td');
	my ($datum_pos, $datum_pov, $knjiznica, $vrsta, $status, $naslov) = @td;
	$DEBUG && print "checking: $datum_pov\t$naslov\n";
	if ($datum_pov !~ m/^(\d{1,2})\.(\d{1,2})\.(\d{4})\.$/) { die "invalid date: $datum_pov"; }

	my $expire = DateTime->new( day => $1, month => $2, year => $3 );
	my $diff_days = ($expire - $now)->delta_days();

	$DEBUG && print "\tnow=" . $now->ymd() . ", istek=" . $expire->ymd() . ", diff=$diff_days\n";

	if ($diff_days <= $WARN_DAYS) {
		if ($diff_days <= 0) {
			print "ERROR: pred $diff_days dana (" . $expire->ymd() . ") JE ISTEKLA knjiga:\t$naslov\n";
		} else {
			print "WARNING: za $diff_days dana (" . $expire->ymd() . ") istjece knjiga:\t$naslov\n";
		}
	}
}


exit 0;
