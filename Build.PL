use 5.008;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Text::Sass::XS',
    license             => 'perl',
    dist_author         => q{David Caldwell <david@porkrind.org>},
    dist_version_from   => 'lib/Text/Sass/XS.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
    },
    add_to_cleanup     => [ 'Text-Sass-XS-*' ],
    create_makefile_pl => 'traditional',
    extra_compiler_flags => '-Wno-parentheses -Wno-tautological-compare',
    extra_linker_flags   => '',
    c_source     => 'libsass',
    xs_files     => {
        './XS.xs' => 'lib/Text/Sass/XS.xs',
    },
);

$builder->create_build_script();
