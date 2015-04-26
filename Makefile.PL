use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'      => 'Sevenroot::FeedParser',
    'VERSION'   => "0.2d",
    'PREREQ_PM' => {
        'Time::ParseDate' => 0,
    },
);
