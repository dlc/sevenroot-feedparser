#!/usr/bin/perl

use strict;

use File::Spec::Functions qw(catfile);
use File::Basename qw(basename);
use FindBin qw($Bin);
use Test::More tests => 8;

# Disable DEBUG, and silence warnings
$Sevenroot::FeedParser::DEBUG = $Sevenroot::FeedParser::DEBUG = 0;
my $datafile = catfile $Bin, "testdata", basename($0, ".t");

use_ok("Sevenroot::FeedParser", qw(parse parsefile parseurl));
ok(-f $datafile, "datafile exists");

my $feed = parsefile($datafile);
ok($feed, "Parsed datafile correctly");

is($feed->{'channel'}->{'webmaster'},
    'webmaster@example.com',
    "webmaster parses correctly");

is(scalar @{ $feed->{'entries'} },
   3, 
   "Number of entries parsed correctly");

is(scalar @{ $feed->{'entries'}->[1]->{'categories'} },
   1,
   "Parsed categories");

is($feed->{'entries'}->[1]->{'categories'}->[0]->{'text'},
   "Testing",
   "Parsed 'Testing' category correctly");

like($feed->{'entries'}->[2]->{'enclosure'}->{'url'},
     qr/\.mp3/,
     "Extract enclosure");
