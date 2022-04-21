#!/usr/bin/perl

use strict;
use warnings;
use SingelCellSAM;

#sam/bam ifile, opath, source, taget

my ($ifile, $path, $source, $target ) = @ARGV;
unless ( -f $ifile ){
	die ("I neeed a sam or bam file to modify")
}

unless ( defined $path ){
	warn "second option is a outpath - missing and therefore set to modBam";
	$path = "modBam";
}

print ("second argument \$path was '$path'");

my $analyzer = SingelCellSAM->new();

if ( -d $path ){
	die "outpath $path already exists!\n";
}

$analyzer->changeReadGroup( $ifile, $path, $source, $target );

print "Finished\n";