#!/usr/bin/perl

use strict;
use warnings;
use SingelCellSAM;
use File::Spec;


#sam/bam ifile, opath, source, taget

my ( $barcodes, $minReads, $source, $target ) = @ARGV;

my $usage =
"samtools view <bam> | changeReadGroup.pl barcodes.tsv <minreads> 'CR:Z' 'RG:Z' > <annotated.sam>

Where bam and barcodes.tsv are input files.

The barcodes.tsv file would contain the cell barcodes that should be exported.
The modified sam reads are written to STDOUT.

";


my $analyzer = SingelCellSAM->new();



$analyzer->changeReadGroup( $barcodes, $minReads, $source, $target );

print STDERR "Finished\n";