package SingelCellSAM::Barcodes;
use strict;
use POSIX qw/ceil/;
use File::Spec::Functions;
#use IO::Handle;
use Fcntl;

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


sub new
{
    my ($class, %parameters) = @_;

    my (@files, $barcodes, @bc4f);

    my $self = bless ({
    	maxOpen => 10, # during development
    	merged => 0,
    	files => \@files,
    	path => "",
    	barcodes4files => \@bc4f,
    	barcodes => $barcodes
    	}, ref ($class) || $class);

    return $self;
}


=head2 read

 Usage     : SingelCellSAM::readBarcodes( file, opath )
 Purpose   : reads all barcodes in a barcodes list and opens files for groups of barcodes
 Returns   : a Barcodes object
 Argument  : the barcodes file and a path to create the outfiles in
 Throws    : Exceptions and other anomolies
 Comment   : under development

=cut

sub read{
	my ( $self, $file, $path) = @_;
	if ( ! -d $path ){
		unless(mkdir $path) {
        	die "Unable to create $path\n$!\n";
    	}
	}
	$self->{'path'} = $path;
	if ($file =~m/gz$/ ) {
 		open(IN, "zcat $file |") or die "gunzip $file: $!";
	} else {
  		open(IN, "<$file") or die $!;
	}
	my @barcodes;
	while ( <IN> ) {
  		chomp;
  		my $bc = $_;
  		push( @barcodes, $bc);
  	}
  	close(IN);
  	#warn("I have read ".scalar(@barcodes)." different barcodes\n");
  	$self->{'path'} = $path;
  	## now create the outfiles and remember the outfile for each barcode
  	my $splitBy = 1;
  	my $prefix = "";
  	$splitBy = ceil( scalar(@barcodes) / $self->{'maxOpen'} );
  	if ( $splitBy > 1 ){
  		$prefix = "sumOf".$splitBy;
  		$self->{'merged'} = 1;
  	}else {
  		$self->{'merged'} = 0;
  	}

  	my ($ofile);
  	for ( my $i = 0; $i < @barcodes; $i++ ){
  		if ( $i % $splitBy == 0 ){
  			$ofile = catfile( $path, $prefix.$barcodes[$i].".sam" );
  			#sysopen(my $fh, $ofile, O_WRONLY|O_CREAT)
   			#	or die "Can't open $ofile: $!";
  			#$fh->autoflush(1);
  			{
   			 	# Symbolic References require 'no strict'.
    			open( my $tmp,">".$ofile ) or die $!;  # Dynamic name.
    			push( @{$self->{'files'}}, $tmp );
  			}
  			#####
  			#warn ( join(", ", @{$self->{'files'}}));
  			#####
  			my @tmp = ( $prefix.$barcodes[$i].".tsv" );
  			push( @{$self->{'barcodes4files'}}, \@tmp );
  		}
  		$self->{'barcodes'}->{$barcodes[$i]} = @{$self->{'files'}}[@{$self->{'files'}}-1];
  		#warn ( "I have this barcodes4filesref: ".$self->{'barcodes4files'}. "\n" );
  		#warn( "With this internal array:. ". join(", ",@{$self->{'barcodes4files'}} )."\n");

  		push( @{@{$self->{'barcodes4files'}}[scalar @{$self->{'barcodes4files'}}-1]}, $barcodes[$i] );
  	}
  	#warn("I have opened files for ".scalar(keys %{$self->{'barcodes'}})." different barcodes\n");
	#while ( my ($key, $value) = each (%{$self->{'barcodes'}})){
	#	print ("BC:".$key."  GLOB:".$value."\n" );
	#}
	# if ( scalar( @{$self->{'barcodes4files'}} ) < scalar(@barcodes) ){
	# 	## merge and we need tth updated barcodes files!
	# 	foreach my $arr ( @{$self->{'barcodes4files'}} ){
	# 		my $fn = shift @$arr;
	# 		#print($fn."\n");
	# 		open (OUT, ">$self->{'path'}/$fn" ) or die $!;
	# 		print OUT join("\n", @$arr);
	# 		close (OUT);
	# 		unshift(@$arr, $fn );
	# 	}
	# }
	
	#print ( "all values in the files array:", join(", ", @{$self->{'files'}})."\n");
	my $OK = 1;
	map { $OK = 0 unless ( defined $self->{'barcodes'}->{"$_"} ) } @barcodes;
	die "Some barcodes have not been actiavted as expected!\n" unless ( $OK );
	return ($self);
}


=head2 writeNewBarcodeFiles

 Usage     : SingelCellSAM::writeNewBarcodeFiles( )
 Purpose   : if there were multiple barcodes in the outfiles the process has to be repeated
 Returns   : an array of [barcodeF, samF] entries to restart the process
 Argument  : NULL
 Throws    : Exceptions and other anomolies
 Comment   : If there were multiple barcodes in the outfiles the process has to be repeated and for that we need the new barcodes files.

=cut

sub writeNewBarcodeFiles{
	my ($self) = @_;

	my (@return);
	
	if ( $self->{'merged'} ) {
		## each of them is an array of barcodes with the first entry being the file we should write the data to.
		foreach my $arr ( @{$self->{'barcodes4files'}} ){
			my $fn = shift @$arr;
			my $sam = $fn;
			$sam =~ s/tsv$/sam/;
			open (OUT, ">$self->{'path'}/".$fn ) or die $!; 
			print OUT join("\n",@$arr); 
			close(OUT);
			my @ret = ("$self->{'path'}/".$fn, "$self->{'path'}/".$sam);
			#print("I have created the outfile '$self->{'path'}/$fn' and '$self->{'path'}/$sam'\n");
			push(@return, \@ret);
		}
	}
	else {
		### Oh cool - we are finished splicing the data - now we need to convert the sam files to bam files :-D
		foreach my $arr ( @{$self->{'barcodes4files'}} ){
			my $fn = shift @$arr;
			$fn =~ s/tsv$/sam/;
			my $bam = $fn;
			$bam =~ s/sam$/bam/;
			my $cmd = "samtools view -b $self->{'path'}/$fn > $self->{'path'}/$bam";
			#print $cmd."\n";
			system( $cmd );
			unlink( "$self->{'path'}/$fn" );
		}
	}
	return @return;
}



DESTROY {
    my ($self) = @_;
    map { close ($_) } @{$self->{files}};
    delete( $self->{'files'});
    delete( $self->{'barcodes'});
}


#################### main pod documentation begin ###################

=head1 NAME

 Barcodes

=head1 SYNOPSIS

  use SingelCellSAM;

=head1 DESCRIPTION

Barcodes is an object storing outfiles for barcodes, meaning for each barcode in a bam file
a different outfile can be kept available.

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