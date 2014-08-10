use 5.008;
use strict;
use warnings FATAL => 'all';
use Module::Build;
use Config;
use File::Spec;
use Cwd;

# Are we in our development tree?
# If so, create the MANIFEST file.
if (-d ".git") {
    my @modules = ('.');
    my $base = getcwd;
    my ($dir, $manifest);
    open $manifest, ">", "MANIFEST" or die "MANIFEST: $!";
    print $manifest "MANIFEST\n";
    while (my $module = shift @modules)
    {
      my $cwd = getcwd;
      chdir ($module) or die "pushd: $!";
      my $files = `git ls-files` or die "Couldn't run git: $!";
      my @items = split(/\n+/, $files);
      my @files = grep { ! -d } @items;
      print $manifest
        map { tr/\\/\//; $_ . "\n" }
        map { File::Spec->abs2rel($_, $base) } @files;
      push @modules,
        map { File::Spec->catfile($module, $_) }
        grep { -d } @items;
      chdir ($cwd) or die "popd: $!";
    }
}

my $class = Module::Build->subclass(
    class => "Module::Build::Custom",
    code => <<'SUBCLASS' );

sub process_support_files {
  my $self = shift;
  my $p = $self->{properties};
  return unless $p->{c_source};

  my $files;
  if (ref($p->{c_source}) eq "HASH") {
      foreach my $path (keys %{$p->{c_source}}) {
          push @{$p->{include_dirs}}, $path;
          foreach my $file (@{$p->{c_source}->{$path}}) {
              $file = join('/', $path, $file);
              push @{$p->{objects}}, $self->compile_c($file);
          }
      }
  } else {
      $self->SUPER::process_support_files;
  }

}
SUBCLASS

my $cover = $ARGV[0] && $ARGV[0] eq "cover=1" ? 1 : 0;

my $builder = Module::Build::Custom->new(
    module_name         => 'CSS::Sass',
    license             => 'perl',
    dist_author         => q{David Caldwell <david@porkrind.org>},
    dist_version_from   => 'lib/CSS/Sass.pm',
    release_status      => 'stable',
    create_license      => 1,
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Class::Accessor::Fast' => 0,
    },
    meta_merge => {
      resources => {
        repository  => 'https://github.com/caldwell/CSS-Sass',
      },
    },
    add_to_cleanup     => [ 'CSS-Sass-*' ],
    extra_compiler_flags => ($cover ? '-O0 -fprofile-arcs -ftest-coverage' : ''),
    $Config{cc} eq 'clang' ? (
        # clang has a bunch of asinine warnings on by default:
        extra_compiler_flags => '-Wno-parentheses -Wno-tautological-compare -Wno-unused-value' .
                                $cover ? ' -O0 -fprofile-arcs -ftest-coverage' : '',
    ) : (),
    extra_linker_flags => ($cover ? '-lgcov -fprofile-arcs -ftest-coverage' : ''),
    c_source => { 'libsass' => [ qw(sass2scss/sass2scss.cpp
        ast.cpp base64vlq.cpp bind.cpp constants.cpp context.cpp contextualize.cpp
        copy_c_str.cpp emscripten_wrapper.cpp error_handling.cpp eval.cpp expand.cpp
        extend.cpp file.cpp functions.cpp inspect.cpp output_compressed.cpp
        output_nested.cpp parser.cpp prelexer.cpp sass.cpp sass_interface.cpp
        source_map.cpp to_c.cpp to_string.cpp units.cpp utf8_string.cpp util.cpp
    ) ] #, "sass2scss" => [ qw(sass2scss.cpp) ]
    },
    config => { ld => 'c++' }, # Need to link with a C++ linker since libsass is C++ (even though the .xs file is not)
);

$builder->create_build_script();
