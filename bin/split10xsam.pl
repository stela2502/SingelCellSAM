#!/usr/bin/perl

use strict;
use warnings;
use SingelCellSAM;

my $barcodeF = $ARGV[0];


my $usage =
"samtools view <bam> | split10xsam.pl barcodes.tsv <outpath>

Where bam and barcodes.tsv are input files.

The barcodes.tsv file would contain the cell barcodes that should be exported.
The modified sam reads are written to STDOUT.

";


$barcodeF ||= '';
unless ( -f $barcodeF ){
	die $usage;
}
my $path = $ARGV[1];
unless ( defined $path ){
	$path = "splitSams";
}

print ("second argument \$path was '$path'");

my $analyzer = SingelCellSAM->new();

if ( -d $path ){
	die "outpath $path already exists!\n";
}

open ( my $IN, <STDIN> );

$analyzer->splitSAM( $barcodeF, $path, $IN );

close ( $IN );

print "Finished\n";
