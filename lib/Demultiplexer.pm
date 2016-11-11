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

# set up the logging environment
my $logger = get_logger();

{
	# Usage statement
	Readonly my $NEW_USAGE => q{ new( {
		plate_primer_file => ,
		fastq_file => ,
		[output_dir => ,]
	})};

	# Attributes #
	my %plate_primer_file_of;
	my %plate_to_primers_href_of;
	my %index_to_well_file_of;
	my %index_to_well_href_of;
	my %fwd_fs_seq_to_fs_code_file_of;
	my %fwd_fs_seq_to_fs_code_href_of;
	my %rev_fs_len_to_fs_code_file_of;
	my %rev_fs_len_to_fs_code_href_of;
	my %fastq_file_of;
	my %output_dir_of;
	
	# Getters #
	sub get_plate_primer_file;
	sub get_index_to_well_file;
	sub get_fwd_fs_seq_to_fs_code_file;
	sub get_fwd_fs_seq_to_fs_code_href;
	sub get_rev_fs_len_to_fs_code_file;
	sub get_rev_fs_len_to_fs_code_href;
	sub get_well_from_index;
	sub get_fastq_file;
	sub get_output_dir;

	# Setters #
	sub set_plate_primer_file;
	sub set_index_to_well_file;
	sub set_index_to_well_href;
	sub set_fwd_fs_seq_to_fs_code_file;
	sub set_fwd_fs_seq_to_fs_code_href;
	sub set_rev_fs_len_to_fs_code_file;
	sub set_rev_fs_len_to_fs_code_href;
	sub set_fastq_file;
	sub set_output_dir;

	# Others #
	sub demultiplex;
	sub print_default_index_href;
	sub print_default_fwd_fs_seq_to_fs_code;
	sub print_default_rev_fs_len_to_fs_code;


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
		$self->set_plate_primer_file($arg_href->{plate_primer_file});		
		$self->parse_plate_primer_file();
		$self->set_fastq_file($arg_href->{fastq_file});
		$self->set_output_dir($arg_href->{output_dir});
		
		my $file = $arg_href->{index_to_well_file};
		if ( defined $file ) {
			$self->set_index_to_well_file($file);
			$self->set_index_to_well_href($file);
		}
		else {
			$self->set_index_to_well_href();
		}
		
		$file = $arg_href->{fwd_fs_seq_to_fs_code_file};
		if ( defined $file ) {
			$self->set_fwd_fs_seq_to_fs_code_file($file);
			$self->set_fwd_fs_seq_to_fs_code_href($file);
		}
		else {
			$self->set_fwd_fs_seq_to_fs_code_href();
		}
		
		$file = $arg_href->{rev_fs_len_to_fs_code_file};
		if ( defined $file ) {
			$self->set_rev_fs_len_to_fs_code_file($file);
			$self->set_rev_fs_len_to_fs_code_href($file);
		}
		else {
			$self->set_rev_fs_len_to_fs_code_href();
		}
	}

	###########
	# Getters #
	###########
	sub get_plate_primer_file {
		my ($self) = @_;
		
		return $plate_primer_file_of{ident $self};
	}
	
	sub get_well_from_index {
		my ($self, $index) = @_;
		
		is_defined($index);
		
		my $well;
		if ( defined $index_to_well_href_of{ident $self}->{$index} ) {
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
	
	sub get_index_to_well_file {
		my ($self) = @_;
		
		return $index_to_well_file_of{ident $self};
	}
	
	sub get_fwd_fs_seq_to_fs_code_file {
		my ($self) = @_;
		
		return $fwd_fs_seq_to_fs_code_file_of{ident $self};
	}
	
	sub get_rev_fs_len_to_fs_code_file {
		my ($self) = @_;
		
		return $rev_fs_len_to_fs_code_file_of{ident $self};
	}
	
	sub get_fastq_file {
		my ($self) = @_;
		
		return $fastq_file_of{ident $self};
	}
	
	sub get_output_dir {
		my ($self) = @_;
		
		return $output_dir_of{ident $self};
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
	
	sub set_fwd_fs_seq_to_fs_code_file {
		my ($self, $file) = @_;
		
		# check if the parameter is defined
		is_defined($file, "file");
		
		# check if the file exists and is non empty
		check_file($file);
		
		$fwd_fs_seq_to_fs_code_file_of{ident $self} = $file;
		
		return 1;
	}
	
	sub set_fwd_fs_seq_to_fs_code_href {
		my ($self, $file) = @_;
		
		# note: this overrides any inforamtion that is already set in this
		# object.
		
		my $href;
		
		# save the file
		eval { $self->set_fwd_fs_seq_to_fs_code_file($file) };
		if ( my $e = Exception::Class->caught('MyX::Generic::Undef::Param') ) {
			$href = _get_default_fwd_seq_code_to_fs_code_href();
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
		
		$fwd_fs_seq_to_fs_code_href_of{ident $self} = $href;
		
		return($href);
	}
	
	sub set_rev_fs_len_to_fs_code_file {
		my ($self, $file) = @_;
		
		# check if the parameter is defined
		is_defined($file, "file");
		
		# check if the file exists and is non empty
		check_file($file);
		
		$rev_fs_len_to_fs_code_file_of{ident $self} = $file;
		
		return 1;
	}
	
	sub set_rev_fs_len_to_fs_code_href {
		my ($self, $file) = @_;
		
		# note: this overrides any inforamtion that is already set in this
		# object.
		
		my $href;
		
		# save the file
		eval { $self->set_rev_fs_len_to_fs_code_file($file) };
		if ( my $e = Exception::Class->caught('MyX::Generic::Undef::Param') ) {
			$href = _get_default_rev_len_code_to_fs_code_href();
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
		
		$rev_fs_len_to_fs_code_href_of{ident $self} = $href;
		
		return($href);
	}
	
	sub set_fastq_file {
		my ($self, $file) = @_;
		
		is_defined($file);
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
		my $in = BioUtils::FastqIO->new( {stream_type => '<',
										  file => $self->get_fastq_file()} );

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
		
		my $href = $plate_to_primers_href_of{ident $self};
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
		my $lookup_href = $fwd_fs_seq_to_fs_code_href_of{ident $self};
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
		my $lookup_href = $rev_fs_len_to_fs_code_href_of{ident $self};
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
	
	sub parse_plate_primer_file {
		my ($self) = @_;
		
		# returns a hash with ??
		
		my $file = $self->get_plate_primer_file();
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
	
	sub print_default_fwd_fs_seq_to_fs_code {
		my ($self) = @_;
		
		print "Default fwd frameshift sequences to frameshift code\n";
		print Dumper($fwd_fs_seq_to_fs_code_href_of{ident $self});
		
		return 1;
	}
	
	sub print_default_rev_fs_len_to_fs_code {
		my ($self) = @_;
		
		print "Default rev frameshift lengths to frameshift code\n";
		print Dumper($rev_fs_len_to_fs_code_href_of{ident $self});
		
		return 1;
	}
	
	sub print_default_index_href {
		my ($self) = @_;
		
		print "Default well to index href\n";
		print Dumper(_get_default_index_href());
		
		return 1;
	}
	
	sub _get_default_fwd_seq_code_to_fs_code_href {
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
	
	sub _get_default_rev_len_code_to_fs_code_href {
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

Demultiplexer - demultiplexes frameshifted primers from MTToolbox output


=head1 VERSION

This document describes Demultiplexer version 0.0.1


=head1 SYNOPSIS

    use Demultiplexer;

	# set up the Demultiplexer
	my $de = Demultiplexer->new({
		plate_primer_file => $plate_primer_file,
		fastq_file => $fastq_file,
		output_dir => $output_dir
	});
	
	# demultiplex
	$de->demultiplex()
	
	# to view what some of the default settings are
	$de->print_default_index_href();
	$de->print_default_fwd_fs_seq_to_fs_code();
	$de->print_default_rev_fs_len_to_fs_code();
  
  
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
calling the function print_default_fwd_fs_seq_to_fs_code().  This file is a tab
delimited file with two columns.  The first column is the frameshift sequence
and the second is the frameshift code.  For example:

TGA	338F_f1_bc1
TTGA	338F_f2_bc1
CTTGA	338F_f3_bc1

Fifth, a reverse primer frameshift length (or sequence) to frameshift code
mapping file that is optionally required.  The default can be viewed in code or
by calling the function print_default_rev_fs_len_to_fs_code().  This file is a
tab delimited file with two columns.  The first column is the length of the
frameshift and the second is the frameshift code.  For exmaple:

5	806R_f1
6	806R_f2
7	806R_f3


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


=head1 INCOMPATIBILITIES

None reported.


=head1 METHODS

new
demultiplex
print_default_index_href
print_default_fwd_fs_seq_to_fs_code
print_default_rev_fs_len_to_fs_code
get_plate_primer_file
set_plate_primer_file
get_index_to_well_file
set_index_to_well_file
set_index_to_well_href
get_well_from_index
get_fwd_fs_seq_to_fs_code_file
set_fwd_fs_seq_to_fs_code_file
get_fwd_fs_seq_to_fs_code_href
set_fwd_fs_seq_to_fs_code_href
get_rev_fs_len_to_fs_code_file
set_rev_fs_len_to_fs_code_file
get_rev_fs_len_to_fs_code_href
set_rev_fs_len_to_fs_code_href
get_fastq_file
set_fastq_file
get_output_dir
set_output_dir

=head1 METHODS DESCRIPTION

=head2 new

	Title: new
	Usage: my $obj = Demultiplexer->new({
				plate_primer_file => $file,
				fastq_file => $fastq_file,
				[output_dir => ,]
			});
	Function: Creates a new Demultiplexer object
	Returns: Demultiplexer
	Args: -plate_primer_file => links plates to frameshifted primers
	      -fastq_file => Fastq file output from MT-Toolbox
	Throws: MyX::Generic::Undef::Param
	Comments: If no output_dir is provided the current working directory
	          is used.
	See Also: NA
	
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
	
=head2 print_default_fwd_fs_seq_to_fs_code

	Title: print_default_fwd_fs_seq_to_fs_code
	Usage: $obj->print_default_fwd_fs_seq_to_fs_code();
	Function: prints the default fwd frameshift seq to frameshift code mapping
	Returns: 1 on success
	Args: NA
	Throws: NA
	Comments: Use this function if you need to check the defaults to see if they
	          match your forward primer frameshift sequences and codes.
	See Also: NA
	
=head2 print_default_rev_fs_len_to_fs_code

	Title: print_default_rev_fs_len_to_fs_code
	Usage: $obj->print_default_rev_fs_len_to_fs_code();
	Function: prints the default rev frameshift length to frameshift code mapping
	Returns: 1 on success
	Args: NA
	Throws: NA
	Comments: Use this function if you need to check the defaults to see if they
	          match your reverse primer frameshift lengths and codes.
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
	
=head2 get_fwd_fs_seq_to_fs_code_file

	Title: get_fwd_fs_seq_to_fs_code_file
	Usage: $obj->get_fwd_fs_seq_to_fs_code_file()
	Function: Returns the fwd_fs_seq_to_fs_code_file
	Returns: str
	Args: NA
	Throws: NA
	Comments: NA
	See Also: NA
	
=head2 set_fwd_fs_seq_to_fs_code_file

	Title: set_fwd_fs_seq_to_fs_code_file
	Usage: $obj->set_fwd_fs_seq_to_fs_code_file($file)
	Function: Sets the file path to the fwd_fs_seq_to_fs_code_file
	Returns: NA
	Args: - file => path ot file
	Throws: MyX::Generic::Undef::Param
	        MyX::Generic::DoesNotExist::File
	        MyX::Generic::File::Empty
	Comments: Optional
	See Also: NA
	
=head2 get_fwd_fs_seq_to_fs_code_href

	Title: get_fwd_fs_seq_to_fs_code_href
	Usage: $obj->get_fwd_fs_seq_to_fs_code_href()
	Function: gets the data in fwd_fs_seq_to_fs_code_href
	Returns: href
	Args: NA
	Throws: NA
	Comments: NA
	See Also: NA
	
=head2 set_fwd_fs_seq_to_fs_code_href

	Title: set_fwd_fs_seq_to_fs_code_href
	Usage: $obj->set_fwd_fs_seq_to_fs_code_href($href)
	Function: sets the data in fwd_fs_seq_to_fs_code_href
	Returns: 1 on success
	Args: -href => href data
	Throws: NA
	Comments: - This overrides any index_to_well information that is already set
	          in this object.  For example, if you run
			  set_fwd_fs_seq_to_fs_code_href to load the
			  fwd_fs_seq_to_fs_code_href info and then later run
			  set_fwd_fs_seq_to_fs_code_href with some new
			  fwd_fs_seq_to_fs_code_href data then the
			  original index_to_well data is erased.
			  
			  - If a file is not given then the default
			  fwd_fs_seq_to_fs_code_href data which is saved in the object will
			  be used.
	See Also: NA

=head2 get_rev_fs_len_to_fs_code_file

	Title: get_rev_fs_len_to_fs_code_file
	Usage: $obj->get_rev_fs_len_to_fs_code_file()
	Function: Returns the rev_fs_len_to_fs_code_file
	Returns: str
	Args: NA
	Throws: NA
	Comments: NA
	See Also: NA
	
=head2 set_rev_fs_len_to_fs_code_file

	Title: set_rev_fs_len_to_fs_code_file
	Usage: $obj->set_rev_fs_len_to_fs_code_file($file)
	Function: Sets the file path to the rev_fs_len_to_fs_code_file
	Returns: NA
	Args: - file => path ot file
	Throws: MyX::Generic::Undef::Param
	        MyX::Generic::DoesNotExist::File
	        MyX::Generic::File::Empty
	Comments: Optional
	See Also: NA
	
=head2 get_rev_fs_len_to_fs_code_href

	Title: get_rev_fs_len_to_fs_code_href
	Usage: $obj->get_rev_fs_len_to_fs_code_href()
	Function: gets the data in rev_fs_len_to_fs_code_href
	Returns: href
	Args: NA
	Throws: NA
	Comments: NA
	See Also: NA
	
=head2 set_rev_fs_len_to_fs_code_href

	Title: set_rev_fs_len_to_fs_code_href
	Usage: $obj->set_rev_fs_len_to_fs_code_href($href)
	Function: sets the data in rev_fs_len_to_fs_code_href
	Returns: 1 on success
	Args: -href => href data
	Throws: NA
	Comments: - This overrides any index_to_well information that is already set
	          in this object.  For example, if you run
			  set_rev_fs_len_to_fs_code_href to load the
			  rev_fs_len_to_fs_code_href info and then later run
			  set_rev_fs_len_to_fs_code_href with some new
			  rev_fs_len_to_fs_code_href data then the
			  original index_to_well data is erased.
			  
			  - If a file is not given then the default
			  rev_fs_len_to_fs_code_href data which is saved in the object will
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

