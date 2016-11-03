use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Demultiplexer',
    license             => 'artistic2',
    dist_author         => 'Scott Yourstone <scott.yourstone81@gmail.com>',
    dist_version_from   => 'lib/Demultiplexer.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'Demultiplexer-*' ],
    recursive_test_files => 1,
);

$builder->create_build_script();
