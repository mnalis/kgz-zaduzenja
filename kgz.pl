#!/usr/bin/perl
use warnings;
use strict;
use autodie qw(:all);

use HTTP::Cookies;
use WWW::Mechanize;

my $cookie_jar	= HTTP::Cookies->new;

sub add_cookie ($$) {
	my ($key, $value) = @_;
#    $cookie_jar->set_cookie( $version, $key, $val, $path, $domain, $port, $path_spec, $secure, $maxage, $discard, \%rest )
#        The set_cookie() method updates the state of the $cookie_jar. The $key, $val, $domain, $port and $path arguments are strings. 
# 		The $path_spec, $secure, $discard arguments are boolean values. The $maxage value is a number indicating number of seconds that this cookie will live. A value <= 0 will delete this cookie. 
# 		%rest defines various other attributes like "Comment" and "CommentURL".

# Set-Cookie3: ASP.NET_SessionId=qukhyk0cma0rovbciwzyyyf0; path="/"; domain=katalog.kgz.hr; path_spec; discard; HttpOnly; version=0

	$cookie_jar->set_cookie (3, $key, $value, '/',  'katalog.kgz.hr', undef, 1, 0, undef, 1);

}


my $iskaznica = shift @ARGV;
my $pin = shift @ARGV;

die "Usage: $0 <broj_iskaznice> <PIN>" if !defined $iskaznica or !defined $pin;

my $mech	= WWW::Mechanize->new( cookie_jar => $cookie_jar );

#$cookie_jar->load("cookies.txt");
add_cookie ('ASP.NET_SessionId', 'qukhyk0cma0rovbciwzyyyf0');
#add_cookie ('patronid', $iskaznica);
#add_cookie ('pin', $pin);

print "Set Cookie Jar?\n", $mech->cookie_jar->as_string, "\n";


my $url = "https://katalog.kgz.hr/pages/mojaStranica.aspx";
#$mech->get( $url );
$mech->post($url, [ 'action' => 'getIspis', 'action2' => 'getZaduzenja']);


#print $mech->content();

#$mech->submit_form(
#		form_id	=> 'form1',
#		fields	=> { txtBrojIskaznice  => $iskaznica, txtPin => $pin },
##            button    => 'btnLogin'
#        );

print $mech->content();


use HTML::TreeBuilder::XPath;
my $tree= HTML::TreeBuilder::XPath->new;
$tree->parse_content( $mech->content() );


my @head= $tree->findvalues( '//table/thead/tr/th');
my @data= $tree->findvalues( '//table/tbody/tr/td');
use Data::Dumper;
print "\n\np=" . Dumper($head[0]) . Dumper(\@data) . "\n";

#my $link_texts= $p->findvalue( './a'); # the texts of all a elements in $p

#my $nb=$tree->findvalue( '/html/body//p[@class="section_title"]/span[@class="nb"]');
#my $id=$tree->findvalue( '/html/body//p[@class="section_title"]/@id');

#my $p= $html->findnodes( '//p[@id="toto"]')->[0];
#my $link_texts= $p->findvalue( './a'); # the texts of all a elements in $p

