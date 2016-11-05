use strict;
use warnings;

use Test::More tests => 28;
use Test::Exception;

# others to include
use File::Temp qw/ tempfile tempdir /;
use Cwd;
use BioUtils::FastaSeq;

# helper subroutines


BEGIN { use_ok( 'Demultiplexer' ); }

my $plate_primer_file = "data/plate_primer_meta.txt";
my $index_to_well_file = "data/index_to_well.txt";
my $fastq_file = "data/mttoolbox_output.fastq";

# test constructor
my $de;
throws_ok(sub{ $de = Demultiplexer->new() },
          'MyX::Generic::Undef::Param',
          "caught - Demultiplexer->new()" );
throws_ok(sub{ $de = Demultiplexer->new({
                        plate_primer_file => $plate_primer_file}) },
          'MyX::Generic::Undef::Param',
          "caught - Demultiplexer->new(missing fastq_file)" );
throws_ok(sub{ $de = Demultiplexer->new({
    plate_primer_file => $plate_primer_file,
    fastq_file => "blah"
}) },
        'MyX::Generic::DoesNotExist::File',
        "caught - Demultiplexer->new(bad fastq_file)" );
lives_ok(sub{ $de = Demultiplexer->new({
                        plate_primer_file => $plate_primer_file,
                        fastq_file => $fastq_file}) },
         "expected to live - constructor" );

# test get_output_dir
{
    is( $de->get_output_dir(), getcwd(), "get_output_dir(DEFAULT)" );
}

# test set_output_dir
{
    my $tmp_dir = tempdir();
    lives_ok(sub{ $de->set_output_dir($tmp_dir) },
             "expected to live - set_output_dir($tmp_dir)" );
    is( $de->get_output_dir(), $tmp_dir, "was the dir set correctly" );
}

# test get_plate_primer_file
{
    is( $de->get_plate_primer_file(),
       $plate_primer_file,
       "get_plate_primer_file()");
}

# test get_fastq_file
{
    is( $de->get_fastq_file(), $fastq_file, "get_fastq_file()");
}

# test set_metadata_file
{
    ;
}

# test get_metadata_file
{
    ;
}

# test set_index_to_well_file
{
    throws_ok(sub{ $de->set_index_to_well_file() },
                  'MyX::Generic::Undef::Param',
                  "caught - set_index_to_well_file()" );
    lives_ok(sub{ $de->set_index_to_well_file($index_to_well_file) },
             "expect to live - set_index_to_well_file(file)" );
}

# test get_index_to_well_file
{
    is( $de->get_index_to_well_file(), $index_to_well_file,
       "get_index_to_well_file()" );
}

# test set_index_to_well_href
{
    lives_ok(sub{ $de->set_index_to_well_href($index_to_well_file) },
             "expected to live - set_index_to_well_href" );
}

# test get_well_from_index
{
    is( $de->get_well_from_index("CGTCGGT"),
       "A1",
       "get_well_from_index(CGTCGGT)" );
}

# test parse_plate_primer_file
{
    my $primer_to_frames;
    lives_ok(sub{ $primer_to_frames = $de->parse_plate_primer_file() },
             "expected to live - parse_plate_primer_file" );
    is ( $primer_to_frames->{"CL1"}{"338F_f4_bc2"}, 1,
        "get primer frame {CL1}{338F_f4_bc2}" );
}

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

# test _get_default_index_href
{
    my $href = Demultiplexer::_get_default_index_href();
    
    is( $href->{"CGTCGGT"}, "A1", "_get_default_index_href()" );
}

# test split_fastq
{
    $de->split_fastq();
}

# test when no index to well file is provided
{
    my $tmp_dir = tempdir();
    my $de2 = Demultiplexer->new({
        plate_primer_file => $plate_primer_file,
        fastq_file => $fastq_file,
        output_dir => $tmp_dir
    });
    $de2->split_fastq();
}


