#!/usr/bin/perl

use strict;

use File::Spec::Functions qw(catfile);
use File::Basename qw(basename);
use FindBin qw($Bin);
use Test::More tests => 4;

# Disable DEBUG, and silence warnings
$Sevenroot::FeedParser::DEBUG = $Sevenroot::FeedParser::DEBUG = 0;
my $datafile = catfile $Bin, "testdata", basename($0, ".t");

use_ok("Sevenroot::FeedParser", qw(parse parsefile));
ok(-f $datafile, "datafile exists");

my $feed = parsefile($datafile);
ok($feed, "Parsed datafile correctly");

is($feed->{'meta'}->{'namespaces'}->{'dc'},
   "http://purl.org/dc/elements/1.1/", 
   "Extract dc namespace");
