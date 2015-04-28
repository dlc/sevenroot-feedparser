package Sevenroot::FeedParser::Atom;

use strict;
use vars qw($VERSION);
use Sevenroot::FeedParser::Utils;

$VERSION = "0.3";

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
        push @entries, { raw => "$1" };
    }

    return \@entries;
}

sub extract_channel {
    my $class = shift;
    my $data = shift;
    my %channel;

#warn "data = '$$data'\n";

    # Extract basic fields, based on http://atomenabled.org/developers/syndication/
    for my $field (qw(
        id title updated
        icon logo rights subtitle
        generator
    )) {
        if ($$data =~ s!<$field>(.+?)</$field>!!s) {
            ($channel{ lc $field }) = unescape(trim("$1"));
        }
        elsif ($$data =~ s!<$field\s+.+?>(.+?)</$field>!!s) {
            ($channel{ lc $field }) = unescape(trim("$1"));
        }
        else {
            $channel{ lc $field } = "";
        }
    }

    # Links
    $channel{'links'} = {};
    while ($$data =~ s!<(link\s+.+?)/>!!s) {
        my $bits = extract_attributes("$1",
            qw(href rel type hreflang title length));
        $channel{'links'}->{ $bits->{'rel'} } = $bits;
    }
    if ($channel{'links'}->{'alternate'}) {
        $channel{'link'} = $channel{'links'}->{'alternate'}->{'href'};
    }

    # Categories
    $channel{'categories'} = [];
    while ($$data =~ s!<(category\s+.+?)/>!!s) {
        my $bits = extract_attributes("$1", qw(term scheme label));
        push @{ $channel{'categories'} }, $bits;
    }

    # Contributor
    $channel{'contributors'} = [];
    while ($$data =~ s!<contributor>(.+?)</contributor>!!s) {
        my $contrib = "$1";
        my %contrib;
        for my $field (qw(name uri email)) {
            if ($contrib =~ s!<$field>(.+?)</$field>!!s) {
                ($contrib{ $field }) = unescape(trim("$1"));
            }
            else {
                $contrib{ $field } = "";
            }
        }
        
        push @{ $channel{'contributors'} }, \%contrib;
    }

    # Normalize date fields
    for my $date_field (qw(updated)) {
        if (my $date_str = delete $channel{$date_field}) {
            $channel{ lc $date_field } = normalize_date($date_str);
        }
    }

    return \%channel;
}

1;
