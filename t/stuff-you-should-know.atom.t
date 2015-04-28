#!/usr/bin/perl

use strict;

use File::Spec::Functions qw(catfile);
use File::Basename qw(basename);
use FindBin qw($Bin);
use Test::More tests => 7;

# Disable DEBUG, and silence warnings
$Sevenroot::FeedParser::DEBUG = $Sevenroot::FeedParser::DEBUG = 0;
my $datafile = catfile $Bin, "testdata", basename($0, ".t");

use_ok("Sevenroot::FeedParser", qw(parse parsefile parseurl));
ok(-f $datafile, "datafile exists");

my $feed = parsefile($datafile);
ok($feed, "Parsed datafile correctly");

my $title = $feed->{'channel'}->{'title'};
is($title,
   "Stuff You Should Know: The Podcast",
   "Parsed title");

my $link = $feed->{'channel'}->{'link'};
is($link,
   "http://www.stuffyoushouldknow.com/stuffyoushouldknow-podcasts",
   "Parsed link");

my $generator = $feed->{'channel'}->{'generator'};
is($generator,
   "WordPress",
   "Parsed generator");

my $entries = $feed->{'entries'};
is(scalar @$entries,
   10,
   "Parsed correct number of entries");
