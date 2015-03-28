use 5.008;
use strict;
use warnings FATAL => 'all';
use Module::Build;
use Config;
use File::Spec;
use Cwd;

my $libsass_version = '[na]';

# Are we in our development tree?
# If so, create the MANIFEST file.
if (-d ".git") {
    my @modules = ('.');
    my $base = getcwd;
    my ($dir, $manifest);
    system "git submodule init";
    system "git submodule update";
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

if (-e "libsass/.git" && ! -f "libsass/VERSION") {
  chdir "libsass";
  my $libsass_version = `git describe --abbrev=4 --dirty --always --tags`;
  chdir "..";
  require File::Slurp;
  chomp $libsass_version;
  File::Slurp::write_file("libsass/VERSION", { 'binmode' => ':raw' }, $libsass_version);
}
if (-f "libsass/VERSION") {
  require File::Slurp;
  $libsass_version = File::Slurp::read_file("libsass/VERSION", { 'binmode' => ':raw' });
  print "using libsass version $libsass_version\n";
}

my $class = Module::Build->subclass(
    class => "Module::Build::Custom",
    code => <<'SUBCLASS' );

sub compile_c {

  my ($self) = shift;
  my ($file, %args) = @_;

  my @extra_compiler_flags;
  my $properties = $self->{'properties'};

  if ($file =~ m/.c$/ && defined $properties->{'extra_c_compiler_flags'})
  { push @extra_compiler_flags, @{$properties->{'extra_c_compiler_flags'}} }
  if ($file =~ m/.cpp$/ && defined $properties->{'extra_cpp_compiler_flags'})
  { push @extra_compiler_flags, @{$properties->{'extra_cpp_compiler_flags'}} }

  push @extra_compiler_flags, @{$properties->{'extra_compiler_flags'}};
  local $properties->{'extra_compiler_flags'} = [ @extra_compiler_flags ];

  return $self->SUPER::compile_c(@_);
}

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

my $re_version = qr/our\s+\$VERSION\s*=\s*[\"\']
                    v?([0-9]+\.[0-9]+\.[0-9]+(?:\-.+?)?)
                   [\"\']\s*\;/x;

# ./Build versions
sub ACTION_versions {
    if (-d ".git") {
        require File::Slurp;
        @files = grep { m/.pm$/i } split /\r?\n/, `git ls-files`;
        for(my $i = 0; $i < scalar(@ARGV) - 1; $i++) {
            if ($ARGV[$i] eq "versionize") {
                $tag = $ARGV[$i+1]; last;
            }
        }
        foreach my $filename (@files) {
            my $data = File::Slurp::read_file($filename, { 'binmode' => ':raw' });
            if ($data =~ m/$re_version/i) {
                print "  $filename ($1)\n";
            } else {
                print "  $filename ([NA])\n";
            }
        }
    } else {
      die "git directory not found";
    }
}

# ./Build versionize [2.4.6]
sub ACTION_versionize {
    if (-d ".git") {
        my $tag;
        require File::Slurp;
        @files = grep { m/.pm$/i } split /\r?\n/, `git ls-files`;
        for(my $i = 0; $i < scalar(@ARGV) - 1; $i++) {
            if ($ARGV[$i] eq "versionize") {
                $tag = $ARGV[$i+1]; last;
            }
        }
        unless ($tag) {
            $tag = `git describe --abbrev=0 --always --tag`;
            $tag =~ s/(?:\A\s+|\Av|\s+\z)//g;
            unless ( $tag =~ m/(\d+\.\d+\.)(\d+)(?:\-|\z)/ )
            { die "tag <$tag> invalid (\\d+.\\d+.\\d+)\n"; }
            # increment patch level
            else { $tag = $1 . ($2 + 1); }
        }
        $tag =~ s/(?:\A\s+|\Av|\s+\z)//g;
        print "update *.pm with new version <$tag>\n";
        unless ( $tag =~ m/(\d+\.\d+\.)(\d+)(?:\-|\z)/ )
        { die "tag <$tag> invalid (\\d+.\\d+.\\d+)\n"; }
        foreach my $filename (@files) {
            my $data = File::Slurp::read_file($filename, { 'binmode' => ':raw' });
            if ($data =~ s/$re_version/our \$VERSION = \"v$tag\";/i) {
                next if $tag eq $1;
                print "  update version $filename (was $1)\n";
                File::Slurp::write_file($filename, { 'binmode' => ':raw' }, $data);
            }
        }
    } else {
      die "git directory not found";
    }
}

SUBCLASS

my $cover = $ARGV[0] && $ARGV[0] eq "cover=1" ? 1 : 0;

# create compile flags to include the libsass version (escape correctly)
my $version = ($^O ne "MSWin32") ? qq( -DLIBSASS_VERSION=\\"$libsass_version\\") :
                                   qq( -DLIBSASS_VERSION=\\"\\\\\\"$libsass_version\\\\\\"\\");

my %config = (
    module_name         => 'CSS::Sass',
    license             => 'MIT',
    dist_author         => [q{David Caldwell <david@porkrind.org>},
                            q{Marcel Greter <perl-libsass@ocbnet.ch>}],
    dist_version_from   => 'lib/CSS/Sass.pm',
    release_status      => 'stable',
    create_license      => 0,
    configure_requires => {
        'Module::Build' => 0,
        'File::chdir' => 0,
        'File::Slurp' => 0,
    },
    build_requires => {
        'Test::More' => 0,
        'File::chdir' => 0,
    },
    test_requires => {
        'File::chdir' => 0,
        'Test::Differences' => 0,
    },
    requires => {
        'perl' => '5.008',
        'File::chdir' => 0,
        'File::Slurp' => 0,
        'List::MoreUtils' => 0,
    },
    meta_merge => {
      resources => {
        repository  => 'https://github.com/caldwell/CSS-Sass',
      },
    },
    add_to_cleanup     => [ 'CSS-Sass-*' ],
    extra_compiler_flags => ($cover ? ' -O0 -fprofile-arcs -ftest-coverage' : '') . ' -Wall' . $version,
    $Config{cc} eq 'clang' ? (
        # clang has a bunch of asinine warnings on by default:
        extra_compiler_flags => '-Wno-parentheses -Wno-tautological-compare -Wno-unused-value' .
                                ($cover ? ' -O0 -fprofile-arcs -ftest-coverage' : '') . $version,
    ) : (),
    extra_cpp_compiler_flags => [ '-std=c++0x' ],
    extra_linker_flags => ($cover ? '-lgcov -fprofile-arcs -ftest-coverage' : ''),
    c_source => { 'libsass' => [ sort qw(
        ast.cpp sass2scss.cpp node.cpp sass_util.cpp remove_placeholders.cpp json.cpp
        base64vlq.cpp bind.cpp constants.cpp context.cpp contextualize.cpp plugins.cpp
        error_handling.cpp eval.cpp expand.cpp cencode.c functions.cpp inspect.cpp
        extend.cpp file.cpp output.cpp parser.cpp prelexer.cpp emitter.cpp position.cpp
        sass.cpp sass_interface.cpp sass_functions.cpp sass_values.cpp sass_context.cpp
        source_map.cpp to_c.cpp to_string.cpp units.cpp utf8_string.cpp util.cpp cssize.cpp
        contextualize_eval.cpp listize.cpp lexer.cpp
    ) ]
    },
    config => { ld => 'c++' }, # Need to link with a C++ linker since libsass is C++ (even though the .xs file is not)
);

my $builder = Module::Build::Custom->new(%config);

$builder->create_build_script();
