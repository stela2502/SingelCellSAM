use ExtUtils::MakeMaker;
use strict;
use warnings;

# Call 'perldoc ExtUtils::MakeMaker' for details of how to influence
# the contents of the Makefile that is written.

my %WriteMakefileArgs = (
    NAME                => 'SingelCellSAM',
    VERSION_FROM        => 'lib/SingelCellSAM.pm',
    AUTHOR              => 'Stefan Lang (Stefan.Lang@Med.Lu.SE)',
    ABSTRACT            => 'Split and add 10x cell info from/to bam/sam files.',
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
    PREREQ_PM           => {
        'Test::Simple' => 0.44,
    },
    EXE_FILES => [ "bin/split10xsam.pl", "bin/changeReadGroup.pl" ],
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? () : ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        #resources => {
        #    homepage    => undef,
        #    repository  => {
        #        url         => undef,
        #        web         => undef,
        #        type        => undef,
        #    },
        #    bugtracker => {
        #        web         => undef,
        #    },
        #},
    })),
);


open( my $IN, "samtools --version |" ) or die "this perl library needs samtools to be installed\n$!\n";

my @info = <$IN>;
print ( "found dependency ". $info[0] );
close ($IN);

WriteMakefile(%WriteMakefileArgs);
