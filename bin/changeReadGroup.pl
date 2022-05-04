#!/usr/bin/perl

use strict;
use warnings;
use SingelCellSAM;
use File::Spec;


#sam/bam ifile, opath, source, taget

my ( $barcodes,  $source, $target ) = @ARGV;

my $usage =
"samtools view <bam,$source> | changeReadGroup.pl barcodes.tsv 'CR:Z' 'RG:Z' > <annotated.sam,$target>

Where bam and barcodes.tsv are input files.

The barcodes.tsv file would contain the cell barcodes that should be exported.
The modified sam reads are written to STDOUT.

";

print ("second argument \$target was '$target'");

my $analyzer = SingelCellSAM->new();

if ( -f $source ){
	die $usage;
}

if ( not defined $target ){
	die $usage;
}

my ($volume,$directories,$file) =File::Spec->splitpath( File::Spec->rel2abs ($target) );
my $path = File::Spec->catfile($volume,$directories);
unless ( -d $path ){
	mkdir( $path ) or die "I tried to create the path $path:\n$!";
}



$analyzer->changeReadGroup( $barcodes, $source, $target );

print "Finished\n";