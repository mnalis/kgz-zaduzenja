#!/usr/bin/perl
use warnings;
use strict;
use autodie qw(:all);

use WWW::Mechanize;

my $mech = WWW::Mechanize->new();

$mech->get( $url );
