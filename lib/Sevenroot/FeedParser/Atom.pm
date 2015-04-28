package Sevenroot::FeedParser::Atom;

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

    $feed{'meta'}->{'type'} = 'Atom';
    $feed{'meta'}->{'docs'} = docs_link('atom');
    $feed{'meta'}->{'source'} = $source;
    $feed{'meta'}->{'namespaces'} = extract_namespaces(\$data);
    $feed{'meta'}->{'xml_attrs'} = extract_xml_attrs(\$data);
    $feed{'entries'} = $class->extract_items(\$data);
    $feed{'channel'} = $class->extract_channel(\$data);

    return \%feed;
}

sub extract_items {
    my $class = shift;
    my $data = shift;
    my @entries = ();

    while ($$data =~ s!<entry>(.+?)</entry>!!s) {
        my $entry = "$1";
        my %entry;

        # Extract basic fields, based on http://atomenabled.org/developers/syndication/
        %entry = extract_nested_tags($entry, qw(
            id title updated content summary published updated rights));

        if ($entry =~ s!<media:description>(.+?)</media:description>!!s) {
            $entry{'content'} = "$1";
        }

        $entry{'categories'} = $class->extract_categories($entry);

        # People
        $entry{'contributors'} = $class->extract_person($entry, "contributor");
        $entry{'author'} = $class->extract_person($entry, "author");

        # Fix links
        $entry{'links'} = $class->extract_links($entry);
        if ($entry{'links'}->{'alternate'}) {
            $entry{'link'} = $entry{'links'}->{'alternate'}->{'href'};
        }
        if ($entry{'links'}->{'enclosure'}) {
            $entry{'enclosure'} = {
                url => $entry{'links'}->{'enclosure'}->{'href'}
            }
        }

        # Normalize date fields
        for my $date_field (qw(published updated)) {
            if (my $date_str = delete $entry{$date_field}) {
                $entry{ lc $date_field } = normalize_date($date_str);
            }
        }

        push @entries, \%entry;
    }

    return \@entries;
}

sub extract_channel {
    my $class = shift;
    my $data = shift;
    my %channel;

    # Extract basic fields, based on http://atomenabled.org/developers/syndication/
    %channel = extract_nested_tags($$data, qw(
        id title updated icon logo rights subtitle generator));

    # Links
    $channel{'links'} = $class->extract_links($$data);
    if ($channel{'links'}->{'alternate'}) {
        $channel{'link'} = $channel{'links'}->{'alternate'}->{'href'};
    }

    # Categories
    $channel{'categories'} = $class->extract_categories($$data);

    # Contributor
    $channel{'contributors'} = $class->extract_person($$data, "contributor");

    # Normalize date fields
    for my $date_field (qw(published updated)) {
        if (my $date_str = delete $channel{$date_field}) {
            $channel{ lc $date_field } = normalize_date($date_str);
        }
    }

    return \%channel;
}

sub extract_categories {
    my $class = shift;
    my $data = shift;
    my @cat;

    while ($data =~ s!<(category\s+.+?)/>!!s) {
        push @cat, scalar extract_attributes("$1", qw(term scheme label));
    }

    return \@cat;
}

sub extract_person {
    my $class = shift;
    my $data = shift;
    my $tag = shift;
    my @people;

    while ($data =~ s!<$tag>(.+?)</$tag>!!s) {
        push @people, { extract_nested_tags("$1", qw(name uri email)) }
    }

    return \@people;
}

sub extract_links {
    my $class = shift;
    my $data = shift;
    my %links;

    while ($data =~ s!<(link\s+.+?)/>!!s) {
        my $bits = extract_attributes("$1",
            qw(href rel type hreflang title length));
        $links{ $bits->{'rel'} } = $bits;
    }

    return \%links;
}

1;
