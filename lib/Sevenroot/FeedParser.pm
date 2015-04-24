package Sevenroot::FeedParser;

use strict;
use vars qw($VERSION @EXPORT_OK $DEBUG);
use base qw(Exporter);

$VERSION = "0.01";
$DEBUG = 0 unless defined $DEBUG;
@EXPORT_OK = qw(parsefile parse parseurl);

use Sevenroot::FeedParser::Util;

# ----------------------------------------------------------------------
# parsefile($filename)
#
# Parses $filename and returns a data structure
# ----------------------------------------------------------------------
sub parsefile {
    my $filename = shift;

    my $data = do {
        if (open my $fh, $filename) {
            local $/;
            <$fh>;
        }
    };

    return unless $data;

    return parse($data, $filename);
}

# ----------------------------------------------------------------------
# parseurl($url)
#
# Fetches $url, parses it, and returns a data structure
# ----------------------------------------------------------------------
sub parseurl {
    my $url = shift;

    require Sevenroot::HTTPClient;
    return parse(
        scalar Sevenroot::HTTPClient::get($url),
        $url);
}

# ----------------------------------------------------------------------
# parse($data)
#
# Parses $data and returns a data structure
# ----------------------------------------------------------------------
sub parse {
    my $data = shift;
    my $source = shift || '<>';

    _debug("\$data is ", length($data), " bytes");
    _debug("head(\$data) = '", substr($data, 0, 100), "'...");

    # Strip all XML directives
    $data =~ s!<\?.+?\?>!!g;

    # Strip leading whitespace
    trim(\$data);

    if (my $class = select_feed_class(substr($data, 0, 1024))) {
        _debug("Using $class to parse $source");
        return $class->parse($data, $source);
    }

    return;
}

# ----------------------------------------------------------------------
# Emit debugging imformation, if required
# ----------------------------------------------------------------------
sub _debug {
    if ($DEBUG) {
        my $msg = join " ", map {
            my $m = $_;
            trim($m);
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
