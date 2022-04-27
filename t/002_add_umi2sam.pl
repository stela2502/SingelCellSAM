# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 5;

use File::Path;

BEGIN { use_ok( 'SingelCellSAM' ); }

my $object = SingelCellSAM->new ();
isa_ok ($object, 'SingelCellSAM');


open ( my $IN , "<t/data/test.ordered.sam" );

open ( my $FASTQ, "<t/data/test.R2.fastq");

open ( my $I1, "<t/data/test.I1.fastq");

if ( not -d "t/data/outpath" ){
	mkdir "t/data/outpath";
}

if ( -f "t/data/outpath/barcodes.tsv"){
	unlink( "t/data/outpath/barcodes.tsv")
}

if ( -f "t/data/outpath/annotated.sam"){
	unlink( "t/data/outpath/annotated.sam")
}



open ( my $out, ">t/data/outpath/barcodes.tsv") or die $!;
open ( my $out1, ">t/data/outpath/annotated.sam") or die $!;
#my $out = "STDERR";
$object->{'out'} = $out1;


$object->annotate10xcells( $IN, $FASTQ, $I1, $out );

close ( $IN );
close( $FASTQ );
close ( $out );

ok ( -f "t/data/outpath/barcodes.tsv", "barcodes.tsv file");
ok ( -f "t/data/outpath/annotated.sam", "annotated.sam file");

open ( my $check, "<t/data/outpath/barcodes.tsv") or die $!;
my @res = ( map { my @arr = split(/\s/, $_); \@arr} <$check>);
close ( $check);
is_deeply( \@res, 
	[["TTAGCCATCTTAGCC","3"],["ACACAATCAAGGACG","2"]],
	"Barcodes content" );


