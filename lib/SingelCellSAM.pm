package SingelCellSAM;


use strict;
use SingelCellSAM::BAMfile::BamEntry;
use SingelCellSAM::Barcodes;
use SingelCellSAM::FastqFile::FastqEntry;

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
    open ( my $stdout, ">&", STDOUT );
    $self->{'out'} = $stdout;
    return $self;
}

DESTROY{
    my $self = shift;
    close ( $self->{'out'} );
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

 Usage     : SingelCellSAM::annotate10xcells( SAMstream, R2fileStream, I1fileStream, $bcFileStream, $cell_barcode_length=15 )
 Purpose   : use the annotation R2 and I1 fastq files to annotate the reads in the (bwa) sam file
 Returns   : print the resulting sam strings to STDOUT and a per cell count into the bcFiles
 Argument  : the sam file stream and the fastq files with the annotation read as well as the bcFile
 Throws    : Exceptions and other anomolies
 Comment   : Adds the 10x annotation tags to each bwa mapped read.

=cut

sub annotate10xcells
{
    my ( $self, $IN, $annotationReadFQ, $I1read, $bcFile, $cell_barcode_length ) = @_;


    $cell_barcode_length ||= 15;

    ## The test files should have been created in
    ## /home/stefanl/NAS/TestData_ChrM_SNPs/10k_PBMC_Multiome_nextgem_Chromium_X_fastqs/10k_PBMC_Multiome_nextgem_Chromium_X_atac
    ## on aurora-ls2.lunarc.lu.se
    ## logics should follow https://github.com/stela2502/Chromium_SingleCell_Perl/blob/master/bin/BAM_restore_CellRanger.pl
    ## or better this: https://github.com/stela2502/Chromium_SingleCell_Perl/blob/master/bin/SplitToCells.pl
    my ( $fastqEntry, $bamEntry, $I1entry, $bcs, $bc );    ## f1, f2, i1

    #print( "I got the samStream '$samStream' and the annotationReadFQ '$annotationReadFQ'\n\n");

    my $i = 0;
    my $fastqReads = 0;
    $bcs = {};
    my $dataArea = 0;

    sub readSeqs {
        my $acc = shift;
        my $fastqEntry = SingelCellSAM::FastqFile::FastqEntry ->new ();
        $fastqEntry = $fastqEntry ->fromFile ( $annotationReadFQ, $acc );
        my $I1entry = SingelCellSAM::FastqFile::FastqEntry ->new ();
        $I1entry = $I1entry -> fromFile ( $I1read, $acc );
        return ( $fastqEntry, $I1entry);
    }
    LOOP: while ( my $line = <$IN> ) {

        #print STDERR $line;

        $bamEntry = SingelCellSAM::BAMfile::BamEntry->new();
        $bamEntry = $bamEntry->fromLine ( $line );


        last  if ( not defined $bamEntry);
        
        if ( not $bamEntry->isa('SingelCellSAM::BAMfile::BamEntry') ){
            ## this has been a comment!
            if ( not $dataArea ){
                print $bamEntry;
            }
            next LOOP;
        }

        $i++;
        #print STDERR "The line we are on: $i\n";

        if ( not defined $fastqEntry){
            ( $fastqEntry, $I1entry ) = readSeqs();
            $fastqReads++;
        } 
        elsif ( not $fastqEntry->name()  eq  $bamEntry->name() ){
            #if the sequence is paired we get two bam entries per read pair.
            ( $fastqEntry, $I1entry ) = readSeqs($bamEntry->name());
            $fastqReads++;
        }
        
        die "the bam entry ".$bamEntry->name()." has no line in one of the fastq files\n" 
            if ( not defined $fastqEntry or not defined $I1entry);

        ## could be possible the initial alignement got already filtered.
        ## read new fastq ewntries until we find the correct one.
        while ( not $fastqEntry->name()  eq  $bamEntry->name() ) {
            ( $fastqEntry, $I1entry ) = readSeqs();
        }
        if ( not $fastqEntry->name()  eq  $bamEntry->name() ) {
            die( "line $i: The bam entry \n'".$bamEntry->name().
                "' does not match the fastq entry name \n'".$fastqEntry->name()."'\n" );
        }
        
        #print STDERR "\n".join("\t", @{$bamEntry->{'data'}})."\n" ;
        #print STDERR "And the fastq entry:\n'".$fastqEntry->name."'\n'".$fastqEntry->sequence."'\n";

        $bc = substr( revSeq( $fastqEntry->sequence() ), 0, $cell_barcode_length );
        $bcs->{$bc} ||= 0;
        $bcs->{$bc} ++;

        $bamEntry ->Add ( join( ":", "CR","Z", $bc ) );
        $bamEntry ->Add ( join( ":", "CB","Z", $bc ) ); # brutal hack to get the cell bar copdes in. Does only work to get the vcf files correctly.
        $bamEntry ->Add ( join( ":", "CY","Z", substr( revSeq( $fastqEntry->quality() ), 0, $cell_barcode_length ) ) );

        # BC:Z:TACGAGTT   QT:Z:F:FFFFFF
        $bamEntry ->Add ( join( ":", "BC","Z",  $I1entry->sequence()  ) );
        $bamEntry ->Add ( join( ":", "QT","Z",  $I1entry->quality()   ) );

        $bamEntry -> print( );

        $dataArea = 1;
        # for the atac sequences the reverse R2 is the sample tag "CR:Z:" rev(R2)[0..15]
        # the CB:Z: tag looks like black magic to me. I can not determine how that one is created.

        #     CR:Z:    
        # ACACCGGCAAACCAGC
        # CB:Z:
        #     TAGTGGCGTACTGAAT-1
        # GGGTTAGGGTTAGGGTTAGGGTTAGGGTTAGGGATATCGGTTGTTATAG
    }

    if ( $i > $fastqReads ){
        foreach my $key ( sort { $bcs->{$b} <=> $bcs->{$a} } keys(%$bcs) ){
            $bcs->{$key} = $bcs->{$key} / 2;
            #print STDERR "$key\t$bcs->{$key}\n";
            print $bcFile "$key\t$bcs->{$key}\n";
        }
    }
    else {
        foreach my $key ( keys(%$bcs) ){
            $bcs->{$key} = $bcs->{$key};
            #print STDERR "$key\t$bcs->{$key}\n";
            print $bcFile "$key\t$bcs->{$key}\n";
        }
    }

    $self->{'bcs'} = $bcs;

    print  STDERR "SingelCellSAM::annotate10xcells finished: ",scalar(keys%$bcs)." 'cell barcodes' detected.\n";
    return ($self);
}

sub revSeq{
    my ( $origin_seq ) = @_;
    my $revcomp = reverse $origin_seq;
    $revcomp =~ tr/ATGCatgc/TACGtacg/;
    return $revcomp;
}



=head2 changeReadGroup

 Usage     : SingelCellSAM::changeReadGroup( $INstream, $OUTstream, $barcodesFile, $minNumi, source, taget )
 Purpose   : replace the read group by the single cell tag
 Returns   : NULL
 Argument  : 
 Throws    : Exceptions and other anomolies
 Comment   : The function reads from STDIN and prints to STDOUT or any stream you give the function
             The source for a 10x data set should be "CR:Z" and the target "RG:Z"

=cut

sub changeReadGroup
{

    my ($self, $barcodes, $minNumi, $source, $target) = @_;

    $minNumi ||= 100;
    $source  ||= "CR:Z";
    $target  ||= "RG:Z";

    my $bcs = {};
    my ($bc, $nUMI, $line, $RGmissing, @lines );
    $RGmissing = 1;
    open (my $bar , "<$barcodes") or die $!;
    open (my $out , ">$barcodes.passing") or die $!;
    while( my $bc  = <$bar> ){
        chomp($bc);
        ( $bc, $nUMI ) = split("\t", $bc);
        if ( defined $nUMI ){
            if ( $nUMI > $minNumi){
                $bcs->{$bc} =1;
                print $out $bc."\n";
            }
        }else{
           $bcs->{$bc} =1;
           print $out $bc."\n";
        }
        
    }
    close ( $bar );
    close ( $out );


    while ( <STDIN> ){
        $line = $self->change( $_, $bcs, $source, $target );
        if ( $line =~m/^@/ ){
            if ( $RGmissing ){
                $RGmissing = 0; # do that only once
                @lines = (map { "\@RG\tID:$_\tSM:$_\n" } keys %$bcs );
                print STDOUT join("", @lines);

            }
        }
        if ( $line =~ m/^\@RG/ ){
            next;
        }
        if ( $line ){
            #print STDERR $line;
            print STDOUT $line;
        }else {
            #print STDERR "FAILED: $_";
        }
    }

    return $self;
}

sub change
{

    my ($self, $line, $bcs, $source, $target) = @_;
    $source = "CB:Z" unless ( defined $source);
    $target = "RG:Z" unless ( defined $target);


    my ($s, $t );
    if ( $_ =~ m/^@/ ){
        return ( $line );
    }
    if ( $line =~m/$source:([\w-\d]*)/ ){
        $s = $1;
        return undef unless ( $bcs->{$s} );
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
            #die "This is a header line: $line";
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
                #print STDERR "matcged to \@RG: $line\n";
            }else {
                foreach my $fn (@{$barcodes->{'files'}} ){
                    #print STDERR $line;
                    print $fn $line;
                }
            }
        }
        #########################
        # fix the data lines
        #########################
        elsif($line =~ m/CB:Z:([AGCTacgt]+-?\d*)/ ) {
            chomp($line);

            #####################
            # fix the RG entry
            #####################
            $line = $self->change( $line, $barcodes->{'barcodes'}, "CB:Z", "RG:Z" );
            

            if ( not defined $line ){
                warn ("barcode $1 is not defined\n".scalar( keys %{$barcodes->{'barcodes'}} ));
            }else {
                #################
                # get the correct outfile & print
                #################
                $tmp = $barcodes->{'barcodes'}->{$1};
                print $tmp $line."\n";
            }
        }
        #########################
    }

    #############################
    # recursion if there are too many cells!
    #############################
    my @res = $barcodes->writeNewBarcodeFiles();
    undef $barcodes;
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

