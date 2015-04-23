#!/usr/bin/perl

use strict;
use warnings;

use File::Spec::Functions qw(catfile);
use File::Basename qw(basename);
use FindBin qw($Bin);
use Test::More tests => 2;

my $datafile = catfile $Bin, "testdata", basename($0, ".t");

use_ok("Sevenroot::FeedParser", qw(parse parsefile));
ok(-f $datafile, "datafile exists");
