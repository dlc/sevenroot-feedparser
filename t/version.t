#!/usr/bin/perl

use strict;

use File::Spec::Functions qw(catfile updir);
use File::Basename qw(basename);
use File::Find qw(find);
use FindBin qw($Bin);
use Test::More;

# Extract canonical version number from Makefile.PL
my $canon_ver = undef;
if (open my $fh, catfile $Bin, updir, "Makefile.PL") {
    while (defined(my $line = <$fh>)) {
        if ($line =~ /(['"])VERSION\1   => (['"])([^'"]+)\2/) {
            $canon_ver = "$3";
            last;
        }
    }
}

# Find all .pm and .pod files
my %found;
find({
    wanted => sub {
        $found{ $_ } = undef if /\.p(od|m)$/
    },
    no_chdir => 1
}, catfile $Bin, updir, "lib");

for my $file (keys %found) {
    if (open my $fh, $file) {
        while (defined(my $line = <$fh>)) {
            if ($line =~ /^\$VERSION\s*=\s*(['"])([^'"]+)\1/) {
                $found{ $file } = "$2";
                last;
            }
            elsif ($line =~ /
                This\s+document\s+describes\s+
                C<Sevenroot::FeedParser>\s+
                version\s+(.+)\.
                /x)
            {
                $found{ $file } = "$1";
                last;
            }
        }
    }
}

plan tests => scalar keys %found;
for my $file (keys %found) {
    is($found{ $file }, $canon_ver, "Version number for $file matches $canon_ver");
}
