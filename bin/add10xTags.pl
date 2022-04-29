#!/usr/bin/perl

use strict;
use warnings;
use SingelCellSAM;
use File::Spec;

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

if ( not defined $barcodes ){
	die ( $usage )
}

my $object = SingelCellSAM->new ();

my ( $r2, $i1, $bar);

if ( $R2 =~ m/gz$/ ){
	open ( $r2, "zcat $R2 |") or die $!;

}else {
	open ( $r2, "<$R2") or die $!;

}

if ( $I1 =~ m/gz$/ ){
	open ( $i1, "zcat $I1 |") or die $!;

}else {
	open ( $i1, "<$I1") or die $!;

}

my ($volume,$directories,$file) =File::Spec->splitpath( File::Spec->rel2abs ($barcodes) );
my $path = File::Spec->catfile($volume,$directories);
unless ( -d $path ){
	mkdir( $path ) or die "I tried to create the path $path:\n$!";
}

open ( $bar, ">$barcodes") or die $!;


$object->annotate10xcells( $r2, $i1, $bar );


close ( $r2 );
close ( $i1 );
close ( $bar );