# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'SingelCellSAM' ); }

my $object = SingelCellSAM->new ();
isa_ok ($object, 'SingelCellSAM');

open ( IN , "samtools view t/data/ChrM_subset.bam |" );

$object->splitSAM( 't/data/barcodes.tsv', 't/data/outpath', *IN );

close ( IN );