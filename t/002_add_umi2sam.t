# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 4;
use strict;


use File::Path;

BEGIN { use_ok( 'SingelCellSAM' ); }

my $object = SingelCellSAM->new ();
isa_ok ($object, 'SingelCellSAM');

my @testFiles =  map { 't/data/'.$_  ;}  ('first1000reads.sam', 'first1000_R2.fastq', 'first1000_I1.fastq') ;
my @outFiles =  map { 't/data/outpath/'.$_; }  ('barcodes.tsv', 'annotated.sam' ) ;


# open ( my $IN , "<$testFiles[0]" ) or die "with file '$testFiles[0]'\n$!";

# open ( my $FASTQ, "<$testFiles[1]") or die $!;

# open ( my $I1, "<$testFiles[2]") or die $!;

if ( -d "t/data/outpath" ){
	rmtree( "t/data/outpath");
}

# print STDERR "creating path t/data/outpath\n";
# mkdir ("t/data/outpath");

# open ( my $out, ">$outFiles[0]") or die $!;
# open ( my $out1, ">$outFiles[1]") or die $!;

#my $out = "STDERR";
#$object->{'out'} = $out1;

#$IN, $annotationReadFQ, $I1read, $bcFile, $cell_barcode_length

#$object->annotate10xcells( $IN, $FASTQ, $I1, $out );

#close ( $IN );
#close( $FASTQ );
#close ( $out );

# undef $object->{'out'};
# close ( $out1 );

# ok ( -f $outFiles[0], "$outFiles[0] file");
# ok ( -f $outFiles[1], "$outFiles[1] file");

# open ( my $check, "<$outFiles[0]") or die $!;
# my @res = ( map { my @arr = split(/\s/, $_); \@arr} <$check>);
# close ( $check);
#is_deeply( \@res, 
#	[["TTAGCCATCTTAGCC","3"],["ACACAATCAAGGACG","2"]],
#	"Barcodes content" );



### look into the script

print STDERR "testing the script add10xTags.pl:\n";

rmtree( "t/data/outpath");
mkdir ("t/data/outpath");



#<R2.fastq.gz> <I1.fastq.gz> <barcodes.tsv>

system ( "samtools view -h $testFiles[0] | ".
	"perl -I lib/ bin/add10xTags.pl $testFiles[1] $testFiles[2] $outFiles[0] > $outFiles[1]");


ok ( -f $outFiles[0], "$outFiles[0] file");
ok ( -f $outFiles[1], "$outFiles[1] file");

open ( my $check, "<$outFiles[0]") or die $!;
my @res = ( map { my @arr = split(/\s/, $_); \@arr} <$check>);
close ( $check);
#is_deeply( \@res, 
#	[["TTAGCCATCTTAGCC","3"],["ACACAATCAAGGACG","2"]],
#	"Barcodes content" );