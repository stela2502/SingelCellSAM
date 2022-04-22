package SingelCellSAM;


use strict;
use SingelCellSAM::Barcodes;

use File::Basename;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '0.01';
    @ISA         = qw(Exporter);
    #Give a hoot don't pollute, do not export more than needed by default
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
}


#################### subroutine header begin ####################

=head2 

 Usage     : How to use this function/method
 Purpose   : What it does
 Returns   : What it returns
 Argument  : What it wants to know
 Throws    : Exceptions and other anomolies
 Comment   : This is a sample subroutine header.
           : It is polite to include more pod and fewer comments.

=cut

#################### subroutine header end ####################


sub new
{
    my ($class) = @_;

    my $self = bless ({}, ref ($class) || $class);

    return $self;
}


=head2 readBarcodes

 Usage     : SingelCellSAM::readBarcodes( file, opath )
 Purpose   : creates a Barcodes object, fills it and returns it.
 Returns   : a populated SingleCellSAM::Barcodes object
 Argument  : the barcodes list file and the outpath for the sam file splits
 Throws    : Exceptions and other anomolies
 Comment   : This is a sample subroutine header.
           : It is polite to include more pod and fewer comments.

=cut

sub readBarcodes
{
    my ( $class, $barcodeF, $opath ) = @_;

    my $ret = SingelCellSAM::Barcodes->new();
    return $ret->read($barcodeF, $opath);

}


=head2 annotate10xcells

 Usage     : SingelCellSAM::annotate10xcells( samStream, annotationReadFQ )
 Purpose   : use the annotation R2 (or R3) fastq file to annotate the reads in the (bwa) sam file
 Returns   : print the resulting sam strings to STDOUT
 Argument  : the sam file stream an the fastq file with the annotation read
 Throws    : Exceptions and other anomolies
 Comment   : Adds the 10x annotation tags to each bwa mapped read.

=cut

sub annotate10xcells
{
    my ( $class, $samStream, $annotationReadFQ ) = @_;

    ## The test files should have been created in
    ## /home/stefanl/NAS/TestData_ChrM_SNPs/10k_PBMC_Multiome_nextgem_Chromium_X_fastqs/10k_PBMC_Multiome_nextgem_Chromium_X_atac
    ## on aurora-ls2.lunarc.lu.se

    die ( "not implemented" );

}



=head2 changeReadGroup

 Usage     : SingelCellSAM::changeReadGroup( sam/bam ifile, opath, source, taget )
 Purpose   : replace the read group by the single cell tag
 Returns   : NULL
 Argument  : 
 Throws    : Exceptions and other anomolies
 Comment   : The source for a 10x data set should be "CB:Z" and the target "RG:Z"

=cut

sub changeReadGroup
{

    my ($self, $ifile, $opath, $source, $target) = @_;
    $source = "CB:Z" unless ( defined $source);
    $target = "RG:Z" unless ( defined $target);

    unless ( -f $ifile ) {
        die "changeReadGroup: ifile '$ifile' is no file!";
    }

    unless ( -d $opath ){
        mkdir( $opath ) or die $!;
    }

    my $in;
    if ( $ifile =~ m/sam$/ ) {
        open ( $in, "<$ifile") or die $!;
    }elsif ( $ifile =~ m/bam$/ ){
        open ( $in, "samtools view -h $ifile|" ) or die $!;
    }
    open ( my $out, ">".$opath."/".basename( $ifile ).".sam" ) or die $!;
    my ($s, $t, $line);
    while ( <$in> ){
        print $out $self->change( $_, $source, $target );
    }
    close ( $in );
    close ( $out );
    print "changed file: '$opath/".basename( $ifile ).".sam'\n";
    return $self;
}

sub change
{

    my ($self, $line, $source, $target) = @_;
    $source = "CB:Z" unless ( defined $source);
    $target = "RG:Z" unless ( defined $target);


    my ($s, $t );
    if ( $_ =~ m/^@/ ){
        return ( $line );
    }
    if ( $line =~m/$source:([\w-\d]*)/ ){
        $s = $1;
        if ( $line =~m/$target:([\w-_:\d]*)/ ){
            $t = $1;
            $line =~ s/$t/$s/;
        }
    }
    return ( $line );

}


=head2 splitSAM

 Usage     : SingelCellSAM::splitSAM( file, opath, $stream )
 Purpose   : split a 10x sam/bam file into single cell sam files
 Returns   : NULL
 Argument  : the barcodes list file and the outpath for the sam file splits and a  stream if not reading from stdin
 Throws    : Exceptions and other anomolies
 Comment   : This is the main split function.

=cut

sub splitSAM
{
    my ( $self, $barcodes, $opath, $stream ) = @_;
    my $barcodes = $self->readBarcodes ( $barcodes, $opath );

    #print "\nThis is the stream variable:".$stream."\n";
    if ( not defined $stream || $stream eq ""  ){
        $stream = "STDIN"
    }

    my($line, $cmd, $id, $tmp, $RGmissing, @lines, @bcs, $fn, $pat);
    $pat = qr'@RG';
    $RGmissing = 1;
    $id = 0;
    while ( <$stream> ) {
        $line = $_;
        #die "\n".$line."\n";
        print(".") if ($id++ % 1000 == 0);
        ########################
        ## fix the header lines:
        ########################
        if ($line =~ m/^@/ ) {
            ## this needs to go into all the outfiles!
            ## read groups is a funny problem. Seams to be @RG elements in the read group, but they are not used as single cell id's
            ## I want to check whether I could make use of them like that.
            #die "reading this line:". $line;
            if ( $line =~ m/^\@RG/ ){
                ## This will be more complicated here - every sam file need to get the 'correct' entry
                #print "\nmatched a \@RG\n";
                if ( $RGmissing ){
                $RGmissing = 0; # do that only once
                for ( my $i = 0; $i < @{$barcodes->{'files'}}; $i++){
                    #print ( $i ."\n");
                    @bcs = @{@{$barcodes->{'barcodes4files'}}[$i]};
                    @lines = (map { "\@RG\tID:$_\tSM:$_\n" } @bcs[1..(@bcs-1)] );
                    $fn = @{$barcodes->{'files'}}[$i];
                    print $fn join("", @lines);
                    #if ( @lines == 1){
                    #    close ( $fn );
                    #    die @lines;
                    #}
                } 
                #die "some problems with the headers - please inspect and fix!\n";
                }
            }else {
                foreach my $fn (@{$barcodes->{'files'}} ){
                    print $fn $line;
                }
            }
            
        }
        #########################
        # fix the data lines
        #########################
        elsif($line =~ m/CB:Z:([AGCTacgt]+-?\d*)/ ) {
            if (defined $barcodes->{'barcodes'}->{$1}) {
                chomp($line);
                #################
                # fix the RG entry
                #################
                $line = $self->change( $line, "CB:Z", "RG:Z" );
                #################
                # get the correct outfile & print
                #################
                $tmp = $barcodes->{'barcodes'}->{$1};
                print $tmp $line."\n";
            }else {
                warn ("barcode $1 is not defined\n".scalar( keys %{$barcodes->{'barcodes'}} ));
            }
            #die $line."\n";
        }
        #########################
    }

    #############################
    # recursion if there are too many cells!
    #############################
    my @res = $barcodes->writeNewBarcodeFiles();
    DESTROY( $barcodes );
    foreach my $bcRes ( @res ) { ## only if there are multiple reads in one file.
        my $IN;
        #print( "we have summary information:", join(",",@$bcRes)."\n");
        open ( $IN, "<@$bcRes[1]") or die $!;
        $self->splitSAM( @$bcRes[0], $opath, $IN);
        close ($IN );
        unlink( @$bcRes[0] );
        unlink( @$bcRes[1] );
    }
    ###############################

    #print( "file stored in path '$opath'\n");
    return ($self);
}


#################### main pod documentation begin ###################

=head1 NAME

SingelCellSAM - Split and add 10x cell info from/to bam/sam files.

=head1 SYNOPSIS

  use SingelCellSAM;
  blah blah blah


=head1 DESCRIPTION

This tool should split a multi sample bam file into separate sam/bam files.
This is meant to help with single cell ChrM mutations that would otherwise be drowned in the other data.
This is necessary as 'normal' SNP detecttion always tries to identify mutations with at least 50% coverage.
All lower frequencies have to be classified as missreads as a normal cell only contains two copies of one genomic loci.
With the ChrM this is different. Each cell can contain multiple mitochondria which in turn can harbor multiple copied of the chromosome.
Hence we need to spliut the data at least to a cell level.

The problem therein is that we can not open that many different outfiles and I assume we sould also not try to keep all the data in memory.
The solution is that we know the barcodes a priori and therefore can slowly claw our way through the data 1000 open files at a time.



=head1 USAGE



=head1 BUGS



=head1 SUPPORT



=head1 AUTHOR

    Stefan Lang
    CPAN ID: MODAUTHOR
    Lund University
    Stefan.Lang@Med.Lu.SE
    https://www.lunduniversity.lu.se/lucat/user/a7a5dbdaf4a0ba980a83f04b4e8869f4

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

#################### main pod documentation end ###################


1;
# The preceding line will help the module return a true value

