package Sevenroot::FeedParser::Atom;

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

    $feed{'meta'}->{'type'} = 'Atom';
    $feed{'meta'}->{'docs'} = docs_link('atom');
    $feed{'meta'}->{'source'} = $source;
    $feed{'meta'}->{'namespaces'} = extract_namespaces(\$data);
    $feed{'meta'}->{'xml_attrs'} = extract_xml_attrs(\$data);

    return \%feed;
}

1;
