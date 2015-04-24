#!/usr/bin/perl

use strict;

use File::Spec::Functions qw(catfile);
use File::Basename qw(basename);
use FindBin qw($Bin);
use Test::More tests => 9;

# Disable DEBUG, and silence warnings
$Sevenroot::FeedParser::DEBUG = $Sevenroot::FeedParser::DEBUG = 0;
my $datafile = catfile $Bin, "testdata", basename($0, ".t");

use_ok("Sevenroot::FeedParser", qw(parse parsefile parseurl));
ok(-f $datafile, "datafile exists");

my $feed = parsefile($datafile);
ok($feed, "Parsed datafile correctly");

is($feed->{'channel'}->{'title'},
   "APOD",
   "APOD channel title test");

is($feed->{'channel'}->{'language'},
   "en-us",
   "APOD channel language test");

is($feed->{'channel'}->{'image'}->{'link'},
   "http://antwrp.gsfc.nasa.gov/",
   "APOD channel image link test");

SKIP: {
    skip "https://github.com/dlc/sevenroot-feedparser/issues/9" => 1;
    is($feed->{'channel'}->{'textinput'}->{'name'},
        "query",
        "APOD channel text input test");
}

is(scalar @{ $feed->{'entries'} },
   7,
   "APOD entry count test");

like($feed->{'entries'}->[0]->{'description'},
     qr/Lapping at rocks/,
     "APOD entry description test");
