package Demultiplexer;

use warnings;
use strict;
use Carp;
use Readonly;
use Class::Std::Utils;
use List::MoreUtils qw(any);
use Log::Log4perl qw(:easy);
use Log::Log4perl::CommandLine qw(:all);
use MyX::Generic;
use version; our $VERSION = qv('0.0.1');
use BioUtils::FastqIO;
use BioUtils::FastaIO;
use UtilSY qw(:all);
use Data::Dumper;
use Cwd;
use Demultiplexer::Param_Handler 0.0.1;

# set up the logging environment
my $logger = get_logger();

{
	# Usage statement
	Readonly my $NEW_USAGE => q{ new( {
		param_handler => $param_handler
	})};

	# Attributes #
	my %param_handler_of;
	
	# Getters #
	sub get_param_handler;

	# Setters #
	

	# Others #
	sub demultiplex;
	


	###############
	# Constructor #
	###############
	sub new {
		my ($class, $arg_href) = @_;

		# Croak if calling new on already blessed reference
		croak 'Constructor called on existing object instead of class'
			if ref $class;

		# Make sure the required parameters are defined
		if ( any {!defined $_}
				$arg_href->{param_handler},
			) {
			MyX::Generic::Undef::Param->throw(
				error => 'Undefined parameter value',
				usage => $NEW_USAGE,
			);
		}

		# Bless a scalar to instantiate an object
		my $new_obj = bless \do{my $anon_scalar}, $class;
		
		# initialize the object attributes
		$param_handler_of{ident $new_obj} = $arg_href->{param_handler};

		return $new_obj;
	}

	###########
	# Getters #
	###########
	sub get_param_handler {
		my ($self) = @_;
		
		return $param_handler_of{ident $self};
	}

	###########
	# Setters #
	###########
	
	
	##########
	# Others #
	##########
	sub demultiplex {
		my ($self) = @_;
		
		# get the primer info
		#my $primers_to_frame = $self->parse_plate_primer_file();
		
		# variables
		my $total = 0;
		my $count = 0;
		my $header;
		my $fwd_fs;  # forward frame shift
		my $rev_fs;  # reverse frame shift
		my $index;
		my $fwd_query;
		my $rev_query;
		my $match_fwd;
		my $match_rev;
		my $plate;
		my $well;
		my $count_id;  # the seq count id in the original seq header ie P0_(13134)
		
		# open the fastq file
		my $file = $self->get_param_handler->get_fastq_file();
		my $in = BioUtils::FastqIO->new( {stream_type => '<',
										  file => $file} );

		# Read in all the sequences
		my %seqs = ();  #hash with KEY=>sampleID VALUE=>aref of seqs
		while ( my $seq = $in->get_next_seq() ) {
			$logger->debug("######################################");
			$header = $seq->get_header();
			$logger->debug("header: $header");
			
			eval {
				$fwd_fs = _get_fwd_fs($header);
				$rev_fs = _get_rev_fs($header);
				$index = _get_index($header);
				$count_id = _get_count_id($header);
				
				$fwd_query = _get_fwd_query($fwd_fs);
				$rev_query = length $rev_fs;
			
				# find the fwd match
				$match_fwd = $self->_get_fwd_match($fwd_query);
				
				# find the rev match
				$match_rev = $self->_get_rev_match($rev_query);
				
				# get the plate and well for the read
				$plate = $self->_get_plate($match_fwd, $match_rev);
				$well = $self->get_well_from_index($index);
				
				_update_seq_id($seq, $plate, $well, $count_id);
				
				_add_seq($seq->to_FastaSeq(), \%seqs, $plate . $well);
				$logger->debug("Seq added");
			};
			# skip this sequence if any of the regex's fail
			if ( my $e = Exception::Class->caught('MyX::Generic::UnmatchedRegex') ) {
				# non matching regex -- throw an error
				print $e->error, "\n";
				next;
			}
			elsif ( $e = Exception::Class->caught('MyX::Generic') ) {
				# any of the other MyX::Generic errors
				print $e->error, "\n";
				next;
			}
			elsif ( $@ ) {
				print $@, "\n";
			}
		}
		
		# output all the seqs to their files
		$self->_output_seqs(\%seqs);
		
		return 1;
	}
	
	sub _update_seq_id {
		my ($seq, $plate, $well, $count_id) = @_;
		
		my $header = $seq->get_header();
		my $new_id = "p" . $plate . "w" . $well . "_" . $count_id;
		my $new_header;
		
		if ( $header =~ m/P\d+_\d+ (.*)/ ) {
			$new_header = $new_id . " " . $1;
		}
		else {
			print "ERROR\n";
		}
		
		$seq->set_header($new_header);
		
		return 1;
	}
	
	sub _output_seqs {
		my ($self, $seqs_href) = @_;
		
		# create a dir in the output dir called samples
		my $dir = $self->get_output_dir();
		
		if ( ! -d $dir ) {
			mkdir $dir;
		}
		
		foreach my $sample ( keys %{$seqs_href} ) {
			my $file = _get_out_file_name($dir, $sample);
			my $fasta_out = BioUtils::FastaIO->new({stream_type => '>',
													file => $file});
			
			foreach my $seq ( @{$seqs_href->{$sample}} ) {
				$fasta_out->write_seq($seq);
			}
		}
	}
	
	sub _get_out_file_name {
		my ($dir, $sample) = @_;
		
		my $file = "$dir/";
		
		if ( $sample =~ m/(.*)([ABCDEFGH]\d{1,2})/i ) {
			$file .= "p" . $1 . "w" . $2 . ".fasta";
		}
		else {
			MyX::Generic::UnmatchedRegex->throw(
				error => "Unknown sample format"
			);
		}
		
		return($file);
	}
	
	sub _add_seq {
		my ($seq, $seq_href, $sample_id) = @_;
		
		if ( exists $seq_href->{$sample_id} ) {
			push @{$seq_href->{$sample_id}}, $seq;
		}
		else {
			my @arr = ();
			push @arr, $seq;
			$seq_href->{$sample_id} = \@arr;
		}
		
		return 1;
	}
	
	sub _get_plate {
		my ($self, $fwd_match, $rev_match) = @_;
		
		my $href = $self->get_param_handler()->get_plate_to_primer_href();
		my $plate_found;
		foreach my $plate ( keys %{$href} ) {
			if ( $href->{$plate}{$fwd_match} and
				 $href->{$plate}{$rev_match} ) {
				$plate_found = $plate;
			}
		}
		
		if ( ! defined $plate_found ) {
			# throw some error
			MyX::Generic->throw(
				error => "Cannot find the plate from fwd_match " .
						 "($fwd_match) and rev_match ($rev_match)"
			);
		}
		
		$logger->debug("plate found: $plate_found");
		
		return($plate_found);
	}
	
	sub _get_fwd_match {
		my ($self, $fwd_query) = @_;
		
		my $match_fwd;
		my $lookup_href = $self->get_fwd_fs_coding_href();
		if ( defined $lookup_href->{$fwd_query} ) {
			$match_fwd = $lookup_href->{$fwd_query};
		}
		else {
			# non matching fwd primer -- throw an error
			MyX::Generic->throw(
				error => "fwd query not found ($fwd_query)"
			);
		}
		
		$logger->debug("match_fwd found: $match_fwd");
		
		return($match_fwd);
	}
	
	sub _get_rev_match {
		my ($self, $rev_query) = @_;
		
		my $match_rev;
		my $lookup_href = $self->get_rev_fs_coding_href();
		if ( defined $lookup_href->{$rev_query} ) {
			$match_rev = $lookup_href->{$rev_query};
		}
		else {
			# non matching rev primer -- throw an error
			MyX::Generic->throw(
				error => "rev query not found ($rev_query)"
			);
		}
		
		$logger->debug("match_rev found: $match_rev");
		
		return($match_rev);
	}
	
	sub _get_fwd_query {
		my ($fwd_fs) = @_;
		
		my $fwd_query;
		if ( $fwd_fs =~ m/^[A-Z]{4}([A-Z]+)[A-Z]{4}$/ ) {
			$fwd_query = $1;
		}
		else {
			MyX::Generic::UnmatchedRegex->throw(
				error => "Cannot find fwd query in $fwd_fs"
			);
		}
		
		$logger->debug("fwd_query found: $fwd_query");
		
		return( $fwd_query );
	}
	
	sub _get_fwd_fs {
		my ($header) = @_;
		
		my $fwd_fs;
		if ( $header =~ m/\S+ (\S+)-\S+/ ) {
			$fwd_fs = $1;
		}
		else {
			MyX::Generic::UnmatchedRegex->throw(
				error => "Cannot find fwd frameshift barcode in $header"
			);
		}
		
		$logger->debug("fwd_fs found: $fwd_fs");
		
		return($fwd_fs);
	}
	
	sub _get_rev_fs {
		my ($header) = @_;
		
		my $rev_fs;
		if ( $header =~ m/\S+ \S+-(\S+)/ ) {
			$rev_fs = $1;
		}
		else {
			MyX::Generic::UnmatchedRegex->throw(
				error => "Cannot find rev frameshift barcode in $header"
			);
		}
		
		$logger->debug("rev_fs found: $rev_fs");
		
		return($rev_fs);
	}
	
	sub _get_index {
		my ($header) = @_;
		
		my $index;
		if ( $header =~ m/\S+ \S+ \S+ \d+:\w+:\d+:(\w+)/ ) {
			$index = $1;
		}
		else {
			MyX::Generic::UnmatchedRegex->throw(
				error => "Cannot find index in $header"
			);
		}
		
		# remove the last base
		chop($index);
		
		$logger->debug("index found: $index");
		
		return($index);
	}
	
	sub _get_count_id {
		my ($header) = @_;
		
		my $count_id;
		if ( $header =~ m/\S+_(\d+) \S+ \S+ \S+/ ) {
			$count_id = $1;
		}
		else {
			MyX::Generic::UnmatchedRegex->throw(
				error => "Cannot find count id in $header"
			);
		}
		
		$logger->debug("count_id found: $count_id");
		
		return($count_id);
	}
	
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Demultiplexer - demultiplexes frameshifted primers from MTToolbox output


=head1 VERSION

This document describes Demultiplexer version 0.0.1


=head1 SYNOPSIS

    use Demultiplexer;
	use Demultiplexer::Param_Handler;
	
	# set up the params -- see Demultiplexer::Param_Handler for details!
	my $ph = Demultiplexer::Param_Handler->new({
		plate_primer_file => $plate_primer_file,
		fastq_file => $fastq_file,
		output_dir => $output_dir
	});
	
	# set up the Demultiplexer
	my $de = Demultiplexer->new({
		param_handler => $ph
	});
	
	# demultiplex
	$de->demultiplex();
  
  
=head1 DESCRIPTION

Demultiplexer provides a framework for demultiplexing frameshifted primers
frequently used in conjuction with molecule tags.  These frameshifted primers
allow for multiplexing of many more than samples than the standard 96 illumina
barcodes.  For more details about frameshifted primers, molecule tagging, and
processing molecule tagged data please see:
L<http://www.nature.com/nmeth/journal/v10/n10/abs/nmeth.2634.html>
L<https://bmcbioinformatics.biomedcentral.com/articles/10.1186/1471-2105-15-284>

Under the molecule tagging protocol, each well in a 96 well illumina barcoded
sequencing recation will have sequences with molecule tags of different lengths.
These different lengths (ie frameshifted primers) can correspond to different
samples.  This Demulitplexer object takes the all_categrizable_reads.fastq file
from the MT-Toolbox output and splits the reads into samples based on the
frameshifted primers.

Here is the basic algorithm:

- foreach sequence in the input fastq file
	- get the molecule tag (which contains the frameshift) from the seq header
	- get the illumina barcode from the seq header
	
	- get the fwd frameshift sequence from the molecule tag
	- get the rev frameshift length from the molecule tag
	
	- lookup the fwd primer frameshift code using the fwd frameshift sequence
	- lookup the rev primer frameshift code using the rev frameshift length
	
	- lookup the plate using the fwd frameshift primer code and rev frameshift
	  primer code
	- lookup the well using the index_to_well_href
	
	- update the sequence name
	- save the sequence using its sample name
	
- print each sequence to its sample fasta file

There are several pieces of information required by Demultiplexer.  See the
documentation in Demultiplexer::Param_Handler for detailed information about the
required and option parameter values for a Demultiplexer.

=head1 CONFIGURATION AND ENVIRONMENT

Demultiplexer requires no configuration files or environment variables.


=head1 DEPENDENCIES

Carp
Readonly
Class::Std::Utils
List::MoreUtils qw(any)
Log::Log4perl qw(:easy)
Log::Log4perl::CommandLine qw(:all)
MyX::Generic
version; our $VERSION = qv('0.0.1')
BioUtils::FastqIO
BioUtils::FastaIO
UtilSY qw(:all)
Data::Dumper
Cwd
Demultiplexer::Param_Handler 0.0.1


=head1 INCOMPATIBILITIES

None reported.


=head1 METHODS

new
demultiplex
get_param_handler


=head1 METHODS DESCRIPTION

=head2 new

	Title: new
	Usage: my $obj = Demultiplexer->new({
				param_handler => $param_handler
			});
	Function: Creates a new Demultiplexer object
	Returns: Demultiplexer
	Args: -param_handler => a Demultiplexer::Param_Handler object
	Throws: MyX::Generic::Undef::Param
	Comments: NA
	See Also: Demultiplexer::Param_Handler
	
=head2 demultiplex

	Title: demultiplex
	Usage: $obj->demultiplex();
	Function: Runs the demultiplexing operation
	Returns: 1 on success
	Args: NA
	Throws: MyX::Generic::UnmatchedRegex
	        MyX::Generic
	Comments: uses BioUtils::FastqIO
	See Also: NA
	
=head2 get_param_handler

	Title: get_param_handler
	Usage: $obj->get_param_handler();
	Function: gets the Demultiplexer::Param_Handler associated with this object
	Returns: Demultiplexer::Param_Handler
	Args: NA
	Throws: NA
	Comments: NA
	See Also: Demultiplexer::Param_Hanlder


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 TO DO

- what to do with seqs that fail
- what if there is a sample that has no reads
- summary numbers
- gzip files after they are created
- refactor the parameters to a param_handler object

=head1 AUTHOR

Scott Yourstone  C<< scott.yourstone81@gmail.com >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, Scott Yourstone
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met: 

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer. 
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution. 

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

The views and conclusions contained in the software and documentation are those
of the authors and should not be interpreted as representing official policies, 
either expressed or implied, of the FreeBSD Project.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

