# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 3;

use File::Path;

BEGIN { use_ok( 'SingelCellSAM' ); }

my $object = SingelCellSAM->new ();
isa_ok ($object, 'SingelCellSAM');

if ( -d "t/data/outpath" ){
	rmtree( "t/data/outpath");
}

mkdir ("t/data/outpath");

open ( my $IN , "samtools view -h t/data/ChrM_subset.bam |" ) or die $!;
open (my $OUT, "| samtools view -b > t/data/outpath/annotated.bam") or die $!;

$object->changeReadGroup( $IN, $OUT, 't/data/barcodes.tsv', 0, "CB:Z", "RG:Z" );


close ( $IN );
close ( $OUT );


ok ( -f "t/data/outpath/annotated.bam", "t/data/outpath/annotated.bam file");


