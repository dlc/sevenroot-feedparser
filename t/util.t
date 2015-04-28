#!/usr/bin/perl

use strict;

use File::Spec::Functions qw(catfile);
use File::Basename qw(basename);
use FindBin qw($Bin);
use Test::More tests => 28;

use_ok("Sevenroot::FeedParser::Utils", qw(docs_link));
use_ok("Sevenroot::FeedParser::Utils", qw(extract_attributes));
use_ok("Sevenroot::FeedParser::Utils", qw(extract_email_address));
use_ok("Sevenroot::FeedParser::Utils", qw(extract_namespaces));
use_ok("Sevenroot::FeedParser::Utils", qw(extract_root_element));
use_ok("Sevenroot::FeedParser::Utils", qw(extract_xml_attrs));
use_ok("Sevenroot::FeedParser::Utils", qw(normalize_date));
use_ok("Sevenroot::FeedParser::Utils", qw(select_feed_class));
use_ok("Sevenroot::FeedParser::Utils", qw(trim));
use_ok("Sevenroot::FeedParser::Utils", qw(unescape));

is(docs_link('RSS'),
   $Sevenroot::FeedParser::Utils::RSS2_DOCS_LINK,
   "rss docs link");

is(docs_link('Atom'),
   $Sevenroot::FeedParser::Utils::ATOM_DOCS_LINK,
   "atom docs link");

is(extract_email_address('Darren Chamberlain <darren@cpan.org>'),
   'darren@cpan.org',
   'extracting email addresses');

my $root = "rss foo='bar'";
my $xml = "<$root><baz/></rss>";
is(extract_root_element(\$xml),
   $root,
   "extract root element");

my $root = "rss\nfoo='bar'";
my $xml = "<$root><baz/></rss>";
is(extract_root_element(\$xml),
   $root,
   "extract root element with newline");

is_deeply(scalar extract_attributes("<$root>", "foo"),
          { foo => "bar" },
          "extract attributes");
   
my $ns = extract_namespaces(\q(<rss
     xmlns:content='http://purl.org/rss/1.0/modules/content/'
     xmlns:taxo='http://purl.org/rss/1.0/modules/taxonomy/'
     xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#'
     xmlns:itunes='http://www.itunes.com/dtds/podcast-1.0.dtd'
     xmlns:dc='http://purl.org/dc/elements/1.1/'
     xmlns:atom='http://www.w3.org/2005/Atom'
     version='2.0'
     xml:lang='en-US'
     xmlns='http://www.example.com/'>));

is($ns->{'content'},
   'http://purl.org/rss/1.0/modules/content/',
   "Namespace test (content)");
is($ns->{'taxo'},
   'http://purl.org/rss/1.0/modules/taxonomy/',
   "Namespace test (taxo)");
is($ns->{'rdf'},
   'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
   "Namespace test (rdf)");
is($ns->{'itunes'},
   'http://www.itunes.com/dtds/podcast-1.0.dtd',
   "Namespace test (itunes)");
is($ns->{'dc'},
   'http://purl.org/dc/elements/1.1/',
   "Namespace test (dc)");
is($ns->{'atom'},
   'http://www.w3.org/2005/Atom',
   "Namespace test (atom)");
is($ns->{'_'},
   'http://www.example.com/',
   "Empty namespace test");

my $xml_attrs = extract_xml_attrs(\q(<feed
  xmlns="http://www.w3.org/2005/Atom"
  xmlns:thr="http://purl.org/syndication/thread/1.0"
  xml:lang="en-US"
  xml:base="http://www.example.com/">));
is($xml_attrs->{'lang'}, "en-US", "XML attrs (lang)");
is($xml_attrs->{'base'}, "http://www.example.com/", "XML attrs (base)");

my $epoch = normalize_date("Wed, 22 Apr 2015 11:26:18 -0400");
is($epoch, 1429716378, "Normalize date does the right thing.");

my $str = "  I like cake     ";
is(trim($str), "I like cake", "trim works");

$str = "&lt;hello&gt;";
is(unescape($str), "<hello>", "unescape works");
