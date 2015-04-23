package Sevenroot::FeedParser::Util;

use strict;
use vars qw(@EXPORT);
use base qw(Exporter);

@EXPORT = qw(
    extract_namespaces
    extract_xml_attrs
    extract_root_element
    extract_email_address
);

# ----------------------------------------------------------------------
# extract_namespaces(\$data)
#
# Return a hash of namespaces from the root element.  The default namespace
# comes back as _.
# ----------------------------------------------------------------------
sub extract_namespaces {
    my $data = shift;
    my $root_elem = extract_root_element($data);

    my %ns = map {
        my ($ns, $uri) = m!xmlns(:.+?)?=(.+)!;
        $uri =~ s/["']//g;
        $ns =~ s/^://;
        $ns ||= '_';
        $ns => $uri;
    } grep /^xmlns/, split /\s+/, $root_elem;

    return \%ns;
}


# ----------------------------------------------------------------------
# extract_xml_attrs(\$data)
# 
# Return xml: attributes from the root element
# ----------------------------------------------------------------------
sub extract_xml_attrs {
    my $data = shift;
    my $root_elem = extract_root_element($data);

    my %attrs = map {
        my ($attr, $uri) = m!xml:(.+?)=(.+)!;
        $uri =~ s/["']//g;
        $attr => $uri;
    } grep /^xml:/, split /\s+/, $root_elem;

    return \%attrs;
}

# ----------------------------------------------------------------------
# extract_root_element(\$data)
#
# Extracts the root element from the data.
# ----------------------------------------------------------------------
sub extract_root_element {
    my $data = shift;
    my ($root_elem) = $$data =~ m!^<((rss|feed)[^>]+)>!;
    return $root_elem;
}

# ----------------------------------------------------------------------
# extract_email_address
#
# Extract the actual address from a string
# TODO Replace this with a real email parser
# ----------------------------------------------------------------------
sub extract_email_address {
    my $str = shift;
    my $em = "";

   ($em) = $str =~ /(\S+@\S+)/;
    $em =~ s/^<//;
    $em =~ s/^>//;

    return $em;
}


1;
