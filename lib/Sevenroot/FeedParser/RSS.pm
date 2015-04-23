package Sevenroot::FeedParser::RSS;

use strict;
use Sevenroot::FeedParser::Util;

# ----------------------------------------------------------------------
# parse(\$data, $source)
#
# Main entry point; currently returns a data structure.
# ----------------------------------------------------------------------
sub parse {
    my $class = shift;
    my $data = shift;
    my $source = shift;

    my %feed = (meta => {}, channel => undef, entries => undef);

    $feed{'meta'}->{'type'} = 'RSS';
    $feed{'meta'}->{'docs'} = docs_link('rss');
    $feed{'meta'}->{'source'} = $source;
    $feed{'meta'}->{'namespaces'} = extract_namespaces(\$data);
    $feed{'meta'}->{'xml_attrs'} = extract_xml_attrs(\$data);
    $feed{'channel'} = $class->extract_channel(\$data);
    $feed{'entries'} = $class->extract_items(\$data);

    return \%feed;
}

# ----------------------------------------------------------------------
# extract_channel(\$data)
#
# Extract the <channel> element from an RSS feed
# ----------------------------------------------------------------------
sub extract_channel {
    my $class = shift;
    my $data = shift;
    my %channel;
    my ($channel) = $$data =~ m!<channel>\s*(.+?)\s*<item!s;

    # Extract known fields, based on http://cyber.law.harvard.edu/rss/rss.html
    for my $field (qw(
        title link description
        language copyright webMaster managingEditor
        pubDate lastBuildDate category generator docs
        ttl image rating textInput skipHours skipDays
    )) {
        if ($channel =~ s!<$field>(.+?)</$field>!!s) {
            ($channel{ $field }) = "$1";
        }
    }

    $channel{'categories'} = [];
    if ($channel =~ m!</category>!) {
        while ($channel =~ s!<(category.*?</category)>!!s) {
            my $cat = "$1";
            my %cat = ();
            ($cat{'text'}) = $cat =~ m!>(.+?)<!;
            ($cat{'domain'}) = $cat =~ m!domain=.(.+)?.>!;

            push @{ $channel{'categories'} }, \%cat;
        }
    }

    if ($channel =~ s!(<cloud.+?/>)!!s) {
        $channel{'cloud'} = extract_attributes("$1",
            qw(domain port path registerProcedure protocol));
    }
    else {
        $channel{'cloud'} = {};
    }

    # Cleanup known fields
    if (my $image = delete $channel{'image'}) {
        my $i = $channel{'image'} = {};
        for my $field (qw(title url link)) {
            if ($image =~ m!<$field>(.+?)</$field>!) {
                $i->{ $field } = "$1";
            }
        }
    }

    if (my $image = delete $channel{'textInput'}) {
        my $i = $channel{'textinput'} = {};
        for my $field (qw(title desciption name link)) {
            if ($image =~ m!<$field>(.+?)</$field>!) {
                $i->{ $field } = "$1";
            }
        }
    }

    for my $person (qw(webMaster managingEditor)) {
        if (my $str = delete $channel{$person}) {
            $channel{ lc $person } = extract_email_address($str);
        }
    }

    return \%channel;
}

# ----------------------------------------------------------------------
# extract_items(\$data)
#
# Extract the <item> elements from an RSS feed
# ----------------------------------------------------------------------
sub extract_items {
    my $class = shift;
    my $data = shift;
    my @entries = ();

    my (@raw_entries) = $$data =~ m!<item>(.+?)</item>!gs;

    for my $raw_entry (@raw_entries) {
        my %entry;

        # Simple scalar fields
        for my $field (qw(title link description comments guid pubDate author)) {
            if ($raw_entry =~ s!<$field>(.+?)</$field>!!s) {
                ($entry{ $field }) = "$1";
                $entry{ $field } =~ s/^\s*//;
                $entry{ $field } =~ s/\s*$//;
            }
            else {
                $entry{ $field } = "";
            }
        }

        # Category is potentially multivalued
        $entry{'categories'} = [];
        if ($raw_entry =~ m!</category>!) {
            while ($raw_entry =~ s!<(category.*?</category)>!!s) {
                my $cat = "$1";
                my %cat = ();
                ($cat{'text'}) = $cat =~ m!>(.+?)<!;
                ($cat{'domain'}) = $cat =~ m!domain=.(.+)?.>!;

                push @{ $entry{'categories'} }, \%cat;
            }
        }

        # source is a single tag with attributes
        $entry{'source'} = {};
        if ($raw_entry =~ m!</source>!) {
            my ($source) = $raw_entry =~ s!<(source.+?</source)>!!;
            ($entry{'source'}->{'title'}) = $source =~ m!>(.+)<!;
            ($entry{'source'}->{'url'}) = $source =~ m! url=.(.+).>!;
        }

        # enclosure is a single tag with attributes
        if ($raw_entry =~ s!(<enclosure.+?/>)!!s) {
            $entry{'enclosure'} = extract_attributes("$1", qw(url length type));
        }
        else {
            $entry{'enclosure'} = {};
        }

        # Clean up author 
        if (my $str = delete $entry{'author'}) {
            $entry{'author'} = extract_email_address($str);
        }

        push @entries, \%entry;
    }

    return \@entries;
}

1;
