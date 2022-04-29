#!/usr/bin/perl

use strict;
use warnings;
use SingelCellSAM;

#sam/bam ifile, opath, source, taget

my ( $barcodes,  $source, $target ) = @ARGV;

my $usage =
"samtools view <bam> | changeReadGroup.pl barcodes.tsv 'CR:Z' 'RG:Z' > <annotated.sam>

Where bam and barcodes.tsv are input files.

The barcodes.tsv file would contain the cell barcodes that should be exported.
The modified sam reads are written to STDOUT.

";

print ("second argument \$path was '$path'");

my $analyzer = SingelCellSAM->new();

if ( -d $path ){
	die $usage;
}

$analyzer->changeReadGroup( $barcodes, $source, $target );

print "Finished\n";