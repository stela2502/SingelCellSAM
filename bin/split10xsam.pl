#!/usr/bin/perl

use strict;
use warnings;
use SingelCellSAM;

my $barcodeF = $ARGV[0];
$barcodeF ||= '';
unless ( -f $barcodeF ){
	die ("I neeed the barcodes file as first command line argument")
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


$analyzer->splitSAM( $barcodeF, $path, "STDIN" );

print "Finished\n";
