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
        my $file_opt = { binmode => ':raw' };
        foreach my $filename (@files) {
            my $data = File::Slurp::read_file($filename, $file_opt);
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
            $tag = `git describe --abbrev=0 --always`;
            $tag =~ s/(?:\A\s+|\Av|\s+\z)//g;
            unless ( $tag =~ m/(\d+\.\d+\.)(\d+)(?:\-|\z)/ )
            { die "tag <$tag> invalid (\\d+.\\d+.\\d+)\n"; }
            # increment patch level
            else { $tag = $1 . ($2 + 1); }
        }
        $tag =~ s/(?:\A\s+|\Av|\s+\z)//g;
        my $file_opt = { binmode => ':raw' };
        print "update *.pm with new version <$tag>\n";
        unless ( $tag =~ m/(\d+\.\d+\.)(\d+)(?:\-|\z)/ )
        { die "tag <$tag> invalid (\\d+.\\d+.\\d+)\n"; }
        foreach my $filename (@files) {
            my $data = File::Slurp::read_file($filename, $file_opt);
            if ($data =~ s/$re_version/our \$VERSION = \"v$tag\";/i) {
                next if $tag eq $1;
                print "  update version $filename (was $1)\n";
                File::Slurp::write_file($filename, $file_opt, $data);
            }
        }
    } else {
      die "git directory not found";
    }
}

SUBCLASS

my $cover = $ARGV[0] && $ARGV[0] eq "cover=1" ? 1 : 0;

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
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl' => '5.008',
        'File::Slurp' => 0,
    },
    meta_merge => {
      resources => {
        repository  => 'https://github.com/caldwell/CSS-Sass',
      },
    },
    add_to_cleanup     => [ 'CSS-Sass-*' ],
    extra_compiler_flags => ($cover ? ' -O0 -fprofile-arcs -ftest-coverage' : ''),
    $Config{cc} eq 'clang' ? (
        # clang has a bunch of asinine warnings on by default:
        extra_compiler_flags => '-Wno-parentheses -Wno-tautological-compare -Wno-unused-value' .
                                ($cover ? ' -O0 -fprofile-arcs -ftest-coverage' : ''),
    ) : (),
    extra_cpp_compiler_flags => [ '-std=c++0x' ],
    extra_linker_flags => ($cover ? '-lgcov -fprofile-arcs -ftest-coverage' : ''),
    c_source => { 'libsass' => [ sort qw(
        sass2scss.cpp node.cpp sass_util.cpp remove_placeholders.cpp
        ast.cpp base64vlq.cpp bind.cpp constants.cpp context.cpp contextualize.cpp
        copy_c_str.cpp error_handling.cpp eval.cpp expand.cpp cencode.c json.cpp
        extend.cpp file.cpp functions.cpp inspect.cpp output_compressed.cpp
        output_nested.cpp parser.cpp prelexer.cpp sass.cpp sass_interface.cpp
        source_map.cpp to_c.cpp to_string.cpp units.cpp utf8_string.cpp util.cpp
    ) ]
    },
    config => { ld => 'c++' }, # Need to link with a C++ linker since libsass is C++ (even though the .xs file is not)
);

$config{'requires'}->{'Win32::Unicode::File'} = 0 if ($^O eq "MSWin32");

my $builder = Module::Build::Custom->new(%config);

$builder->create_build_script();
