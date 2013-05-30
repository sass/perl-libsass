use 5.008;
use strict;
use warnings FATAL => 'all';
use Module::Build;

if (-d ".git") { # Are we in our development tree? If so, create MANIFEST.
    my ($dir, $manifest);
    open $manifest, ">", "MANIFEST" or die "MANIFEST: $!";
    print $manifest "MANIFEST\n";
    open $dir, '-|', 'git', 'ls-files' or die "Couldn't run git: $!";
    while (<$dir>) { print $manifest $_ unless /^\.|^libsass/ }
    open $dir, '-|', 'cd libsass && git ls-files' or die "Couldn't run git in libsass: $!";
    while (<$dir>) { print $manifest "libsass/$_" unless /^\./ }
}

my $builder = Module::Build->new(
    module_name         => 'CSS::Sass',
    license             => 'perl',
    dist_author         => q{David Caldwell <david@porkrind.org>},
    dist_version_from   => 'lib/CSS/Sass.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
    },
    add_to_cleanup     => [ 'CSS-Sass-*' ],
    create_makefile_pl => 'traditional',
    # clang has a bunch of asinine warnings on by default:
    extra_compiler_flags => '-Wno-parentheses -Wno-tautological-compare -Wno-unused-value',
    extra_linker_flags   => '',
    c_source     => 'libsass',
);

$builder->create_build_script();
