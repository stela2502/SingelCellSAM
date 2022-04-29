# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 602;

use File::Path;

BEGIN { use_ok( 'SingelCellSAM' ); }

my $object = SingelCellSAM->new ();
isa_ok ($object, 'SingelCellSAM');

if ( -d "t/data/outpath" ){
	rmtree( "t/data/outpath");
}

open (my  $IN , "samtools view -h t/data/ChrM_subset.bam |" );


$object->splitSAM( 't/data/barcodes.tsv', 't/data/outpath', $IN );

close ( $IN );


open ( my $bcs, "<t/data/barcodes.tsv");
my @files = ( map { chomp; 't/data/outpath/'. $_ .".bam" } <$bcs> );
close ( $bcs );

foreach my $file ( @files ) {
	chomp;
	print "test for file $file\n";
	ok( -f $file, "outfile $_" );
}


### and now test the script....

rmtree( "t/data/outpath");

system ( "samtools view -h t/data/ChrM_subset.bam | perl -I lib/ bin/split10xsam.pl t/data/barcodes.tsv t/data/outpath");

foreach my $file ( @files ) {
	chomp;
	print "test for file $file\n";
	ok( -f $file, "outfile $_" );
}
