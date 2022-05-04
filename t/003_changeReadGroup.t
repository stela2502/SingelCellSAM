# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

use File::Path;

BEGIN { use_ok( 'SingelCellSAM' ); }

# my $object = SingelCellSAM->new ();
# isa_ok ($object, 'SingelCellSAM');

# if ( -d "t/data/outpath" ){
# 	rmtree( "t/data/outpath");
# }

# mkdir ("t/data/outpath");

# open ( my $IN , "samtools view -h t/data/ChrM_subset.bam |" ) or die $!;
# open (my $OUT, "| samtools view -b > t/data/outpath/annotated.bam") or die $!;

# $object->changeReadGroup( 't/data/barcodes.tsv', 0, "CB:Z", "RG:Z" );


# close ( $IN );
# close ( $OUT );


# ok ( -f "t/data/outpath/annotated.bam", "t/data/outpath/annotated.bam file");

my $cmd = "samtools view -h t/data/ChrM_subset.bam | perl -I lib bin/changeReadGroup.pl t/data/barcodes.tsv 100 'CB:Z', 'RG:Z' ".
	"> t/data/outpath/annotated.sam ";

if ( -f "t/data/outpath/annotated.sam" ){
	unlink( "t/data/outpath/annotated.sam" );
}

system ( $cmd );

ok ( -f "t/data/outpath/annotated.sam", "t/data/outpath/annotated.sam file");