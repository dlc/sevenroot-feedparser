package Sevenroot::FeedParser;

use strict;
use vars qw($VERSION @EXPORT_OK $DEBUG);
use base qw(Exporter);

$VERSION = "0.01";
$DEBUG = 0 unless defined $DEBUG;
@EXPORT_OK = qw(parsefile parse);

use Data::Dumper;

sub parsefile {
    my $filename = shift;

    my $data = do {
        if (open my $fh, $filename) {
            local $/;
            <$fh>;
        }
    };

    return unless $data;

    return parse($data);
}

sub parse {
    my $data = shift;

    _debug("\$data is ", length($data), " bytes");
    _debug("head(\$data) = '", substr($data, 0, 100), "'...");

    # Strip <?xml> tag
    $data =~ s!^\s*<\?xml[^>]+\?>\s*!!m;

    return _parse_rss($data) if $data =~ /^<rss/;
    return _parse_atom($data) if $data =~ /^<feed/;

    return;
}

sub _parse_rss {
    my $data = shift;
    my %feed = (meta => {}, channel => {}, entries => []);

    _debug("Parsing data as rss: ", substr($data, 0, 30), "...");

    $feed{'meta'}->{'namespaces'} = _extract_namespaces(\$data);
    $feed{'meta'}->{'xml_attrs'} = _extract_xml_attrs(\$data);

    $feed{'channel'}->{'raw'} = _extract_channel_metadata(\$data);

    return \%feed;
}

sub _parse_atom {
    my $data = shift;
    my %feed = (meta => {}, channel => {}, entries => []);

    _debug("Parsing data as atom ", substr($data, 0, 30), "...");

    $feed{'meta'}->{'namespaces'} = _extract_namespaces(\$data);
    $feed{'meta'}->{'xml_attrs'} = _extract_xml_attrs(\$data);

    return \%feed;
}

# ----------------------------------------------------------------------
# _extract_root_element(\$data)
#
# Extracts the root element from the data.
# ----------------------------------------------------------------------
sub _extract_root_element {
    my $data = shift;
    my ($root_elem) = $$data =~ m!^<((rss|feed)[^>]+)>!;
    return $root_elem;
}

# ----------------------------------------------------------------------
# extract_namespaces(\$data)
#
# Return a hash of namespaces from the root element.  The default namespace
# comes back as _.
# ----------------------------------------------------------------------
sub _extract_namespaces {
    my $data = shift;
    my $root_elem = _extract_root_element($data);

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
# _extract_xml_attrs(\$data)
# 
# Return xml: attributes from the root element
# ----------------------------------------------------------------------
sub _extract_xml_attrs {
    my $data = shift;
    my $root_elem = _extract_root_element($data);

    my %attrs = map {
        my ($attr, $uri) = m!xml:(.+?)=(.+)!;
        $uri =~ s/["']//g;
        $attr => $uri;
    } grep /^xml:/, split /\s+/, $root_elem;

    return \%attrs;
}

# ----------------------------------------------------------------------
# _extract_channel_metadata(\$data)
#
# Extract the <channel> element from an RSS feed
# ----------------------------------------------------------------------
sub _extract_channel_metadata {
    my $data = shift;
    my %channel;
    my ($channel) = $$data =~ m!<channel>\s*(.+?)\s*<item!s;

    $channel{'raw'} = $channel;
    $channel{'bits'} = [];


    return \%channel;
}

# ----------------------------------------------------------------------
# _extract_feed_metadata(\$data)
# 
# Extract the feed-related data from an Atom feed
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Emit debugging imformation, if required
# ----------------------------------------------------------------------
sub _debug {
    if ($DEBUG) {
        my $msg = join " ", map {
            my $m = $_;
            $m =~ s/^\s*//;
            $m =~ s/\s*$//;
            $m;
        } @_;
        chomp $msg;
        warn "$msg\n";
    }
}

1;

__END__

=head1 NAME

Sevenroot::FeedParser

=head1 SYNOPSIS

    use Sevenroot::FeedParser qw(parsefile);

    my $data1 = parsefile("foo.xml");

=head1 DESCRIPTION

C<Sevenroot::FeedParser> implements a simple regexp-based RSS and
Atom parser. This is probably not a good idea, but it's a fun side
project for me.  My use case is older machines on which I cannot
install things like expat and XML::LibXML. It is similar is scope
and function to Mark Pilgrim's Universal Feed Parser
(https://github.com/kurtmckee/feedparser).

Note that this is *not* a general-purpose XML parser, and will most
likely be lossy; it will only extract known elements from RSS and
Atom feeds, but I will try to make it cover all the cases documented
in the specs.

=head1 INTERFACE

C<Sevenroot::FeedParser> provides a pair of functions, C<parsefile>
and C<parse>, which, when feed an RSS or Atom document, return a
normalized data structure. As C<parsefile> simply opens a file and
then passes the contents to C<parse>, these docs will simply refer
to C<parse>.

A call to C<parse> will return a data structure (see L</PARSED DATA
STRUCTURE>) on success, or undef on failure.  Note that there is no
explicit check that the XML is well-formed, so that by itself is not
cause for failure, but if the contents of the feed are not similar
enough to the spec, key elements won't be extractable; depending on
how malformed the data is, C<parse> might not be able to extract the
proper information.

=head1 PARSED DATA STRUCTURE

The structure returned by C<parse> looks like this:

    {
        meta => {
        },
        channel => {
            title => "",
            description => "",
            uri => "",
        },
        entries => [
            {
                title => "",
                description => "",
                uri => "",
                pubdate => ""
            },
        ]

    }

The C<meta>, C<channel>, and C<entries> elements will always be
present, and will always be a hashref, hashref, and arrayref,
respectively. Each element in the C<entries> array will be a
hashref.  C<meta> refers to attributes of the feed itself, and not
of the data, like xml properties (language) and xml namespaces.
