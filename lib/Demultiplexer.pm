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

# set up the logging environment
my $logger = get_logger();

{
	# Usage statement
	Readonly my $NEW_USAGE => q{ new( {
		plate_primer_file => ,
		[metadata_file => ,]
	})};

	# Attributes #
	my %plate_primer_file_of;
	my %metadata_file_of;
	my %index_to_well_file_of;
	my %index_to_well_href_of;
	
	# Getters #
	sub get_plate_primer_file;
	sub get_metadata_file;
	sub get_index_to_well_href;
	sub get_index_to_well_file;

	# Setters #
	sub set_plate_primer_file;
	sub set_index_to_well_href;

	# Others #



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
				$arg_href->{plate_primer_file},
			) {
			MyX::Generic::Undef::Param->throw(
				error => 'Undefined parameter value',
				usage => $NEW_USAGE,
			);
		}

		# Bless a scalar to instantiate an object
		my $new_obj = bless \do{my $anon_scalar}, $class;

		# Set Attributes
		$new_obj->set_plate_primer_file($arg_href->{plate_primer_file});
		
		#if ( defined $arg_href->{metadata_file} ) {
		#	$new_obj->set_metadata_file($arg_href->{metadata_file});
		#}
		
		if ( defined $arg_href->{index_to_well_file} ) {
			$new_obj->set_index_to_well_file($arg_href->{index_to_well_file});
			$new_obj->set_index_to_well_href($arg_href->{index_to_well_file});
		}

		return $new_obj;
	}

	###########
	# Getters #
	###########
	sub get_plate_primer_file {
		my ($self) = @_;
		
		return $plate_primer_file_of{ident $self};
	}
	
	sub get_metadata_file {
		my ($self) = @_;
		
		return $metadata_file_of{ident $self};
	}
	
	sub get_well_from_barcode {
		my ($self, $well) = @_;
		
		is_defined($well);
		
		my $barcode;
		if ( defined $index_to_well_href_of{ident $self}->{$well} ) {
			$barcode = $index_to_well_href_of{ident $self}->{$well}
		}
		else {
			
		}
	}
	
	sub get_index_to_well_file {
		my ($self) = @_;
		
		return $index_to_well_file_of{ident $self};
	}

	###########
	# Setters #
	###########
	sub set_plate_primer_file {
		my ($self, $file) = @_;
		
		# check if the parameter is defined
		is_defined($file, "file");
		
		# check if the file exists and is non empty
		check_file($file);
		
		$plate_primer_file_of{ident $self} = $file;
		
		return 1;
	}
	
	sub set_metadata_file {
		my ($self, $file) = @_;
		
		# check if the parameter is defined
		is_defined($file, "file");
		
		# check if the file exists and is non empty
		check_file($file);
		
		$metadata_file_of{ident $self} = $file;
		
		return 1;
	}
	
	sub set_index_to_well_file {
		my ($self, $file) = @_;
		
		# check if the parameter is defined
		is_defined($file, "file");
		
		# check if the file exists and is non empty
		check_file($file);
		
		$index_to_well_file_of{ident $self} = $file;
		
		return 1;
	}
	
	sub set_index_to_well_href {
		my ($self, $file) = @_;
		
		my $href;
		
		# save the file
		eval { $self->set_index_to_well_file($file) };
		if ( my $e = Exception::Class->caught('MyX::Generic::Undef::Param') ) {
			$href = _get_default_index_href();
		}
		else {
			open my $IN, "<", $file or
				MyX::Generic::File::CannotOpen->throw(
					error => "Cannot open file ($file)"
				);
			
			my @vals = ();
			foreach my $line ( <$IN> ) {
				chomp($line);
				next if /^Sample_Well/i;
				@vals = split("\t", $line);
				$href->{$vals[1]} = $vals[0];
			}
			close($IN);
		}
		
		$index_to_well_href_of{ident $self} = $href;
		
		return($href);
	}

	##########
	# Others #
	##########
	sub _get_default_index_href {
		my $href = {
			"A1" => "CGTCGGTA",
			"B1" => "GTGTCCAA",
			"C1" => "TCCATGCG",
			"D1" => "AGGTTCGC",
			"E1" => "GTCGAAGC",
			"F1" => "ACGGCTGA",
			"G1" => "CTATCTGG",
			"H1" => "TGGACTCT",
			"A2" => "ATTGTGAG",
			"B2" => "TGTCGTCA",
			"C2" => "CGTTCTAA",
			"D2" => "TGTGAACC",
			"E2" => "GGCCTATC",
			"F2" => "GGATATAG",
			"G2" => "GCTGAAGA",
			"H2" => "CGGTGTCT",
			"A3" => "GTCAGCTG",
			"B3" => "GCCGACTT",
			"C3" => "CTAAGGAG",
			"D3" => "TCAGGCCA",
			"E3" => "TACTTGCA",
			"F3" => "CTTACTAG",
			"G3" => "TGATCCTA",
			"H3" => "ACGTTCAT",
			"A4" => "TCGCACAA",
			"B4" => "ACCATCGT",
			"C4" => "AAGGCACG",
			"D4" => "GCTAGTTC",
			"E4" => "CGCTGAAT",
			"F4" => "CACCGATT",
			"G4" => "CATGGACG",
			"H4" => "CATCTTAC",
			"A5" => "CTGTAACA",
			"B5" => "GATGATCG",
			"C5" => "AGCCGTTA",
			"D5" => "TAAGCATG",
			"E5" => "TGTGCGTA",
			"F5" => "TGGCTCTA",
			"G5" => "CGACCTTA",
			"H5" => "AGTGCCAC",
			"A6" => "CACTTCTG",
			"B6" => "CGCTAGTA",
			"C6" => "GGAACGCT",
			"D6" => "ATGACTCA",
			"E6" => "GTAGGACC",
			"F6" => "GTACGCGT",
			"G6" => "AGATGGCT",
			"H6" => "ATACGGAC",
			"A7" => "GAACGTAT",
			"B7" => "AACCAGCT",
			"C7" => "GGCGCTTA",
			"D7" => "CTTCGCAG",
			"E7" => "CGGCTACA",
			"F7" => "CTCTACAG",
			"G7" => "GCTTAATA",
			"H7" => "ACCTCAGA",
			"A8" => "CGAATCCT",
			"B8" => "TAGCAGTG",
			"C8" => "GTGACATG",
			"D8" => "CGGCAGAA",
			"E8" => "CAGCGTGT",
			"F8" => "GTGTATGC",
			"G8" => "ACATTGCG",
			"H8" => "TCTTCGAG",
			"A9" => "GCAACGTC",
			"B9" => "GCAGCTCT",
			"C9" => "GAGGTTAC",
			"D9" => "CATGAAGT",
			"E9" => "AGTATGCA",
			"F9" => "GATGCCTT",
			"G9" => "GCGAATAC",
			"H9" => "ATCTGCGA",
			"A10" => "AACAGGTG",
			"B10" => "TACCATGA",
			"C10" => "CCAACTAG",
			"D10" => "ATAGTCCG",
			"E10" => "TTAAGCGA",
			"F10" => "ACGTCCTG",
			"G10" => "CAGTAATG",
			"H10" => "TTCCATAG",
			"A11" => "TGCACAAT",
			"B11" => "CATGAGGC",
			"C11" => "ACAGGAGT",
			"D11" => "AGCCTTCT",
			"E11" => "TGACTAGT",
			"F11" => "CGAGTATC",
			"G11" => "CAATGTCG",
			"H11" => "GCGTCACG",
			"A12" => "TTATAGGC",
			"B12" => "GAGTGCTA",
			"C12" => "ACGTCTTA",
			"D12" => "TTGTGCAC",
			"E12" => "GGCGTTAC",
			"F12" => "GTCTCGCA",
			"G12" => "TCTTGACG",
			"H12" => "GTGCTACT"
		};
		
		# I want the barcode as the key
		my %nhash = reverse %{$href};
		
		return(\%nhash);
	}
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Demultiplexer - [One line description of module's purpose here]


=head1 VERSION

This document describes Demultiplexer version 0.0.1


=head1 SYNOPSIS

    use Demultiplexer;

=for author to fill in:
    Brief code example(s) here showing commonest usage(s).
    This section will be as far as many users bother reading
    so make it as educational and exeplary as possible.
  
  
=head1 DESCRIPTION

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.


=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.
  
Demultiplexer requires no configuration files or environment variables.


=head1 DEPENDENCIES

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

Carp
Readonly
Class::Std::Utils
List::MoreUtils qw(any)
Log::Log4perl qw(:easy)
Log::Log4perl::CommandLine qw(:all)
MyX::Generic
version; our $VERSION = qv('0.0.1')


=head1 INCOMPATIBILITIES

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.


=head1 METHODS

=over

=for author to fill in:
	A list of method names in the module
	
	new
	get_plate_primer_file
	set_plate_primer_file
	get_metadata_file
	set_metadata_file

=back

=head1 METHODS DESCRIPTION

=head2 new

	Title: new
	Usage: Demultiplexer->new({
				plate_primer_file => $file,
			});
	Function:
	Returns: Demultiplexer
	Args: -plate_primer_file => links plates to frameshifted primers
	Throws: MyX::Generic::Undef::Param
	Comments: NA
	See Also: NA
	
=head2 get_plate_primer_file

	Title: get_plate_primer_file
	Usage: $obj->get_plate_primer_file()
	Function: Returns path to plate primer file
	Returns: str
	Args: NA
	Throws: NA
	Comments: NA
	See Also: NA
	
=head2 set_plate_primer_file

	Title: set_plate_primer_file
	Usage: $obj->set_plate_primer_file($file)
	Function: sets the plate_primer_file value
	Returns: 1 on success
	Args: -file => Path to plate primer file
	Throws: MyX::Generic::Undef::Param
	        MyX::Generic::DoesNotExist::File
	        MyX::Generic::File::Empty
	Comments: NA
	See Also: NA
	
=head2 get_metadata_file

	Title: get_metadata_file
	Usage: $obj->get_metadata_file()
	Function: Returns path to optional metadata file
	Returns: str
	Args: NA
	Throws: NA
	Comments: OPTIONAL
	See Also: NA
	
=head2 set_metadata_file

	Title: set_metadata_file
	Usage: $obj->set_metadata_file($file)
	Function: sets the path to the metadata file
	Returns: 1 on success
	Args: -file => Path to metadata file
	Throws: MyX::Generic::Undef::Param
	        MyX::Generic::DoesNotExist::File
	        MyX::Generic::File::Empty
	Comments: NA
	See Also: NA


=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-demultiplexer@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 TO DO

= for author to fill in:
	Include a list of features and/or tasks that have yet to be
	implemented in this object.

None

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

