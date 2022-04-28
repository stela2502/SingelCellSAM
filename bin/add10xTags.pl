#!/usr/bin/perl

use strict;
use warnings;
use SingelCellSAM;

#sam/bam ifile, opath, source, taget

my ( $R2, $I1, $barcodes ) = @ARGV;

my $usage =
"samtools view <bam> | add10xTags.pl <R2.fastq.gz> <I1.fastq.gz> <barcodes.tsv> > <annotated.sam>

Where bam, R2.fastq.gz and I1.fastq.gz are input files.
The R1 and possibly R3 reads should have been mapped to a genome 
and the sam entries of that genome should be piped through this tool.

The barcodes.tsv file would contain the sorted cell barcodes and read counts per barcode.
The modified bam reads are written to STDOUT.

";

unless ( -f $R2 ){
	die ( $usage )
}

unless ( -f $I1 ){
	die ( $usage )
}

if ( undef $barcodes ){
	die ( $usage )
}

my $object = SingelCellSAM->new ();

$object->annotate10xcells( \*STDIN , $R2, $I1, $barcodes );

