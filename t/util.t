#!/usr/bin/perl

use strict;

use File::Spec::Functions qw(catfile);
use File::Basename qw(basename);
use FindBin qw($Bin);
use Test::More tests => 9;

use_ok("Sevenroot::FeedParser::Util", qw(extract_namespaces));
use_ok("Sevenroot::FeedParser::Util", qw(extract_xml_attrs));
use_ok("Sevenroot::FeedParser::Util", qw(extract_root_element));
use_ok("Sevenroot::FeedParser::Util", qw(extract_email_address));
use_ok("Sevenroot::FeedParser::Util", qw(docs_link));

is(docs_link('RSS'),
   'http://cyber.law.harvard.edu/rss/rss.html',
   "rss docs link");

is(docs_link('Atom'),
   'http://atomenabled.org/',
   "atom docs link");

is(extract_email_address('Darren Chamberlain <darren@cpan.org>'),
   'darren@cpan.org',
   'extracting email addresses');

my $root = "rss foo='bar'";
my $xml = "<$root><baz/></rss>";
is(extract_root_element(\$xml),
   $root,
   "extract root element");
