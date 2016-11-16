use strict;
use warnings;

use Test::More tests => 10;
use Test::Exception;

# others to include
# use File::Temp qw/ tempfile tempdir /;

BEGIN { use_ok( 'Demultiplexer::Summary' ); }

# test constructor
my $summary;
lives_ok(sub{ $summary = Demultiplexer::Summary->new() },
         "lives - Demultiplexer::Summary->new()" );

# test increment_feature
{
    throws_ok(sub{ $summary->increment_feature() },
              "MyX::Generic::Undef::Param",
              "throws - increment_feature()" );
    lives_ok(sub{ $summary->increment_feature("feat1") },
             "lives - increment_feature(feat1)" );
    is($summary->get_feature("feat1"), 1, "increment_feature(feat1)" );
    
    # increment again
    lives_ok(sub{ $summary->increment_feature("feat1") },
             "lives - increment_feature(feat1)" );
    is($summary->get_feature("feat1"), 2, "increment_feature(feat1)" );
    
    # increment a second feature but still check the first one
    lives_ok(sub{ $summary->increment_feature("feat2") },
             "lives - increment_feature(feat2)" );
    is($summary->get_feature("feat1"), 2, "increment_feature(feat1)" );
    is($summary->get_feature("feat2"), 1, "increment_feature(feat1)" );
}
