use strict;
use warnings;

use Test::More tests => 19;
use Test::Exception;

# others to include
use File::Temp qw/ tempfile tempdir /;
use Cwd;
use BioUtils::FastaSeq;
use File::Basename;

# get the directory of this script so I will know where the test data files
# are located
my $test_dir = dirname(__FILE__);


BEGIN { use_ok( 'Demultiplexer' ); }
BEGIN { use_ok( 'Demultiplexer::Param_Handler'); }

my $plate_primer_file = "$test_dir/data/plate_primer_meta.txt";
my $index_to_well_file = "$test_dir/data/index_to_well.txt";
my $fastq_file = "$test_dir/data/mttoolbox_output.fastq";
my $fwd_fs_seq = "$test_dir/data/fwd_fs_seq_to_fs_code.txt";
my $rev_fs_len = "$test_dir/data/rev_fs_len_to_fs_code.txt";
my $tmp_dir = tempdir();

# make a Demultiplex::Param_Handler for testing
my $ph;
lives_ok(sub {
    $ph = Demultiplexer::Param_Handler->new({
        plate_primer_file => $plate_primer_file,
        fastq_file => $fastq_file,
        output_dir => $tmp_dir
    })
}, "expected to live -- making Demultiplexer::Param_Handler object" );

# test constructor
my $de;
throws_ok(sub{ $de = Demultiplexer->new() },
          'MyX::Generic::Undef::Param',
          "caught - Demultiplexer->new()" );
lives_ok(sub{ $de = Demultiplexer->new({
                        param_handler => $ph}) },
         "expected to live - constructor" );


# test _get_count_id
{
    my $header = "\@P0_77775 CCGTTGACTACTACCT-TCAAGTCATG UNC20:346:000000000-AWCC2:1:2108:6913:19538 1:N:0:GATGCCTT";
    is( Demultiplexer::_get_count_id($header), "77775", "_get_count_id()" );
}

# test _get_fwd_fs
{
    my $header = "\@P0_77775 CCGTTGACTACTACCT-TCAAGTCATG UNC20:346:000000000-AWCC2:1:2108:6913:19538 1:N:0:GATGCCTT";
    is( Demultiplexer::_get_fwd_fs($header), "CCGTTGACTACTACCT", "_get_fwd_fs()" );
}

# test _get_rev_fs
{
    my $header = "\@P0_77775 CCGTTGACTACTACCT-TCAAGTCATG UNC20:346:000000000-AWCC2:1:2108:6913:19538 1:N:0:GATGCCTT";
    is( Demultiplexer::_get_rev_fs($header), "TCAAGTCATG", "_get_rev_fs()" );
}

# test _get_index
{
    my $header = "\@P0_77775 CCGTTGACTACTACCT-TCAAGTCATG UNC20:346:000000000-AWCC2:1:2108:6913:19538 1:N:0:GATGCCTT";
    is( Demultiplexer::_get_index($header), "GATGCCT", "_get_index()" );
}

# test _get_fwd_query
{
    my $fwd_fs = "CCGTTGACTACTACCT";
    is( Demultiplexer::_get_fwd_query($fwd_fs), "TGACTACT", "_get_fwd_query()" );
}

# test _get_plate
{
    my $fwd_match = "338F_f6_bc2";
    my $rev_match = "806R_f3";
    is( $de->_get_plate($fwd_match, $rev_match), "CL1", "_get_plate()" );
}

# test _add_seq
{
    my $seq_href = {};
    
    lives_ok(sub{ Demultiplexer::_add_seq(1, $seq_href, "A") },
             "expected to live - _add_seq" );
    is_deeply( $seq_href->{"A"}, [1], "check what I just added" );
}

# test _update_seq_id
{
    my $header = "P0_77775 CCGTTGACTACTACCT-TCAAGTCATG UNC20:346:000000000-AWCC2:1:2108:6913:19538 1:N:0:GATGCCTT";
    my $new_header = "pAwB_10 CCGTTGACTACTACCT-TCAAGTCATG UNC20:346:000000000-AWCC2:1:2108:6913:19538 1:N:0:GATGCCTT";
    my $seq = BioUtils::FastaSeq->new({
        header => $header,
        seq => "ATCTG"
    });

    lives_ok(sub{ Demultiplexer::_update_seq_id($seq, "A", "B", "10") },
             "expected to live - _update_seq_id");
    is($seq->get_header(), $new_header, "check _update_seq_id for correctness" );
}

# test _get_out_file_name
{
    is(Demultiplexer::_get_out_file_name("test", "PiG1A1"),
       "test/pPiG1wA1.fasta", "_get_out_file_name(PiG1A1)" );
    is(Demultiplexer::_get_out_file_name("test", "AA1"),
       "test/pAwA1.fasta", "_get_out_file_name(AA1)" );
    is(Demultiplexer::_get_out_file_name("test", "1A1"),
       "test/p1wA1.fasta", "_get_out_file_name(1A1)" );
    is(Demultiplexer::_get_out_file_name("test", "CL2G11"),
       "test/pCL2wG11.fasta", "_get_out_file_name(CL2G11)" );
}

# test demultiplex
{
    #$de->demultiplex();
    ;
}

# test when a custom index to well file is used
{
    ;
    # I'm pretty sure this works, but I should write test code later
}

# test when a custom fwd_fs_seq_to_fs_code file is used
{
    ;
    # I'm pretty sure this works, but I should write test code later
}

# test when a custom rev_fs_len_to_fs_code file is used
{
    ;
    # I'm pretty sure this works, but I should write test code later
}


