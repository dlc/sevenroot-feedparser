package Sevenroot::FeedParser::RSS2;

use strict;
use vars qw($VERSION);
use Sevenroot::FeedParser::Utils;

$VERSION = "0.3a";

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
    $feed{'entries'} = $class->extract_items(\$data);
    $feed{'channel'} = $class->extract_channel(\$data);

    return \%feed;
}

# ----------------------------------------------------------------------
# extract_channel(\$data)
#
# Extract the <channel> element from an RSS feed.
# ----------------------------------------------------------------------
sub extract_channel {
    my $class = shift;
    my $data = shift;
    my %channel;
    my ($channel) = $$data =~ m!<channel>\s*(.+?)\s*(?:<item|$)!s;

    # Extract known fields, based on http://cyber.law.harvard.edu/rss/rss.html
    for my $field (qw(
        title link description
        language copyright webMaster managingEditor
        pubDate lastBuildDate category generator docs
        ttl image rating textInput skipHours skipDays
    )) {
        if ($channel =~ s!<$field>(.+?)</$field>!!s) {
            ($channel{ lc $field }) = unescape(trim("$1"));
        }
        else {
            $channel{ lc $field } = "";
        }
    }

    $channel{'categories'} = [];
    if ($channel =~ m!</category>!) {
        while ($channel =~ s!<(category.*?</category)>!!s) {
            my $cat = "$1";
            my %cat = ();
            ($cat{'text'}) = unescape(trim($cat =~ m!>(.+?)<!));
            ($cat{'domain'}) = unescape(trim($cat =~ m!domain=.(.+)?.>!));

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
                $i->{ $field } = unescape(trim("$1"));
            }
        }
    }

    if (my $text_input = delete $channel{'textinput'}) {
        my $i = $channel{'textinput'} = {};
        for my $field (qw(title description name link)) {
            if ($text_input =~ m!<$field>(.+?)</$field>!s) {
                $i->{ $field } = unescape(trim("$1"));
            }
        }
    }

    for my $person (qw(webmaster managingeditor)) {
        if (my $str = delete $channel{$person}) {
            $channel{ lc $person } = extract_email_address($str);
        }
    }

    for my $date_field (qw(pubdate lastbuilddate)) {
        if (my $date_str = delete $channel{$date_field}) {
            $channel{ lc $date_field } = normalize_date($date_str);
        }
    }

    # Other well-known, common fields
    for my $field (qw(dc:creator)) {
        if ($channel =~ s!<$field>(.+?)</$field>!!s) {
            ($channel{ lc $field }) = unescape(trim("$1"));
        }
    }

    return \%channel;
}

# ----------------------------------------------------------------------
# extract_items(\$data)
#
# Extract the <item> elements from an RSS feed.
# ----------------------------------------------------------------------
sub extract_items {
    my $class = shift;
    my $data = shift;
    my @entries = ();

    while ($$data =~ s!<item>(.+?)</item>!!s) {
        my $raw_entry = "$1";
        my %entry;

        # Simple scalar fields
        for my $field (qw(title link description comments pubDate author)) {
            if ($raw_entry =~ s!<$field>(.+?)</$field>!!s) {
                ($entry{ lc $field }) = unescape(trim("$1"));
            }
            else {
                $entry{ lc $field } = "";
            }
        }

        # Category is potentially multivalued
        $entry{'categories'} = [];
        if ($raw_entry =~ m!</category>!) {
            while ($raw_entry =~ s!<(category.*?</category)>!!s) {
                my $cat = "$1";
                my %cat = ();
                ($cat{'text'}) = unescape(trim($cat =~ m!>(.+?)<!));
                ($cat{'domain'}) = unescape(trim($cat =~ m!domain=.(.+)?.>!));

                push @{ $entry{'categories'} }, \%cat;
            }
        }

        # source is a single tag with attributes
        $entry{'source'} = {};
        if ($raw_entry =~ m!</source>!) {
            my ($source) = $raw_entry =~ s!<(source.+?</source)>!!;
            ($entry{'source'}->{'title'}) = unescape(trim($source =~ m!>(.+)<!));
            ($entry{'source'}->{'url'}) = unescape(trim($source =~ m! url=.(.+).>!));
        }

        # enclosure is a single tag with attributes
        if ($raw_entry =~ s!(<enclosure.+?/>)!!s) {
            $entry{'enclosure'} = extract_attributes("$1", qw(url length type));
        }
        else {
            $entry{'enclosure'} = {};
        }

        # guid is a single tag, potentially with a isPermalink attribute
        if ($raw_entry =~ s!(<guid.+?</guid>)!!s) {
            my $raw_guid = "$1";
            ($entry{'guid'}) = $raw_guid =~ m!>(.+)<!;

        }
        else {
            $entry{'guid'} = "";
        }

        # Clean up author 
        if (my $str = delete $entry{'author'}) {
            $entry{'author'} = extract_email_address($str);
        }

        # Parse date into epoch
        if (my $date_str = delete $entry{'pubdate'}) {
            $entry{'pubdate'} = normalize_date($date_str);
        }

        # Other common fields
        for my $field (qw(wfw:commentRss slash:comments
                          dc:creator feedburner:origLink)) {
            if ($raw_entry =~ s!<$field>(.+?)</$field>!!s) {
                ($entry{ lc $field }) = unescape(trim("$1"));
            }
        }

        push @entries, \%entry;
    }

    return \@entries;
}

1;
