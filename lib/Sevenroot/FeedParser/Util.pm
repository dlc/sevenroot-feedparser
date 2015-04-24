package Sevenroot::FeedParser::Util;

use strict;
use vars qw(@EXPORT);
use vars qw($RSS2_DOCS_LINK $ATOM_DOCS_LINK);
use base qw(Exporter);

@EXPORT = qw(
    docs_link
    extract_attributes
    extract_email_address
    extract_namespaces
    extract_root_element
    extract_xml_attrs
    normalize_date
    select_feed_class
    trim
    unescape
);

$RSS2_DOCS_LINK = 'http://cyber.law.harvard.edu/rss/rss.html';
$ATOM_DOCS_LINK = 'http://atomenabled.org/';

use Time::ParseDate qw(parsedate);

# ----------------------------------------------------------------------
# extract_namespaces(\$data)
#
# Return a hash of namespaces from the root element.  The default namespace
# comes back as _.
# ----------------------------------------------------------------------
sub extract_namespaces {
    my $data = shift;
    my $root_elem = extract_root_element($data);
    my $attrs = extract_attributes($root_elem);
    my %ns;

    for my $ns (keys %$attrs) {
        if ($ns =~ /^xmlns/) {
           (my $short = $ns) =~ s/^xmlns:?//;
            $short ||= '_';
            $ns{ $short } = unescape($attrs->{ $ns });
        }
    }

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
    my $attrs = extract_attributes($root_elem);
    my %xml;

    for my $att (keys %$attrs) {
        if ($att =~ s/xml://) {
            $xml{ $att } = unescape($attrs->{ "xml:$att" });
        }
    }

    return \%xml;
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
    my %attrs = ();
    my @attrs;

    if (@_) {
        @attrs = @_;
    }
    else {
        @attrs = $str =~ /([\w:]+)=/g;
    }

    @attrs{ @attrs } = ("") x @attrs;

    # Kill leading and trailing whitespace
    trim(\$str);

    # Kill xml cruft
    $str =~ s/^<//;
    $str =~ s/\/>$//;

    my $tag;
    if ($str =~ s/^([\w][\w\d:]+)//) {
        $tag = "$1";
    }

    if ($tag) {
        $str =~ s/<\/$tag>$//;
    }

    for my $attr (@attrs) {
        if ($str =~ s!$attr=(['"])(.+?)\1!!) {
            $attrs{ lc $attr } = unescape(trim("$2"));
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

    return $RSS2_DOCS_LINK if 'rss' eq $type;
    return $RSS2_DOCS_LINK if 'rss2' eq $type;
    return $ATOM_DOCS_LINK if 'atom' eq $type;

    return;
}

# ----------------------------------------------------------------------
# normalize_date($date_str)
#
# Turns $date_str into a epoch.
# ----------------------------------------------------------------------
sub normalize_date {
    my $date_str = shift;

    my $epoch = parsedate($date_str);

    return $epoch;
}

# ----------------------------------------------------------------------
# feed_version($feed_string)
#
# Given a feed (sub)string, return a class to implement it
# ----------------------------------------------------------------------
sub select_feed_class {
    my $feed_string = shift;

    if ($feed_string =~ /^<rss/) {
        require Sevenroot::FeedParser::RSS2;
        return "Sevenroot::FeedParser::RSS2";
    }

    if ($feed_string =~ /^<feed/) {
        require Sevenroot::FeedParser::Atom;
        return "Sevenroot::FeedParser::Atom";
    }

    return;
}

# ----------------------------------------------------------------------
# trim($str)
# 
# Trims leading and trailing whitespace
# ----------------------------------------------------------------------
sub trim {
    my $str = shift || return;

    if (ref $str) {
        $$str =~ s/^\s*//;
        $$str =~ s/\s*$//;
    }

    else {
        $str =~ s/^\s*//;
        $str =~ s/\s*$//;
    }

    return $str;
}

sub unescape {
    my $str = shift || return;

    if (ref $str) {
        $$str =~ s/^<!\[CDATA\[//;
        $$str =~ s/\]\]>$//;
        $$str =~ s/&lt;/</g;
        $$str =~ s/&gt;/>/g;
        $$str =~ s/&quot;/"/g;
        $$str =~ s/&apos;/'/g;
        $$str =~ s/&amp;/&/g;
    }

    else {
        $str =~ s/^<!\[CDATA\[//;
        $str =~ s/\]\]>$//;
        $str =~ s/&lt;/</g;
        $str =~ s/&gt;/>/g;
        $str =~ s/&quot;/"/g;
        $str =~ s/&apos;/'/g;
        $str =~ s/&amp;/&/g;
    }

    return $str;
}

1;
