# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

use File::Path;

BEGIN { use_ok( 'SingelCellSAM' ); }

my $object = SingelCellSAM->new ();
isa_ok ($object, 'SingelCellSAM');

if ( -d "t/data/outpath" ){
	rmtree( "t/data/outpath");
}

open ( IN , "samtools view -h t/data/ChrM_subset.bam |" );

$object->splitSAM( 't/data/barcodes.tsv', 't/data/outpath', <IN> );

close ( IN );