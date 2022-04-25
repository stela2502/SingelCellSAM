# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

use File::Path;

BEGIN { use_ok( 'SingelCellSAM' ); }

my $object = SingelCellSAM->new ();
isa_ok ($object, 'SingelCellSAM');


open ( my $IN , "<t/data/test.ordered.sam" );

open ( my $FASTQ, "<t/data/test.fastq");

$object->annotate10xcells( $IN, $FASTQ );

close ( IN );
close( FASTQ );