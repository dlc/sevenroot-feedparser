use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'      => 'Sevenroot::FeedParser',
    'VERSION'   => "0.3a",
    'PREREQ_PM' => {
        'Time::ParseDate' => 0,
    },
    dist => {
        PREOP => 'perldoc -t lib/Sevenroot/FeedParser.pm > README',
    },
);
