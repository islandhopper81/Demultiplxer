#!/usr/bin/env perl

# Demultiplex the output from MT-Toolbox

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use Carp;
use Readonly;
use version; our $VERSION = qv('1.0.0');
use Log::Log4perl qw(:easy);
use Log::Log4perl::CommandLine qw(:all);
use Cwd;
use UtilSY 0.0.2 qw(:all);
use Demultiplexer;
use Demultiplexer::Param_Handler;


# Subroutines #
sub check_params;

# Variables #
my ($plate_primer_file, $fastq_file, $output_dir, $bad_seqs_file,
	$index_to_well_file, $fwd_fs_coding_file, $rev_fs_coding_file,
	$help, $man);

my $options_okay = GetOptions (
    "plate_primer_file|p:s" => \$plate_primer_file,
    "fastq_file|f:s" => \$fastq_file,
	"output_dir|o:s" => \$output_dir,
	"bad_seqs_file|b:s" => \$bad_seqs_file,
	"index_to_well_file:s" => \$index_to_well_file,
	"fwd_fs_coding_file:s" => \$fwd_fs_coding_file,
	"rev_fs_coding_file:s" => \$rev_fs_coding_file,
    "help|h" => \$help,                  # flag
    "man" => \$man,                     # flag (print full man page)
);

# set up the logging environment
my $logger = get_logger();

# check for input errors
if ( $help ) { pod2usage(0) }
if ( $man ) { pod2usage(-verbose => 3) }
check_params();


########
# MAIN #
########
$logger->debug("Build Demultiplex::Param_Handler Object");
my $ph = Demultiplexer::Param_Handler->new({
	plate_primer_file => $plate_primer_file,
    fastq_file => $fastq_file,
	output_dir => $output_dir,
	bad_seqs_file => $bad_seqs_file,
	index_to_well_file => $index_to_well_file,
	fwd_fs_coding_file => $fwd_fs_coding_file,
	rev_fs_coding_file => $rev_fs_coding_file
});

$logger->debug("Build Demultiplex Object");
my $de = Demultiplexer->new({
    param_handler => $ph
});

$logger->info("Begin demultiplexing");
$de->demultiplex();
$logger->info("Finished demultiplexing");


########
# Subs #
########
sub check_params {
	# check for required variables
    if ( ! defined $plate_primer_file ) {
		pod2usage(-message => "ERROR: required --plate_primer_file not defined\n\n",
					-exitval => 2);
	}
	if ( ! defined $fastq_file) { 
		pod2usage(-message => "ERROR: required --fastq_file not defined\n\n",
					-exitval => 2); 
	}

	# make sure required files are non-empty
	if ( defined $fastq_file and ! -e $fastq_file ) { 
		pod2usage(-message => "ERROR: --fastq_file $fastq_file is an empty file\n\n",
					-exitval => 2);
	}
    if ( defined $plate_primer_file and ! -e $plate_primer_file ) { 
		pod2usage(-message => "ERROR: --plate_primer_file $plate_primer_file is an empty file\n\n",
					-exitval => 2);
	}
	
	# create and/or check the output dir
	if ( ! is_defined($output_dir) ) {
		$output_dir = getcwd();
	}
	if ( ! -d $output_dir ) { 
		pod2usage(-message => "ERROR: --output_dir is not a directory\n\n",
					-exitval => 2); 
	}
	
	return 1;
}


__END__

# POD

=head1 NAME

demultiplex.pl - Demultiplex the output from MT-Toolbox


=head1 VERSION

This documentation refers to version 1.0.0


=head1 SYNOPSIS

    demultiplex.pl
        -p plate_primer_file.txt
        -f my_seqs.fastq
        -o output_dir/
        -b bad_sequences.fastq
        --index_to_well_file index_to_well.txt
        --fwd_fs_coding_file fwd_fs_coding.txt
        --rev_fs_coding_file rev_fs_coding.txt
        
        [--help]
        [--man]
        [--debug]
        [--verbose]
        [--quiet]
        [--logfile logfile.log]

    --plate_primer_file | -p     Path to plate primer file
    --fastq_file | -f            Path to an input fastq file
    --output_dir | -o            Path to the output directory
    --bad_seqs_file | -b         Path to where the bad sequences will be printed
    --index_to_well_file         Path to the index to well file
    --fwd_fs_coding_file         Path to forward frameshift coding file
    --rev_fs_coding_file         Path to reverse frameshift coding file
    --help | -h                  Prints USAGE statement
    --man                        Prints the man page
    --debug	                     Prints Log4perl DEBUG+ messages
    --verbose                    Prints Log4perl INFO+ messages
    --quiet	                     Suppress printing ERROR+ Log4perl messages
    --logfile                    File to save Log4perl messages


=head1 ARGUMENTS
    
=head2 --plate_primer_file | -p

Path to a the plate primer file.  This is a tab delimited file with three
columns.  

The first column is the plate name.  This is specified by the user
and can be anything.  Each plate name must be unique.  The second column
is the code used to specify the forward barcodes.  The third column are
the reverse primers used.  

For example:

	CL1 338F_f4_bc2,338F_f5_bc2,338F_f6_bc2 806R_f3,806R_f4,806R_f6
	CL2 338F_f1_bc1,338F_f2_bc1,338F_f3_bc1 806R_f3,806R_f4,806R_f6
	MF1 338F_f4_bc1,338F_f5_bc1,338F_f6_bc1 806R_f1,806R_f2,806R_f3
	MF2 338F_f1_bc2,338F_f2_bc2,338F_f3_bc2 806R_f4,806R_f5,806R_f6
	PiG1    338F_f1_bc2,338F_f2_bc2,338F_f3_bc2 806R_f1,806R_f2,806R_f3
	PiG2    338F_f4_bc1,338F_f5_bc1,338F_f6_bc1 806R_f4,806R_f5,806R_f6

In the above example the forward frameshift primer codes are formatted with the
primer name (e.g. 338F), number of frameshifts (e.g. f4), and frameshift
sequence code (e.g. bc2).  Each comma seperated value is used to retrieve the
frameshift  sequences used in the primers (e.g. TGA, TTGA, ACT, TACT, etc) and
is specified in the --fwd_fs_coding_file file.  The defaults used in the Dangl
lab will be used if no --fwd_fs_coding_file file is specified.  These defualts
are shown in the documentation for the --fwd_fs_coding_file parameter below.  
The values in this second column of the plate_primer_file must match something
in the second column of the fwd_fs_coding_file. The reverse frameshift primers
 are similar but don't have a frameshift sequence. They simply match to a 
length.  So fwd frameshifts can be sequence and length specific, but rev 
frameshifts are only length specific.  

=head2 --fastq_file | -f

Path to an input fastq file.  This file is likely output from MT-Toolbox. The
MT-Toolbox file that most users will input here is the
all_categorizable_reads.fastq file.  Note that the Demultiplexer.pl changes the
IDs of the sequences when they are output.  The IDs in the --fastq_file will not
change, but it could be difficult to directly connect the output sequences with
the input sequences.  If this is a problem please email me and I will resolve it
for you.

=head2 --output_dir | -o

Path to a directory where output files will be printed.  If no directory is
specified the current working directory is used.

=head2 --bad_seqs_file | -b

Path to a file where the bad sequences can be printed.  They are printed in the
fastq format.

=head2 --index_to_well_file

Path to file mapping the illumina index sequences to the plate wells.  The
index sequence is included in the headers of the sequence file as it was 
output from MTToolbox.  The sequence is used to lookup the sample well.  The
sample well is printed in the sequence header along with the plate ID when the
sequences are output.  Remember the plate IDs come from the 
--plate_primer_file.  So a demultiplex sequence might have a header that 
starts with something like "pCL1wA1".  For example here are the first few lines
of the Dangl lab index_to_well_file:

	Sample_Well index
	A1  CGTCGGTA
	B1  GTGTCCAA
	C1  TCCATGCG
	D1  AGGTTCGC
	E1  GTCGAAGC
	F1  ACGGCTGA

=head2 --fwd_fs_coding_file

Path to file with the forward frameshift information and the corresponding
codes.  The first column is the framshift sequence and the second is the
frameshift code. The defaults used in the Dangl lab are shown in the example
below:

	AGT 338F_f1_bc1
	AGTC    338F_f2_bc1
	AGTCA   338F_f1_bc2

=head2 --rev_fs_coding_file

Path to file with the reverse frameshift information and the corresponding
codes.  In this case the first column is the length of the frameshift and the
second is the corresponding code.  The defaults used in the Dangl lab are 
shown in the example below:

	0   806R_f1
	1   806R_f2
	2   806R_f3
 
=head2 [--help | -h]
    
An optional parameter to print a usage statement.

=head2 [--man]

An optional parameter to print he entire man page (i.e. all documentation)

=head2 [--debug]

Prints Log4perl DEBUG+ messages.  The plus here means it prints DEBUG
level and greater messages.

=head2 [--verbose]

Note that this flag prints useful summary information!  Prints Log4perl INFO+
messages.  The plus here means it prints INFO level and greater messages.

=head2 [--quiet]

Suppresses print ERROR+ Log4perl messages.  The plus here means it suppresses
ERROR level and greater messages that are automatically printed.

=head2 [--logfile]

File to save Log4perl messages.  Note that messages will also be printed to
STDERR.
    

=head1 DESCRIPTION

This script runs a demultiplexing job.  The Dangl lab uses frameshifted primers
to include more than 96 samples on a 16S sequencing metagenome profiling.  Of
course, when we do the actual sequencing we can only use the 96 illumina
barcodes.  But based on the frameshifted primers we can further split the 96
samples into their subsamples.

Typically this script is ran on one of the output files from MT-Toolbox
(usually the all_categorizable_reads.fastq file).

Include the --verbose flag to print read count summary information.


=head1 CONFIGURATION AND ENVIRONMENT
    
No special configurations or environment variables needed
    
    
=head1 DEPENDANCIES

version
Getopt::Long
Pod::Usage
Carp
Readonly
version
Log::Log4perl qw(:easy)
Log::Log4perl::CommandLine qw(:all)
Cwd
UtilSY 0.0.2 qw(:all)
Demultiplexer


=head1 AUTHOR

Scott Yourstone     scott.yourstone81@gmail.com
    
    
=head1 LICENCE AND COPYRIGHT

Copyright (c) 2015, Scott Yourstone
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


=cut
