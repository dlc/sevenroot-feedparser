use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Sevenroot::FeedParser',
    'VERSION_FROM' => 'lib/Sevenroot/FeedParser.pm',
    'PREREQ_PM'    => {
        'Time::ParseDate' => 0,
    },
);
