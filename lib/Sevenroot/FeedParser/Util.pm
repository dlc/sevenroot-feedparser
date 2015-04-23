package Sevenroot::FeedParser::Util;

use strict;
use vars qw(@EXPORT);
use vars qw($RSS_DOCS_LINK $ATOM_DOCS_LINK);
use base qw(Exporter);

@EXPORT = qw(
    extract_attributes
    extract_namespaces
    extract_xml_attrs
    extract_root_element
    extract_email_address
    docs_link
);

$RSS_DOCS_LINK = 'http://cyber.law.harvard.edu/rss/rss.html';
$ATOM_DOCS_LINK = 'http://atomenabled.org/';

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
        $ns ||= '_';
        $ns =~ s/^://;
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
    $em =~ s/>$//;

    return $em;
}

# ----------------------------------------------------------------------
# extract_attributes($str, @wanted_attrs)
#
# Extracts @wanted_attrs from $str.  If an attribute is not present in
# $str, it is set to "" in the returned hash.
# ----------------------------------------------------------------------
sub extract_attributes {
    my $str = shift;
    my @attrs = @_;
    my %attrs = ();
    @attrs{ @attrs } = ("") x @attrs;

    # Kill leading and trailing whitespace
    $str =~ s/^\s*//;
    $str =~ s/\s*$//;

    # Kill xml cruft
    $str =~ s/^<//;
    $str =~ s/\/>$//;

    # Tag name into _
    my $tag;
    if ($str =~ s/^([\w][\w\d:]+)//) {
        $tag = "$1";
    }

    if ($tag) {
        $str =~ s/<\/$tag>$//;
    }

    for my $attr (@attrs) {
        if ($str =~ s!$attr=(['"])(.+?)\1!!) {
            $attrs{ $attr } = "$2";
            $attrs{ $attr } =~ s/^\s*//;
            $attrs{ $attr } =~ s/\s*$//;
        }
    }

    return \%attrs;
}

# ----------------------------------------------------------------------
# docs_link($feed_type)
# 
# Return a link to the docs for $feed_type.
# ----------------------------------------------------------------------
sub docs_link {
    my $type = lc shift;

    return $RSS_DOCS_LINK if 'rss' eq $type;
    return $ATOM_DOCS_LINK if 'atom' eq $type;

    return;
}

1;
