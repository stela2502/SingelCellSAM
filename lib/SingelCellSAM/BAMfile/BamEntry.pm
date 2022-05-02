package SingelCellSAM::BAMfile::BamEntry;

#use FindBin;
#use lib "$FindBin::Bin/../lib/";
use strict;
use warnings;

use vars '$VERSION'; $VERSION = '0.4.1';

=head1 LICENCE
  Copyright (C) 2022-04-25 Stefan Lang
  This program is free software; you can redistribute it 
  and/or modify it under the terms of the GNU General Public License 
  as published by the Free Software Foundation; 
  either version 3 of the License, or (at your option) any later version.
  This program is distributed in the hope that it will be useful, 
  but WITHOUT ANY WARRANTY; without even the implied warranty of 
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
  See the GNU General Public License for more details.
  You should have received a copy of the GNU General Public License 
  along with this program; if not, see <http://www.gnu.org/licenses/>.
=for comment
This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.
=head1 NAME
SingelCellSAM::BAMfile::BamEntry
=head1 DESCRIPTION
SIMPLE bam file interface that uses samtools view in the back - not a compressed file reader.
=head2 depends on
=cut

=head1 METHODS
=head2 new ( $hash )
new returns a new object reference of the class SingelCellSAM::BAMfile.
All entries of the hash will be copied into the objects hash - be careful t use that right!
=cut

sub new {

	my ( $class, $hash ) = @_;

	my ($self, @arr);

	$self = {
    data => \@arr,
  };
	foreach ( keys %{$hash} ) {
		$self->{$_} = $hash->{$_};
	}

	bless $self, $class if ( $class eq "SingelCellSAM::BAMfile::BamEntry" );

	return $self;

}

=head2 fromFile

 Usage     : SingelCellSAM::BAMfile::BamEntry::fromFile( $fh )
 Purpose   : split the bam entry by tab and 'package that info into this object
 Returns   : a SingelCellSAM::BAMfile::BamEntry object or prints the header and returnd 0
 Argument  : the file handle to read from
 Throws    : Exceptions and other anomolies
 Comment   : parse through a BAM/SAM file one entry at a time

=cut

sub fromFile{
  my ( $self, $fh ) = @_;
  
  if ( $fh and my $line = <$fh> ) {
    return $self->fromLine( $line );
  }
  else {
      return undef;
  }

  return $self;
}


=head2 fromLine

 Usage     : SingelCellSAM::BAMfile::BamEntry::fromFile( $line )
 Purpose   : split the bam entry by tab and 'package that info into this object
 Returns   : a SingelCellSAM::BAMfile::BamEntry object or prints the header and returnd 0
 Argument  : the file handle to read from
 Throws    : Exceptions and other anomalies
 Comment   : parse one SAM file line

=cut

sub fromLine{
  my ( $self, $line ) = @_;
  
  if ( $line =~ m/^@/ ){
    print $line;
    return $line;
  }
  chomp($line);
  $self->{'data'} = [ split("\t", $line) ];

  return $self;
}


=head2 print

 Usage     : SingelCellSAM::BAMfile::BamEntry::print( $fh )
 Purpose   : print the bam entry to the file handle or <STDOUT>
 Returns   : the SingelCellSAM::BAMfile::BamEntry object
 Argument  : the file handle to read from
 Throws    : Exceptions and other anomolies
 Comment   : print the SAM entry to a file

=cut


sub print {
  my ( $self, $fh ) = @_;

  #print "I got the fh $fh.\n";
  $fh ||= *STDOUT;
  #print "And now I have the fh $fh\n";

  #die join("\t", @{$self->{'data'}}). "\n" ;

  print $fh join("\t", @{$self->{'data'}}). "\n" ;

  return $self;
}


=head2 Add

 Usage     : SingelCellSAM::BAMfile::BamEntry::Add( $entry )
 Purpose   : add one entry to the BAM/SAM data
 Returns   : the SingelCellSAM::BAMfile::BamEntry object
 Argument  : the entry to add
 Throws    : Exceptions and other anomolies
 Comment   : naively simple function to make the reading easier...

=cut

sub Add{
  my ($self, $entry) = @_;
  if ( defined $entry){
    push( @{$self->{'data'}}, $entry);
  }

  return $self;
}

=head2 name

 Usage     : SingelCellSAM::BAMfile::BamEntry::name( $name )
 Purpose   : setter/getter for the SAM name
 Returns   : the name
 Argument  : the entry to add
 Throws    : Exceptions and other anomolies
 Comment   : naively simple function to make the reading easier...

=cut

sub name{
  my ($self, $entry) = @_;
  if ( defined $entry){
    @{$self->{'data'}}[0] = $entry;
  }

  return @{$self->{'data'}}[0]
  ;
}