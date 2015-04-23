package Sevenroot::FeedParser;

use strict;
use vars qw($VERSION @EXPORT_OK $DEBUG);
use base qw(Exporter);

$VERSION = "0.01";
$DEBUG = 1 unless defined $DEBUG;
@EXPORT_OK = qw(parsefile parse);

sub parsefile {
    my $filename = shift;

    my $data = do {
        if (open my $fh, $filename) {
            local $/;
            <$fh>;
        }
    };

    return unless $data;

    if ($DEBUG) {
        warn "\$data is ", length($data), " bytes\n";
        warn "head(\$data) = '", substr($data, 0, 100), "'...\n";
    }

    return parse($data);
}

sub parse {
    my $data = shift;

    # Strip <?xml> tag
    $data =~ s!^\s*<\?xml[^>]+\?>\s*!!m;

    return _parse_rss($data) if $data =~ /^<rss/;
    return _parse_atom($data) if $data =~ /^<atom/;

    return;
}

sub _parse_rss {
    my $data = shift;
    warn "Parsing data as rss: ", substr($data, 0, 30), "...\n"
        if $DEBUG;
}

sub _parse_atom {
    my $data = shift;
    warn "Parsing data as atom ", substr($data, 0, 30), "...\n"
        if $DEBUG;
}

1;

__END__

=head1 NAME

Sevenroot::FeedParser

=head1 SYNOPSIS

    use Sevenroot::FeedParser qw(parsefile);

    my $data1 = parsefile("foo.xml");
