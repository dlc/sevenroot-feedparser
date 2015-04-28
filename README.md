NAME
    Sevenroot::FeedParser

SYNOPSIS
        use Sevenroot::FeedParser qw(parsefile);

        my $data1 = parsefile("foo.xml");

DESCRIPTION
    "Sevenroot::FeedParser" implements a simple regexp-based RSS and Atom
    parser. This is probably not a good idea, but it's a fun side project
    for me. My use case is older machines on which I cannot install things
    like expat and XML::LibXML. It is similar is scope and function to Mark
    Pilgrim's Universal Feed Parser
    (https://github.com/kurtmckee/feedparser).

    Note that this is *not* a general-purpose XML parser, and will most
    likely be lossy; it will only extract known elements from RSS and Atom
    feeds, but I will try to make it cover all the cases documented in the
    specs.

INTERFACE
    "Sevenroot::FeedParser" provides a pair of functions, "parsefile" and
    "parse", which, when feed an RSS or Atom document, return a normalized
    data structure. As "parsefile" simply opens a file and then passes the
    contents to "parse", these docs will simply refer to "parse".

    A call to "parse" will return a data structure (see "PARSED DATA
    STRUCTURE") on success, or undef on failure. Note that there is no
    explicit check that the XML is well-formed, so that by itself is not
    cause for failure, but if the contents of the feed are not similar
    enough to the spec, key elements won't be extractable; depending on how
    malformed the data is, "parse" might not be able to extract the proper
    information.

PARSED DATA STRUCTURE
    The structure returned by "parse" looks like this:

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

    The "meta", "channel", and "entries" elements will always be present,
    and will always be a hashref, hashref, and arrayref, respectively. Each
    element in the "entries" array will be a hashref. "meta" refers to
    attributes of the feed itself, and not of the data, like xml properties
    (language) and xml namespaces.

VERSION
    This document describes "Sevenroot::FeedParser" version 0.2d.

