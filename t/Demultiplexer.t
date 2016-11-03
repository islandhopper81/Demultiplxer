use strict;
use warnings;

use Test::More tests => 7;
use Test::Exception;

# others to include
#use File::Temp qw/ tempfile tempdir /;

# helper subroutines


BEGIN { use_ok( 'Demultiplexer' ); }

my $plate_primer_file = "data/plate_primer_meta.txt";
my $index_to_well_file = "data/index_to_well.txt";

# test constructor
my $de;
throws_ok(sub{ $de = Demultiplexer->new() },
          'MyX::Generic::Undef::Param',
          "caught - Demultiplexer->new()" );
lives_ok(sub{ $de = Demultiplexer->new({
                        plate_primer_file => $plate_primer_file}) },
         "expected to live - constructor" );



# test get_plate_primer_file
{
    is( $de->get_plate_primer_file(),
       $plate_primer_file,
       "get_plate_primer_file()");
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
