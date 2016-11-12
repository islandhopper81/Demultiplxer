use strict;
use warnings;

use Test::More tests => 39;
use Test::Exception;

# others to include
use File::Temp qw/ tempfile tempdir /;
use Cwd;
use BioUtils::FastaSeq;
use File::Basename;

# get the directory of this script so I will know where the test data files
# are located
my $test_dir = dirname(__FILE__) . "/../";


BEGIN { use_ok( 'Demultiplexer::Param_Handler' ); }

my $plate_primer_file = "$test_dir/data/plate_primer_meta.txt";
my $index_to_well_file = "$test_dir/data/index_to_well.txt";
my $fastq_file = "$test_dir/data/mttoolbox_output.fastq";
my $fwd_fs_coding_file = "$test_dir/data/fwd_fs_coding.txt";
my $rev_fs_coding_file = "$test_dir/data/rev_fs_coding.txt";

# test constructor
my $de;
throws_ok(sub{ $de = Demultiplexer::Param_Handler->new() },
          'MyX::Generic::Undef::Param',
          "caught - Demultiplexer::Param_Handler->new()" );

throws_ok(sub{ $de = Demultiplexer::Param_Handler->new({
                        plate_primer_file => $plate_primer_file}) },
          'MyX::Generic::Undef::Param',
          "caught - Demultiplexer::Param_Handler->new(missing fastq_file)" );

throws_ok(sub{ $de = Demultiplexer::Param_Handler->new({
                    plate_primer_file => $plate_primer_file,
                    fastq_file => "blah"
                }) },
        'MyX::Generic::DoesNotExist::File',
        "caught - Demultiplexer::Param_Handler->new(bad fastq_file)" );

lives_ok(sub{ $de = Demultiplexer::Param_Handler->new({
                        plate_primer_file => $plate_primer_file,
                        fastq_file => $fastq_file}) },
         "expected to live - constructor" );

# test all the constructor cases where the defaults are overridden
{
    # when an output dir is given
    my $tmp_dir = tempdir();
    my $de2;
    lives_ok(sub{
        $de2 = Demultiplexer::Param_Handler->new({
            plate_primer_file => $plate_primer_file,
            fastq_file => $fastq_file,
            output_dir => $tmp_dir
        })
    }, "expected to live - new(output_dir)" );
    is( $de2->get_output_dir(), $tmp_dir, "output_dir was set in constructor" );
    
    # when an index_to_well_file is given
    lives_ok(sub{
        $de2 = Demultiplexer::Param_Handler->new({
            plate_primer_file => $plate_primer_file,
            fastq_file => $fastq_file,
            output_dir => $tmp_dir,
            index_to_well_file => $index_to_well_file
        })
    }, "expected to live - new(index_to_well_file)" );
    is( $de2->get_index_to_well_file(), $index_to_well_file,
        "index_to_well_file set in constructor" );
    
    # when an fwd_fs_coding_file is given
    lives_ok(sub{
        $de2 = Demultiplexer::Param_Handler->new({
            plate_primer_file => $plate_primer_file,
            fastq_file => $fastq_file,
            output_dir => $tmp_dir,
            fwd_fs_coding_file => $fwd_fs_coding_file
        })
    }, "expected to live - new(fwd_fs_coding_file)" );
    is( $de2->get_fwd_fs_coding_file(), $fwd_fs_coding_file,
        "fwd_fs_coding_file set in constructor" );
    
    # when an rev_fs_coding_file is given
    lives_ok(sub{
        $de2 = Demultiplexer::Param_Handler->new({
            plate_primer_file => $plate_primer_file,
            fastq_file => $fastq_file,
            output_dir => $tmp_dir,
            rev_fs_coding_file => $rev_fs_coding_file
        })
    }, "expected to live - new(rev_fs_coding_file)" );
    is( $de2->get_rev_fs_coding_file(), $rev_fs_coding_file,
        "rev_fs_coding_file set in constructor" );
}

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

# test get_plate_to_primer_file
{
    is( $de->get_plate_to_primer_file(),
       $plate_primer_file,
       "get_plate_to_primer_file()");
}

# test get_plate_to_primer_href
{
    lives_ok(sub{ $de->get_plate_to_primer_href() },
             "expected to live - get_plate_to_primer_href" );
}

# test get_fastq_file
{
    is( $de->get_fastq_file(), $fastq_file, "get_fastq_file()");
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

# test set_fwd_fs_coding_file
{
    throws_ok(sub{ $de->set_fwd_fs_coding_file() },
                  'MyX::Generic::Undef::Param',
                  "caught - set_fwd_fs_coding_file()" );
    lives_ok(sub{ $de->set_fwd_fs_coding_file($fwd_fs_coding_file) },
             "expect to live - set_fwd_fs_coding_file(file)" );
}

# test get_fwd_fs_coding_file
{
    is( $de->get_fwd_fs_coding_file(), $fwd_fs_coding_file,
       "get_fwd_fs_coding_file()" );
}

# test set_fwd_fs_coding_href
{
    lives_ok(sub{ $de->set_fwd_fs_coding_href($fwd_fs_coding_file) },
             "expected to live - set_fwd_fs_coding_href(fwd_fs_seq)" );
    lives_ok(sub{ $de->set_fwd_fs_coding_href() },
             "expected to live - set_fwd_fs_coding_href" );
}

# test get_fwd_fs_coding_href
{
    lives_ok(sub{ $de->get_fwd_fs_coding_href() },
             "expected to live - get_fwd_fs_coding_href()" );
}

# test set_rev_fs_coding_file
{
    throws_ok(sub{ $de->set_rev_fs_coding_file() },
                  'MyX::Generic::Undef::Param',
                  "caught - set_rev_fs_coding_file()" );
    lives_ok(sub{ $de->set_rev_fs_coding_file($rev_fs_coding_file) },
             "expect to live - set_rev_fs_coding_file(file)" );
}

# test get_rev_fs_coding_file
{
    is( $de->get_rev_fs_coding_file(), $rev_fs_coding_file,
       "get_rev_fs_coding_file()" );
}

# test set_rev_fs_coding_href
{
    lives_ok(sub{ $de->set_rev_fs_coding_href($rev_fs_coding_file) },
             "expected to live - set_rev_fs_coding_href(rev_fs_len)" );
    lives_ok(sub{ $de->set_rev_fs_coding_href() },
             "expected to live - set_rev_fs_coding_href" );
}

# test get_rev_fs_coding_href
{
    lives_ok(sub{ $de->get_rev_fs_coding_href() },
             "expected to live - get_rev_fs_coding_href()" );
}

# test parse_plate_primer_file
{
    my $primer_to_frames;
    lives_ok(sub{ $primer_to_frames = $de->parse_plate_primer_file() },
             "expected to live - parse_plate_primer_file" );
    is ( $primer_to_frames->{"CL1"}{"338F_f4_bc2"}, 1,
        "get primer frame {CL1}{338F_f4_bc2}" );
}

# test _get_default_index_href
{
    my $href = Demultiplexer::Param_Handler::_get_default_index_href();
    
    is( $href->{"CGTCGGT"}, "A1", "_get_default_index_href()" );
}

