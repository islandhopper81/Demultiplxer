package Demultiplexer::Param_Handler;

use warnings;
use strict;
use Carp;
use Readonly;
use Class::Std::Utils;
use List::MoreUtils qw(any);
use Log::Log4perl qw(:easy);
use Log::Log4perl::CommandLine qw(:all);
use MyX::Generic;
use version; our $VERSION = qv('1.0.0');
use BioUtils::FastqIO;
use BioUtils::FastaIO;
use UtilSY 0.0.2 qw(:all);
use Data::Dumper;
use Cwd;

# set up the logging environment
my $logger = get_logger();

{
	# Usage statement
	Readonly my $NEW_USAGE => q{ new( {
		plate_primer_file => ,
		fastq_file => ,
		[output_dir => ,]
		[index_to_well_file => ,]
		[fwd_fs_coding_file => ,]
		[rev_fs_coding_file => ,]
		[bad_seqs_file => ,]
	})};

	# Attributes #
	my %plate_primer_file_of;
	my %plate_to_primers_href_of;
	my %index_to_well_file_of;
	my %index_to_well_href_of;
	my %fwd_fs_coding_file_of;
	my %fwd_fs_coding_href_of;
	my %rev_fs_coding_file_of;
	my %rev_fs_coding_href_of;
	my %fastq_file_of;
	my %output_dir_of;
	my %bad_seqs_file_of;
	
	# Getters #
	sub get_plate_to_primer_file;
	sub get_plate_to_primer_href;
	sub get_index_to_well_file;
	sub get_well_from_index;
	sub get_fwd_fs_coding_file;
	sub get_fwd_fs_coding_href;
	sub get_rev_fs_coding_file;
	sub get_rev_fs_coding_href;
	sub get_fastq_file;
	sub get_output_dir;
	sub get_bad_seqs_file;

	# Setters #
	sub set_plate_to_primer_file;
	sub set_index_to_well_file;
	sub set_index_to_well_href;
	sub set_fwd_fs_coding_file;
	sub set_fwd_fs_coding_href;
	sub set_rev_fs_coding_file;
	sub set_rev_fs_coding_href;
	sub set_fastq_file;
	sub set_output_dir;
	sub set_bad_seqs_file;
	
	# Others #
	sub parse_plate_primer_file;
	sub print_default_params;
	sub print_default_index_href;
	sub print_default_fwd_fs_coding;
	sub print_default_rev_fs_coding;


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
				$arg_href->{fastq_file},
			) {
			MyX::Generic::Undef::Param->throw(
				error => 'Undefined parameter value',
				usage => $NEW_USAGE,
			);
		}

		# Bless a scalar to instantiate an object
		my $new_obj = bless \do{my $anon_scalar}, $class;
		
		# initialize the object attributes
		$new_obj->_init($arg_href);

		return $new_obj;
	}
	
	sub _init {
		my ($self, $arg_href) = @_;
		
		# Set Attributes
		$self->set_plate_to_primer_file($arg_href->{plate_primer_file});		
		$self->parse_plate_primer_file();
		$self->set_fastq_file($arg_href->{fastq_file});
		$self->set_output_dir($arg_href->{output_dir});
		$self->set_bad_seqs_file($arg_href->{bad_seqs_file});
		
		my $file = $arg_href->{index_to_well_file};
		if ( defined $file ) {
			$self->set_index_to_well_file($file);
			$self->set_index_to_well_href($file);
		}
		else {
			$self->set_index_to_well_href();
		}
		
		$file = $arg_href->{fwd_fs_coding_file};
		if ( defined $file ) {
			$self->set_fwd_fs_coding_file($file);
			$self->set_fwd_fs_coding_href($file);
		}
		else {
			$self->set_fwd_fs_coding_href();
		}
		
		$file = $arg_href->{rev_fs_coding_file};
		if ( defined $file ) {
			$self->set_rev_fs_coding_file($file);
			$self->set_rev_fs_coding_href($file);
		}
		else {
			$self->set_rev_fs_coding_href();
		}
	}

	###########
	# Getters #
	###########
	sub get_plate_to_primer_file {
		my ($self) = @_;
		
		return $plate_primer_file_of{ident $self};
	}
	
	sub get_plate_to_primer_href {
		my ($self) = @_;
		
		return $plate_to_primers_href_of{ident $self};
	}
	
	sub get_index_to_well_file {
		my ($self) = @_;
		
		return $index_to_well_file_of{ident $self};
	}
	
	sub get_well_from_index {
		my ($self, $index) = @_;
		
		check_defined($index);
		
		my $well;
		if ( check_defined($index_to_well_href_of{ident $self}->{$index}) ) {
			$well = $index_to_well_href_of{ident $self}->{$index}
		}
		else {
			#print Dumper($index_to_well_href_of{ident $self});
			MyX::Generic::Undef->throw(
				error => "index ($index) not defined in hash"
			);
		}
		
		return($well)
	}
	
	sub get_fwd_fs_coding_file {
		my ($self) = @_;
		
		return $fwd_fs_coding_file_of{ident $self};
	}
	
	sub get_fwd_fs_coding_href {
		my ($self) = @_;
		
		return $fwd_fs_coding_href_of{ident $self};
	}
	
	sub get_rev_fs_coding_file {
		my ($self) = @_;
		
		return $rev_fs_coding_file_of{ident $self};
	}
	
	sub get_rev_fs_coding_href {
		my ($self) = @_;
		
		return $rev_fs_coding_href_of{ident $self};
	}
	
	sub get_fastq_file {
		my ($self) = @_;
		
		return $fastq_file_of{ident $self};
	}
	
	sub get_output_dir {
		my ($self) = @_;
		
		return $output_dir_of{ident $self};
	}
	
	sub get_bad_seqs_file {
		my ($self) = @_;
		
		return $bad_seqs_file_of{ident $self};
	}

	###########
	# Setters #
	###########
	sub set_plate_to_primer_file {
		my ($self, $file) = @_;
		
		# check if the parameter is defined
		check_defined($file, "file");
		
		# check if the file exists and is non empty
		check_file($file);
		
		$plate_primer_file_of{ident $self} = $file;
		
		return 1;
	}
	
	sub set_index_to_well_file {
		my ($self, $file) = @_;
		
		# check if the parameter is defined
		check_defined($file, "file");
		
		# check if the file exists and is non empty
		check_file($file);
		
		$index_to_well_file_of{ident $self} = $file;
		
		return 1;
	}
	
	sub set_index_to_well_href {
		my ($self, $file) = @_;
		
		# note: this overrides any index_to_well inforamtion that is
		# already set in this object.
		
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
				next if ( $line =~ m/^Sample_Well/i );
				@vals = split("\t", $line);
				chop $vals[1];
				$href->{$vals[1]} = $vals[0];
			}
			close($IN);
		}
		
		$index_to_well_href_of{ident $self} = $href;
		
		return($href);
	}
	
	sub set_fwd_fs_coding_file {
		my ($self, $file) = @_;
		
		# check if the parameter is defined
		check_defined($file, "file");
		
		# check if the file exists and is non empty
		check_file($file);
		
		$fwd_fs_coding_file_of{ident $self} = $file;
		
		return 1;
	}
	
	sub set_fwd_fs_coding_href {
		my ($self, $file) = @_;
		
		# note: this overrides any inforamtion that is already set in this
		# object.
		
		my $href;
		
		# save the file
		eval { $self->set_fwd_fs_coding_file($file) };
		if ( my $e = Exception::Class->caught('MyX::Generic::Undef::Param') ) {
			$href = _get_default_fwd_fs_coding_href();
		}
		else {
			open my $IN, "<", $file or
				MyX::Generic::File::CannotOpen->throw(
					error => "Cannot open file ($file)"
				);
			
			my @vals = ();
			foreach my $line ( <$IN> ) {
				chomp($line);
				@vals = split("\t", $line);
				$href->{$vals[0]} = $vals[1];
			}
			close($IN);
		}
		
		$fwd_fs_coding_href_of{ident $self} = $href;
		
		return($href);
	}
	
	sub set_rev_fs_coding_file {
		my ($self, $file) = @_;
		
		# check if the parameter is defined
		check_defined($file, "file");
		
		# check if the file exists and is non empty
		check_file($file);
		
		$rev_fs_coding_file_of{ident $self} = $file;
		
		return 1;
	}
	
	sub set_rev_fs_coding_href {
		my ($self, $file) = @_;
		
		# note: this overrides any inforamtion that is already set in this
		# object.
		
		my $href;
		
		# save the file
		eval { $self->set_rev_fs_coding_file($file) };
		if ( my $e = Exception::Class->caught('MyX::Generic::Undef::Param') ) {
			$href = _get_default_rev_fs_coding_href();
		}
		else {
			open my $IN, "<", $file or
				MyX::Generic::File::CannotOpen->throw(
					error => "Cannot open file ($file)"
				);
			
			my @vals = ();
			foreach my $line ( <$IN> ) {
				chomp($line);
				@vals = split("\t", $line);
				$href->{$vals[0]} = $vals[1];
			}
			close($IN);
		}
		
		$rev_fs_coding_href_of{ident $self} = $href;
		
		return($href);
	}
	
	sub set_fastq_file {
		my ($self, $file) = @_;
		
		check_defined($file);
		check_file($file);
		
		$fastq_file_of{ident $self} = $file;
		
		return 1;
	}
	
	sub set_output_dir {
		my ($self, $dir) = @_;
		
		if ( ! defined $dir ) {
			$dir = getcwd();
		}
		
		$output_dir_of{ident $self} = $dir;
		
		return 1;
	}
	
	sub set_bad_seqs_file {
		my ($self, $file) = @_;
		
		#if $file is undef the the set value will be undef
		$bad_seqs_file_of{ident $self} = $file;
	}

	##########
	# Others #
	##########
	sub parse_plate_primer_file {
		my ($self) = @_;
		
		# returns a hash with ??
		
		my $file = $self->get_plate_to_primer_file();
		open my $IN, "<", $file or
			MyX::Generic::File::CannotOpen->throw(
				error => "Cannot open file ($file)"
			);
		
		my @vals = ();
		my @fwd_frames = ();
		my @rev_frames = ();
		my %plate_to_frames = ();
		foreach my $line ( <$IN> ) {
			chomp $line;
			@vals = split("\t", $line);
			@fwd_frames = split(",", $vals[1]);
			@rev_frames = split(",", $vals[2]);
			
			foreach my $fwd_frame ( @fwd_frames ) {
				$plate_to_frames{$vals[0]}{$fwd_frame}++;
			}
			foreach my $rev_frame ( @rev_frames ) {
				$plate_to_frames{$vals[0]}{$rev_frame}++;
			}
		}
		close($IN);
		
		#print Dumper(%plate_to_frames);
		
		$plate_to_primers_href_of{ident $self} = \%plate_to_frames;
		
		return(\%plate_to_frames);
	}
	
	sub print_default_params {
		my ($self) = @_;
		
		$self->print_default_fwd_fs_coding();
		$self->print_default_rev_fs_coding();
		$self->print_default_index_href();
		
		return 1;
	}
	
	sub print_default_index_href {
		my ($self) = @_;
		
		print "Default well to index href\n";
		print Dumper(_get_default_index_href());
		
		return 1;
	}
	
	sub print_default_fwd_fs_coding {
		my ($self) = @_;
		
		print "Default fwd frameshift sequences to frameshift code\n";
		print Dumper($fwd_fs_coding_href_of{ident $self});
		
		return 1;
	}
	
	sub print_default_rev_fs_coding {
		my ($self) = @_;
		
		print "Default rev frameshift lengths to frameshift code\n";
		print Dumper($rev_fs_coding_href_of{ident $self});
		
		return 1;
	}
	
	sub _get_default_fwd_fs_coding_href {
		my $href = {
			"TGA"  => "338F_f1_bc1",
			"TTGA" => "338F_f2_bc1",
			"CTTGA"  => "338F_f3_bc1",
			"ACTTGA"  => "338F_f4_bc1",
			"GACTTGA" => "338F_f5_bc1",
			"TGACTTGA"  => "338F_f6_bc1",
			"ACT"  => "338F_f1_bc2",
			"TACT" => "338F_f2_bc2",
			"CTACT"  => "338F_f3_bc2",
			"ACTACT"  => "338F_f4_bc2",
			"GACTACT" => "338F_f5_bc2",
			"TGACTACT"  => "338F_f6_bc2",
		};
		
		return($href);
	}
	
	sub _get_default_rev_fs_coding_href {
		my $href = {
			"5" => "806R_f1",
			"6" => "806R_f2",
			"7" => "806R_f3",
			"8" => "806R_f4",
			"9" => "806R_f5",
			"10" => "806R_f6",
		};
		
		return($href);
	}
	
	sub _get_default_index_href {
		my $href = {
			"A1" => "CGTCGGT",
			"B1" => "GTGTCCA",
			"C1" => "TCCATGC",
			"D1" => "AGGTTCG",
			"E1" => "GTCGAAG",
			"F1" => "ACGGCTG",
			"G1" => "CTATCTG",
			"H1" => "TGGACTC",
			"A2" => "ATTGTGA",
			"B2" => "TGTCGTC",
			"C2" => "CGTTCTA",
			"D2" => "TGTGAAC",
			"E2" => "GGCCTAT",
			"F2" => "GGATATA",
			"G2" => "GCTGAAG",
			"H2" => "CGGTGTC",
			"A3" => "GTCAGCT",
			"B3" => "GCCGACT",
			"C3" => "CTAAGGA",
			"D3" => "TCAGGCC",
			"E3" => "TACTTGC",
			"F3" => "CTTACTA",
			"G3" => "TGATCCT",
			"H3" => "ACGTTCA",
			"A4" => "TCGCACA",
			"B4" => "ACCATCG",
			"C4" => "AAGGCAC",
			"D4" => "GCTAGTT",
			"E4" => "CGCTGAA",
			"F4" => "CACCGAT",
			"G4" => "CATGGAC",
			"H4" => "CATCTTA",
			"A5" => "CTGTAAC",
			"B5" => "GATGATC",
			"C5" => "AGCCGTT",
			"D5" => "TAAGCAT",
			"E5" => "TGTGCGT",
			"F5" => "TGGCTCT",
			"G5" => "CGACCTT",
			"H5" => "AGTGCCA",
			"A6" => "CACTTCT",
			"B6" => "CGCTAGT",
			"C6" => "GGAACGC",
			"D6" => "ATGACTC",
			"E6" => "GTAGGAC",
			"F6" => "GTACGCG",
			"G6" => "AGATGGC",
			"H6" => "ATACGGA",
			"A7" => "GAACGTA",
			"B7" => "AACCAGC",
			"C7" => "GGCGCTT",
			"D7" => "CTTCGCA",
			"E7" => "CGGCTAC",
			"F7" => "CTCTACA",
			"G7" => "GCTTAAT",
			"H7" => "ACCTCAG",
			"A8" => "CGAATCC",
			"B8" => "TAGCAGT",
			"C8" => "GTGACAT",
			"D8" => "CGGCAGA",
			"E8" => "CAGCGTG",
			"F8" => "GTGTATG",
			"G8" => "ACATTGC",
			"H8" => "TCTTCGA",
			"A9" => "GCAACGT",
			"B9" => "GCAGCTC",
			"C9" => "GAGGTTA",
			"D9" => "CATGAAG",
			"E9" => "AGTATGC",
			"F9" => "GATGCCT",
			"G9" => "GCGAATA",
			"H9" => "ATCTGCG",
			"A10" => "AACAGGT",
			"B10" => "TACCATG",
			"C10" => "CCAACTA",
			"D10" => "ATAGTCC",
			"E10" => "TTAAGCG",
			"F10" => "ACGTCCT",
			"G10" => "CAGTAAT",
			"H10" => "TTCCATA",
			"A11" => "TGCACAA",
			"B11" => "CATGAGG",
			"C11" => "ACAGGAG",
			"D11" => "AGCCTTC",
			"E11" => "TGACTAG",
			"F11" => "CGAGTAT",
			"G11" => "CAATGTC",
			"H11" => "GCGTCAC",
			"A12" => "TTATAGG",
			"B12" => "GAGTGCT",
			"C12" => "ACGTCTT",
			"D12" => "TTGTGCA",
			"E12" => "GGCGTTA",
			"F12" => "GTCTCGC",
			"G12" => "TCTTGAC",
			"H12" => "GTGCTAC"
		};
		
		# I want the barcode as the key
		my %nhash = reverse %{$href};
		
		return(\%nhash);
	}
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Demultiplexer::Param_Handler - parameter data and opperations


=head1 VERSION

This document describes Demultiplexer::Param_Handler version 1.0.0


=head1 SYNOPSIS

    use Demultiplexer::Param_Handler;

	# set up the Demultiplexer::Param_Handler
	my $de = Demultiplexer::Param_Handler->new({
		plate_primer_file => $plate_primer_file,
		fastq_file => $fastq_file,
		output_dir => $output_dir
	});

	# to view what some of the default settings are
	$de->print_default_index_href();
	$de->print_default_fwd_fs_coding();
	$de->print_default_rev_fs_coding();
  
  
=head1 DESCRIPTION

There are several pieces of information required by Demultiplexer.  However,
there are also defaults for many of these.  But the defaults may or may not work
for your sequences, so it's important to carefully consider all of the inputs.

First, a fastq file of sequecnes as output from MT-Toolbox are always required.
I recommend always using the all_categorizable_reads.fastq file when
demultiplexing.

Second, a plate_primer_file is always required.  This file is a tab delimited
file with three columns.  The first column is the plate name.  The second column
are the forward frameshift codes used.  The third column are the reverse
frameshift used codes used.  For example:

CL1 338F_f4_bc2,338F_f5_bc2,338F_f6_bc2 806R_f3,806R_f4,806R_f6
CL2 338F_f1_bc1,338F_f2_bc1,338F_f3_bc1 806R_f3,806R_f4,806R_f6
MF1 338F_f4_bc1,338F_f5_bc1,338F_f6_bc1 806R_f1,806R_f2,806R_f3
MF2 338F_f1_bc2,338F_f2_bc2,338F_f3_bc2 806R_f4,806R_f5,806R_f6
PiG1    338F_f1_bc2,338F_f2_bc2,338F_f3_bc2 806R_f1,806R_f2,806R_f3
PiG2    338F_f4_bc1,338F_f5_bc1,338F_f6_bc1 806R_f4,806R_f5,806R_f6

In the above example the forward frameshift primer codes are formatted with the
primer name (e.g. 338F), number of frameshifts (e.g. f4), and frameshift
sequence code (e.g. bc2).  The frameshift sequence code represents the different
frameshift sequences used in the primers (e.g. TGA, TTGA, ACT, TACT, etc).  The
reverse frameshift primers are similar but don't have a frameshift sequence
code.  However, it is possible to design reverse frameshifted primers that also
use the frameshift sequence code.

Third, a index to well mapping file is optionally required.  The default can be
viewed in the code or by calling the function print_default_index_href().  The
file, if provided, should be tab delimited file with two columns.  The first
column is well and the second is the illumina index.  For example:

Sample_Well index
A1  CGTCGGTA
B1  GTGTCCAA
C1  TCCATGCG
D1  AGGTTCGC
E1  GTCGAAGC
F1  ACGGCTGA

Fourth, a forward primer frameshift sequecne to frameshift code mapping file
that is optionally required.  The default can be viewed in the code or by
calling the function print_default_fwd_fs_coding().  This file is a tab
delimited file with two columns.  The first column is the frameshift sequence
and the second is the frameshift code.  For example:

TGA	338F_f1_bc1
TTGA	338F_f2_bc1
CTTGA	338F_f3_bc1

Fifth, a reverse primer frameshift length (or sequence) to frameshift code
mapping file that is optionally required.  The default can be viewed in code or
by calling the function print_default_rev_fs_coding().  This file is a
tab delimited file with two columns.  The first column is the length of the
frameshift and the second is the frameshift code.  For exmaple:

5	806R_f1
6	806R_f2
7	806R_f3


=head1 CONFIGURATION AND ENVIRONMENT

Demultiplexer::Param_Hanlder requires no configuration files or environment variables.


=head1 DEPENDENCIES

Carp
Readonly
Class::Std::Utils
List::MoreUtils qw(any)
Log::Log4perl qw(:easy)
Log::Log4perl::CommandLine qw(:all)
MyX::Generic
version; our $VERSION = qv('1.0.0')
BioUtils::FastqIO
BioUtils::FastaIO
UtilSY qw(:all)
Data::Dumper
Cwd


=head1 INCOMPATIBILITIES

None reported.


=head1 METHODS

new
print_default_params
print_default_index_href
print_default_fwd_fs_coding
print_default_rev_fs_coding
get_plate_to_primer_file
get_plate_to_primer_href
get_index_to_well_file
get_well_from_index
get_fwd_fs_coding_file
get_fwd_fs_coding_href
get_rev_fs_coding_file
get_rev_fs_coding_href
get_fastq_file
get_output_dir
get_bad_seqs_file
set_plate_to_primer_file
set_index_to_well_file
set_index_to_well_href
set_fwd_fs_coding_file
set_fwd_fs_coding_href
set_rev_fs_coding_file
set_rev_fs_coding_href
set_fastq_file
set_output_dir
set_bad_seqs_file

=head1 METHODS DESCRIPTION

=head2 new

	Title: new
	Usage: my $obj = Demultiplexer::Param_Handler->new({
				plate_primer_file => $file,
				fastq_file => $fastq_file,
				[output_dir => ,]
			});
	Function: Creates a new Demultiplexer::Param_Handler object
	Returns: Demultiplexer::Param_Handler
	Args: -plate_primer_file => links plates to frameshifted primers
	      -fastq_file => Fastq file output from MT-Toolbox
		  [-output_dir => Path to output dir]
		  [index_to_well_file => Path to index_to_well file]
		  [fwd_fs_coding_file => Path to fwd frameshift coding file]
		  [rev_fs_coding_file => Path to rev frameshift coding file]
	Throws: MyX::Generic::Undef::Param
	Comments: If no output_dir is provided the current working directory
	          is used.  If the other three optional parameters are not specified
			  the default values stored in this object are used.  To view the
			  default values use the print_
	See Also: NA
	
=head2 print_default_params

	Title: print_default_params
	Usage: $obj->print_default_params();
	Function: Print the default parameters
	Returns: 1 on success
	Args: NA
	Throws: NA
	Comments: Calls the methods print_default_fwd_fs_coding,
	          print_default_rev_fs_coding, and print_default_index_href
	See Also: NA
	
=head2 print_default_index_href

	Title: print_default_index_href
	Usage: $obj->print_default_index_href();
	Function: prints the default well to index href
	Returns: 1 on success
	Args: NA
	Throws: NA
	Comments: Use this function if you need to check the defaults to see if they
	          match your well to illumina index mapping.
	See Also: NA
	
=head2 print_default_fwd_fs_coding

	Title: print_default_fwd_fs_coding
	Usage: $obj->print_default_fwd_fs_coding();
	Function: prints the default fwd frameshift seq to frameshift code mapping
	Returns: 1 on success
	Args: NA
	Throws: NA
	Comments: Use this function if you need to check the defaults to see if they
	          match your forward primer frameshift sequences and codes.
	See Also: NA
	
=head2 print_default_rev_fs_coding

	Title: print_default_rev_fs_coding
	Usage: $obj->print_default_rev_fs_coding();
	Function: prints the default rev frameshift length to frameshift code mapping
	Returns: 1 on success
	Args: NA
	Throws: NA
	Comments: Use this function if you need to check the defaults to see if they
	          match your reverse primer frameshift lengths and codes.
	See Also: NA
	
=head2 get_plate_to_primer_file

	Title: get_plate_to_primer_file
	Usage: $obj->get_plate_to_primer_file()
	Function: Returns path to plate primer file
	Returns: str
	Args: NA
	Throws: NA
	Comments: NA
	See Also: NA
	
=head2 get_plate_to_primer_href

	Title: get_plate_to_primer_href
	Usage: $obj->get_plate_to_primer_href()
	Function: Returns path to plate primer href
	Returns: str
	Args: NA
	Throws: NA
	Comments: NA
	See Also: NA
	
=head2 set_plate_to_primer_file

	Title: set_plate_to_primer_file
	Usage: $obj->set_plate_to_primer_file($file)
	Function: sets the plate_primer_file value
	Returns: 1 on success
	Args: -file => Path to plate primer file
	Throws: MyX::Generic::Undef::Param
	        MyX::Generic::DoesNotExist::File
	        MyX::Generic::File::Empty
	Comments: NA
	See Also: NA
	
=head2 get_index_to_well_file

	Title: get_index_to_well_file
	Usage: $obj->get_index_to_well_file()
	Function: Returns path to optional index to well mapping file
	Returns: str
	Args: NA
	Throws: NA
	Comments: OPTIONAL
	See Also: NA
	
=head2 set_index_to_well_file

	Title: set_index_to_well_file
	Usage: $obj->set_index_to_well_file($file)
	Function: sets the path to the index to well mapping file
	Returns: 1 on success
	Args: -file => Path to file
	Throws: MyX::Generic::Undef::Param
	        MyX::Generic::DoesNotExist::File
	        MyX::Generic::File::Empty
	Comments: NA
	See Also: NA
	
=head2 set_index_to_well_href

	Title: set_index_to_well_href
	Usage: $obj->set_index_to_well_href($file)
	Function: sets the index_to_well_href_of value in the object
	Returns: the href
	Args: -file => Path to index-to-well file
	Throws: MyX::Generic::Undef::Param
	        MyX::Generic::File::CannotOpen
			MyX::Generic::DoesNotExist::File
	        MyX::Generic::File::Empty
	Comments: - This overrides any index_to_well information that is already set
	          in this object.  For example, if you run set_index_to_well_file
			  to load the index_to_well info and then later run
			  set_index_to_well_href with some new index_to_well data then the
			  original index_to_well data is erased.
			  
			  - If a file is not given then the default index_to_well data which
			  is saved in the object will be used.
	See Also: NA
	
=head2 get_well_from_index

	Title: get_well_from_index
	Usage: $obj->get_well_from_index($index)
	Function: Returns the well matching the given index
	Returns: str
	Args: -index => illumina barcode (ie index)
	Throws: MyX::Generic::Undef::Param
	        MyX::Generic::Undef
	Comments: NA
	See Also: NA
	
=head2 get_fwd_fs_coding_file

	Title: get_fwd_fs_coding_file
	Usage: $obj->get_fwd_fs_coding_file()
	Function: Returns the fwd_fs_coding_file
	Returns: str
	Args: NA
	Throws: NA
	Comments: NA
	See Also: NA
	
=head2 set_fwd_fs_coding_file

	Title: set_fwd_fs_coding_file
	Usage: $obj->set_fwd_fs_coding_file($file)
	Function: Sets the file path to the fwd_fs_coding_file
	Returns: NA
	Args: - file => path ot file
	Throws: MyX::Generic::Undef::Param
	        MyX::Generic::DoesNotExist::File
	        MyX::Generic::File::Empty
	Comments: Optional
	See Also: NA
	
=head2 get_fwd_fs_coding_href

	Title: get_fwd_fs_coding_href
	Usage: $obj->get_fwd_fs_coding_href()
	Function: gets the data in fwd_fs_coding_href
	Returns: href
	Args: NA
	Throws: NA
	Comments: NA
	See Also: NA
	
=head2 set_fwd_fs_coding_href

	Title: set_fwd_fs_coding_href
	Usage: $obj->set_fwd_fs_coding_href($href)
	Function: sets the data in fwd_fs_coding_href
	Returns: 1 on success
	Args: -href => href data
	Throws: NA
	Comments: - This overrides any index_to_well information that is already set
	          in this object.  For example, if you run
			  set_fwd_fs_coding_href to load the
			  fwd_fs_coding_href info and then later run
			  set_fwd_fs_coding_href with some new
			  fwd_fs_coding_href data then the
			  original index_to_well data is erased.
			  
			  - If a file is not given then the default
			  fwd_fs_coding_href data which is saved in the object will
			  be used.
	See Also: NA

=head2 get_rev_fs_coding_file

	Title: get_rev_fs_coding_file
	Usage: $obj->get_rev_fs_coding_file()
	Function: Returns the rev_fs_coding_file
	Returns: str
	Args: NA
	Throws: NA
	Comments: NA
	See Also: NA
	
=head2 set_rev_fs_coding_file

	Title: set_rev_fs_coding_file
	Usage: $obj->set_rev_fs_coding_file($file)
	Function: Sets the file path to the rev_fs_coding_file
	Returns: NA
	Args: - file => path ot file
	Throws: MyX::Generic::Undef::Param
	        MyX::Generic::DoesNotExist::File
	        MyX::Generic::File::Empty
	Comments: Optional
	See Also: NA
	
=head2 get_rev_fs_coding_href

	Title: get_rev_fs_coding_href
	Usage: $obj->get_rev_fs_coding_href()
	Function: gets the data in rev_fs_coding_href
	Returns: href
	Args: NA
	Throws: NA
	Comments: NA
	See Also: NA
	
=head2 set_rev_fs_coding_href

	Title: set_rev_fs_coding_href
	Usage: $obj->set_rev_fs_coding_href($href)
	Function: sets the data in rev_fs_coding_href
	Returns: 1 on success
	Args: -href => href data
	Throws: NA
	Comments: - This overrides any index_to_well information that is already set
	          in this object.  For example, if you run
			  set_rev_fs_coding_href to load the
			  rev_fs_coding_href info and then later run
			  set_rev_fs_coding_href with some new
			  rev_fs_coding_href data then the
			  original index_to_well data is erased.
			  
			  - If a file is not given then the default
			  rev_fs_coding_href data which is saved in the object will
			  be used.
	See Also: NA
	
=head2 parse_plate_primer_file
	
	Tilte: parse_plate_primer_file
	Usage: $obj->parse_plate_primer_file()
	Function: Parse the plate primer file and return that info in a hash ref
	Returns: Href
	Args: NA
	Throws: MyX::Generic::File::CannotOpen
	Comments: NA
	See Also: NA
	
=head2 get_fastq_file

	Title: get_fastq_file
	Usage: $obj->get_fastq_file()
	Function: Returns path to FASTQ file output from MT-Toolbox
	Returns: str
	Args: NA
	Throws: NA
	Comments: NA
	See Also: NA
	
=head2 set_fastq_file

	Title: set_fastq_file
	Usage: $obj->set_fastq_file($file)
	Function: sets the path to the FASTQ file output from MT-Toolbox
	Returns: 1 on success
	Args: -file => Path to FASTQ file
	Throws: MyX::Generic::Undef::Param
	        MyX::Generic::DoesNotExist::File
	        MyX::Generic::File::Empty
	Comments: NA
	See Also: NA
	
=head2 get_output_dir

	Title: get_output_dir
	Usage: $obj->get_output_dir()
	Function: Returns path to the output directory
	Returns: str
	Args: NA
	Throws: NA
	Comments: NA
	See Also: NA
	
=head2 set_output_dir

	Title: set_output_dir
	Usage: $obj->set_output_dir($dir)
	Function: Sets the path to the output directory
	Returns: 1 on success
	Args: -dir => Path to output directory
	Throws: NA
	Comments: If no output_dir parameter is provided in the new function
	          the defualt output_dir is the current working directory.
	See Also: NA
	
=head2 set_bad_seqs_file

	Title: set_bad_seqss_file
	Usage: $obj->set_bad_seqss_file($file)
	Function: Sets the path to the bad seqs output file
	Returns: 1 on success
	Args: -file => Path to output bad seqs file
	Throws: NA
	Comments: If no file is set in the object then no bad sequences are printed.
	          Bad sequences are sequences that cannot be assigned to a sample.
	See Also: NA
	
=head2 get_bad_seqs_file

	Title: get_bad_seqs_file
	Usage: $obj->get_bad_seqs_file();
	Function: Gets the output file path for the bad seqs
	Returns: str or undef
	Args: NA
	Throws: NA
	Comments: if the bad seqs file is not set then the bad seqs will not be
	          printed.
	See Also: NA


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 TO DO

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

