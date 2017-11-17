# Copyright (c) 2013-2014 David Caldwell.
# Copyright (c) 2014-2017 Marcel Greter.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

use 5.008000;
use Getopt::Long;
use ExtUtils::CppGuess;
use ExtUtils::MakeMaker;

# TIP: use `dmake -P#jobs` on windows

use strict;
use warnings;

################################################################################
# commandline options
################################################################################

# command line options
my $optimize = '-O3';
my $debug_mode = 0;
my $install_sassc = 0;
my $install_plugins = 1;
my $install_library = 0;
my $native_watcher = 0;
my $compiler = undef;
my $profiling = 0;
my $skip_manifest = 0;
my $skip_version = 0;
my $update_deps = 0;
my $checkout_deps = 0;
my $skip_git = 0;

# arrays for various switches
my (@libs, @flags, @defs, @incs);

# start by adding the main incs
push @incs, '.', 'libsass/include';

# query version of libsass dep
my $libsass_version = '[na]';

sub help
{
	print "CSS::Sass Makefile.PL end-user options:\n\n";
	print "  --sassc              Install optional sassc cli utility\n";
	print "  --plugins            Install optional libsass plugins (default)\n";
	print "  --library            Install libsass library (auto-enabled)\n";
	print "  --native-watcher     Depend on optimized file watcher module\n";
	print "  --help               This help screen\n";
	print "\n  The following options are for developers only:\n\n";
	print "  --debug              Build libsass in debug mode\n";
	print "  --profiling          Enable gcov profiling switches\n";
	print "  --compiler           Skips compiler autodetection (passed to CppGuess)\n";
	print "  --skip-manifest      Skips manifest generation (would need git repo)\n";
	print "  --skip-version       Skips generating libsass/VERSION (would need git repo)\n";
	print "  --update-deps        Update libsass and specs to latest master (needs git repo)\n";
	print "  --checkout-deps      Checkout submodules at linked commit (needs git repo)\n";
	print "  --get-versions       Show versions of all perl package (.pm) files\n";
	print "  --set-versions       Set versions of all perl package (.pm) files\n";
	print "  --skip-git           Do not try to use anything git related\n";
	exit 1;
}

my $re_vtoken = qr/v?([0-9]+\.[0-9]+\.[0-9]+(?:[\-_].+?)?)/;
my $re_version = qr/our\s+\$VERSION\s*=\s*[\"\']
                    $re_vtoken
                   [\"\']\s*\;/x;


################################################################################
# helper for version cli option
################################################################################

# needs File::Slurp
# no hard dependency!
sub versions
{
	my @files;
	my ($v) = @_;
	require File::Slurp;
	my $tag = $v;
	my $ma = File::Slurp::read_file('MANIFEST', { 'binmode' => ':raw' });
	@files = grep { m/.pm$/i } split /\s*\r?\n/, $ma;
	# this optional step need git repo
	# when nothing is explicitly passed
	unless ($tag) {
		$tag = `git describe --abbrev=0 --always --tag`;
		$tag =~ s/(?:\A\s+|\Av|\s+\z)//g;
		unless ( $tag =~ m/(\d+\.\d+\.)(\d+)(?:[\-_]|\z)/ )
		{ die "Tag <$tag> invalid (\\d+.\\d+.\\d+)\n"; }
		# increment the patch level
		else { $tag = $1 . ($2 + 1); }
	}
	$tag =~ s/(?:\A\s+|\Av|\s+\z)//g;
	if (scalar(@_)) {
		print "Update META.* and *.pm with new version <$tag>\n";
		unless ( $tag =~ m/(\d+\.\d+\.)(\d+)(?:[\-_]|\z)/ )
		{ die "Tag <$tag> invalid (\\d+.\\d+.\\d+)\n"; }
		my $metayml = File::Slurp::read_file("META.yml", { 'binmode' => ':raw' });
		if ($metayml =~ s/version\s*:\s*v($re_vtoken)/version: v$tag/i && $tag ne $1) {
			print "  update version in META.yml (was $1)\n";
			File::Slurp::write_file("META.yml", { 'binmode' => ':raw' }, $metayml);
		}
		my $metajson = File::Slurp::read_file("META.json", { 'binmode' => ':raw' });
		if ($metajson =~ s/\"version\"\s*:\s*\"v($re_vtoken)\"/\"version\" : \"v$tag\"/i && $tag ne $1) {
			print "  update version in META.json (was $1)\n";
			File::Slurp::write_file("META.json", { 'binmode' => ':raw' }, $metajson);
		}
		foreach my $filename (@files) {
			my $data = File::Slurp::read_file($filename, { 'binmode' => ':raw' });
			if ($data =~ s/$re_version/our \$VERSION = \"$tag\";/i) {
				next if $tag eq $1;
				print "  update version in $filename (was $1)\n";
				File::Slurp::write_file($filename, { 'binmode' => ':raw' }, $data);
			}
		}
	} else {
		foreach my $filename (@files) {
			my $data = File::Slurp::read_file($filename, { 'binmode' => ':raw' });
			print "  $filename (", ($data =~ m/$re_version/i ? $1 : "[NA]"), ")\n";
		}
	}
}

################################################################################
# parse options via GetOptions ("posix standard")
################################################################################

GetOptions(
	'--help' => \&help,
	'--debug!' => \$debug_mode,
	'--sassc!' => \$install_sassc,
	'--plugins!' => \$install_plugins,
	'--library!' => \$install_library,
	'--compiler:s' => \$compiler,
	'--profiling!' => \$profiling,
	'--skip-git!' => \$skip_git,
	'--skip-version!' => \$skip_version,
	'--skip-manifest!' => \$skip_manifest,
	'--native-watcher!' => \$native_watcher,
	# options for git submodules
	'--update-deps!' => \$update_deps,
	'--checkout-deps!' => \$checkout_deps,
	# manipulate versions of all perl packages
	'--get-versions' => sub { versions(); exit 1; },
	'--set-versions:s' => sub { versions($_[1]); exit 1; },
);

################################################################################
# some git helper utilities (devs only)
################################################################################

# declare git submodules that are used
my @submodules = qw(libsass t/sass-spec);

if ($install_sassc) {
	push @submodules, "plugins/sassc";
}

if ($install_plugins) {
	# add optional libsass-math plugin
	push @submodules, "plugins/math";
	# add optional libsass-img-size plugin
	push @submodules, "plugins/img-size";
	# add optional libsass-glob plugin
	push @incs, 'plugins/glob/vendor';
	push @submodules, "plugins/glob";
	# add optional libsass-digest plugin
	push @incs, 'plugins/digest/vendor';
	push @incs, 'plugins/digest/vendor/crc';
	push @incs, 'plugins/digest/vendor/md5';
	push @submodules, "plugins/digest";
}

# make some options depending on others
# no-library (static) is not yet handled
$install_library = 1 if $install_sassc;
$install_library = 1 if $install_plugins;

# print some debug messages to console
print "Building sassc cli util\n" if $install_sassc;
print "Building libsass plugins\n" if $install_plugins;
print "Building shared libsass lib\n" if $install_library;
print "Compiling with code profiling\n" if $profiling;
print "Compiling release build\n" unless $debug_mode;
print "Compiling debug build\n" if $debug_mode;

# Are we in our development tree?
# If so, create the MANIFEST file.
if (-d ".git" && !$skip_git)
{
	require Cwd;
	require File::Spec;
	my @modules = ('.');
	my $base = Cwd::getcwd;
	my ($dir, $manifest);
	# init and update git submodules
	foreach my $submodule (@submodules)
	{
		if (!-e "$submodule/.git" || $checkout_deps)
		{
			print "Checkout git submodule: $submodule\n";
			system "git submodule init \"$submodule\"";
			system "git submodule update \"$submodule\"";
			system "git -C \"$submodule\" fetch --tags";
		}
	}
	# create manifest file via git
	# also add files that we generate
	unless ($skip_manifest) {
		open $manifest, ">:encoding(UTF-8)", "MANIFEST";
		die "could not create MANIFEST: $!" unless $manifest;
		print $manifest "MANIFEST\n";
		print $manifest "libsass/VERSION\n";
		while (my $module = shift @modules)
		{
			my $cwd = Cwd::getcwd;
			chdir ($module) or die "pushd: $!";
			my $files = "";
			if (-e ".git") {
				$files = `git ls-files` or
					die "Couldn't run git: $!";
			}
			my @items = split(/\n+/, $files);
			my @files = grep { ! -d } @items;
			print $manifest grep { ! /\"/ }
				map { tr/\\/\//; $_ . "\n" }
				map { File::Spec->abs2rel($_, $base) } @files;
			push @modules,
				map { File::Spec->catfile($module, $_) }
				grep { -d } @items;
			chdir ($cwd) or die "popd: $!";
		}
	}
	if ($update_deps)
	{
		foreach my $submodule (@submodules)
		{
			print "Update git submodule $submodule\n";
			system "git -C \"$submodule\" fetch";
			system "git -C \"$submodule\" fetch --tags";
			system "git -C \"$submodule\" pull --ff origin master";
		}
	}
	# create version file in libsass submodule root
	foreach my $submodule (@submodules)
	{
		if (-e "$submodule/.git" && !$skip_version) {
			next unless $submodule eq "libsass"; # skip all others for now
			system "git -C \"$submodule\" describe --abbrev=8 --dirty --always --tags > \"$submodule/VERSION\"";
		}
	}
}

################################################################################
# get the libsass version from source
################################################################################

# read version from version file
if (-f "libsass/VERSION") {
	open (my $fh, "<", "libsass/VERSION");
	$libsass_version = <$fh> if (defined $fh);
	chomp($libsass_version);
	print "Detected libsass $libsass_version\n";
} else {
	# give a warning if the version could not be determined (probably not generated yet)
	warn "Could not get version for libsass (", $libsass_version, ")\n";
}

################################################################################
# compiler configurations
################################################################################

my $guess = ExtUtils::CppGuess->new(
	(defined($compiler) ? (cc => $compiler) : ()),
);

# check gcc version
if ($guess->is_gcc) {
	# version not exposed by CppGuess!?
	use Capture::Tiny 'capture_merged';
	my $cmd = $guess->{cc} . " --version";
	my $cc_version = capture_merged { system($cmd) };
	if ($cc_version =~ m/gcc\s+\([^\)]+\)\s+(\d+)\.(\d+)\.(\d+)\r?\n/i) {
		$cc_version = sprintf("%d.%d.%d", $1, $2, $3);
		$guess->{'gcc_version'} = $cc_version;
		print "Detected GCC compiler $cc_version ...\n";
		if ($1 < 4 || ($1 == 4 && $2 < 4)) {
			warn "Your GCC Version is too old for LibSass!\n";
			warn "Needs at least gcc version 4.4 or higher!\n";
			die "Please consider upgrading your GCC compiler!\n";
		}
	}
	else {
		print "Detected GCC compiler (version unknown) ...\n";
	}
}
# we never really tested compilation via MSVC yet ...
elsif ($guess->is_msvc) { print "Detected MSVC compiler ...\n"; }
else { print "Unknown compiler, trying anyway...\n"; }

# Fixup CC flags issue
no warnings 'redefine';
my $orig = \&ExtUtils::MM_Unix::c_o;
*ExtUtils::MM_Unix::c_o = sub {
	my @rv = &{$orig};
	foreach (@rv) {
		# add c++0x flag only for cpp files
		# otherwise XS perl handshake fails
		s/\$\*\.c(pp|xx)\s*(?=\n|\r|\Z)/-xc++ -std=c++0x \$\*\.c$1/g
	}
	return @rv;
};
use warnings 'redefine';

# enable all warnings (disable only specific ones)
push @flags, '-Wall -Wextra -Wno-unused-parameter';

# enable optional debug mode
$optimize = '-O1' if $debug_mode;
push @defs, 'DEBUG' if $debug_mode;

# not sure why this does not work otherwise
push @flags, '-o $*.o' if ($guess->is_gcc);

# this fixes some clang issues (is detected as gcc)
# push @flags, '-stdlib=libstdc++' if ($guess->is_gcc);

# create compile flags to include the libsass version
push @defs, qq( LIBSASS_VERSION=\\"$libsass_version\\");

# enable code profiling via gcov
$optimize = '-O1' if $profiling;
push @libs, '-lgcov' if $profiling;
push @libs, '-fprofile-arcs' if $profiling;
push @libs, '-ftest-coverage' if $profiling;
push @flags, '-fprofile-arcs' if $profiling;
push @flags, '-ftest-coverage' if $profiling;

# now add our custom flags
$guess->add_extra_linker_flags(join(' ', @libs));
$guess->add_extra_compiler_flags(join(' ', @flags));

# fetch the original compiler flags
my %compiler_flags = $guess->makemaker_options();

# remove c++ flag (only needed for cpp files)
$compiler_flags{'CCFLAGS'} =~ s/\-xc\+\+//g;

# cleanup some unnecessary whitespace
$compiler_flags{'CCFLAGS'} =~ s/^\s+//g;
$compiler_flags{'CCFLAGS'} =~ s/\s+$//g;
$compiler_flags{'CCFLAGS'} =~ s/\s+/ /g;

# disable all optimizations when doing code profiling
$compiler_flags{'CCFLAGS'} =~ s/\s*\-O[1-9]//g if $profiling;

# avoid invalid flag warning when compiling c++ files (already has -Wall and -Wextra)
$compiler_flags{'CCFLAGS'} =~ s/(?:\s+|\A)-Wimplicit-function-declaration(?:\s+|\z)/ /g;

# parse source files directly from libsass makefile
open(my $fh, "<", "libsass/Makefile.conf");
die "libsass/Makefile.conf not found" unless $fh;
my $srcfiles = join "", <$fh>; close $fh;

my (@CFILES, @CPPFILES);
# parse variable out (this is hopefully tolerant enough)
if ($srcfiles =~ /^\s*SOURCES\s*=\s*((?:.*(?:\\\r?\n))*.*)/m) {
	@CPPFILES = grep { $_ } split /(?:\s|\\\r?\n)+/, $1;
} else { die "Did not find c++ SOURCES in libsass/Makefile.conf"; }
if ($srcfiles =~ /^\s*CSOURCES\s*=\s*((?:.*(?:\\\r?\n))*.*)/m) {
	@CFILES = grep { $_ } split /(?:\s|\\\r?\n)+/, $1;
} else { die "Did not find c++ CSOURCES in libsass/Makefile.conf"; }

# prefix paths and filter the c and c++ sources
my @SOURCES = map { join '/', 'libsass', 'src', $_ }
              grep { s/\.c(?:pp)?$/\.o/ }
              (@CFILES, @CPPFILES);

# Fix an issue with EU::MM > 7.10 as reported in:
# https://github.com/sass/perl-libsass/issues/25
my $EMMV = $ExtUtils::MakeMaker::VERSION;
# Bug has been fixed in version 7.20
if ($EMMV > 7.10 && $EMMV < 7.20) {
	# Fix another issue if as-needed is not supported
	# https://github.com/sass/perl-libsass/issues/26
	unless (`ld --help` =~ /--no-as-needed/) {
		warn "Your current ExtUtils::MakeMaker has a bug\n";
		die "You need to upgrade ExtUtils::MakeMaker to 7.20+\n";
	}
	if (exists $compiler_flags{'dynamic_lib'}) {
		my $dynlibs = $compiler_flags{'dynamic_lib'};
		if (exists $dynlibs->{'OTHERLDFLAGS'}) {
			if ($guess->is_gcc) {
				$dynlibs->{'OTHERLDFLAGS'} = join " ",
					'-Wl,--no-as-needed',
					$dynlibs->{'OTHERLDFLAGS'},
					'-Wl,--as-needed';
			}
		}
	}
}

################################################################################
# Emit a message to inform user of suboptimal watch behavior
# Filesys::Notify::KQueue will use inefficient polling scans
################################################################################

# stores choosen matcher
my $watchdeps = undef;

# list watchers per OS
my %watchers = (
	'linux' => [ 'Linux::Inotify2', 0.01 ],
	'darwin' => [ 'Mac::FSEvents', 0.01 ],
	'freebsd' => [ 'Filesys::Notify::KQueue', 0.01 ],
	'MSWin32' => [ 'Win32::ChangeNotify', 0.01 ],
	'cygwin' => [ 'Win32::ChangeNotify', 0.01 ]
);

# check if dependency is wanted and/or available
if (exists $watchers{$^O} && ! $ENV{PERL_FNS_NO_OPT}) {
	if ($native_watcher) { $watchdeps = $watchers{$^O}; }
	elsif (!eval { require $watchers{$^O}->[0]; return 1; }) {
		warn "Consider installing $watchers{$^O}->[0]\n";
		warn "Or configure with `--native-watcher` option\n";
	}
}

################################################################################
# See lib/ExtUtils/MakeMaker.pm for details of how to
# influence content of the Makefile that is written.
################################################################################

my %WriteMakefile = (
	NAME               => 'CSS::Sass',
	# finds $VERSION, requires EU::MM from perl >= 5.5
	VERSION_FROM       => 'lib/CSS/Sass.pm',
	# runtime dependencies
	PREREQ_PM          => {
		# 'perl'                 => 5.008000,
		'Carp'                 => 1.01, # core as of 5.008
		'version'              => 0,
		'warnings'             => 0, # core as of 5.008
		'strict'               => 0, # core as of 5.008,
		# dependencies for psass cli tool
		# 'Benchmark'          => 0.01,
		'Getopt::Long'         => 0.01,
		'Encode::Locale'       => 0.01,
		# dependencies for file watcher
		# uniq only available since 1.45
		'List::Util'           => 1.45, # core as of 5.008
		# this is an optional dependency
		# only needed for psass filewatcher
		'Filesys::Notify::Simple' => 0.01,
		# it doesn't have any dependencies
		# but you may want to install one of
		# Linux::Inotify2, Win32::ChangeNotify
		# Mac::FSEvents, Filesys::Notify::KQueue
		$watchdeps ? @{$watchdeps} : (),
	},
	# test dependencies
	TEST_REQUIRES      => {
		'YAML::XS'             => 0.01,
		'File::chdir'          => 0.01,
		'Test::Differences'    => 0.01,
	},
	# build dependencies
	BUILD_REQUIRES     => {
		'Getopt::Long'         => 0.01,
		'ExtUtils::CppGuess'   => 0.09,
		'ExtUtils::MakeMaker'  => 6.52,
	},
	# build dependencies
	CONFIGURE_REQUIRES => {
		'Getopt::Long'         => 0.01,
		'ExtUtils::CppGuess'   => 0.09,
		'ExtUtils::MakeMaker'  => 6.52,
	},
	# additional information
	META_MERGE => {
		resources => {
			license     => 'http://opensource.org/licenses/MIT',
			homepage    => 'https://metacpan.org/release/CSS-Sass',
			bugtracker  => 'https://github.com/sass/perl-libsass/issues',
			repository  => 'https://github.com/sass/perl-libsass',
		},
	},
	ABSTRACT_FROM      => 'lib/CSS/Sass.pm', # retrieve abstract from module
	AUTHOR             => q{David Caldwell <david@porkrind.org>},
	AUTHOR             => q{Marcel Greter <perl-libsass@ocbnet.ch>},
	LICENSE            => 'MIT',
	# options are set by CppGuess
	# LIBS               => [''],
	# CCFLAGS            => '',
	# LDDLFLAGS          => '',
	INC                => join(" ", map { sprintf "-I%s", $_ } @incs),
	DEFINE             => join(" ", map { sprintf "-D%s", $_ } @defs),
	%compiler_flags,
	OPTIMIZE           => $optimize,
	TYPEMAPS           => [ 'perlobject.map' ],
	OBJECT             => join(" ", (@SOURCES), '$(O_FILES)'),
	EXE_FILES          => [ 'bin/psass' ],
);

# remove unknown key (as seen in Dist::Zilla)
unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
	delete $WriteMakefile{TEST_REQUIRES};
	delete $WriteMakefile{BUILD_REQUIRES};
	# $WriteMakefile{PREREQ_PM} = \%fallback;
}

# remove unknown key (as seen in Dist::Zilla)
unless ( eval { ExtUtils::MakeMaker->VERSION(6.52) } ) {
	delete $WriteMakefile{CONFIGURE_REQUIRES}
}

# See lib/ExtUtils/MakeMaker.pm for details of how to
# influence content of the Makefile that is written.
my $mm = WriteMakefile(%WriteMakefile);

################################################################################
# extend EU::MM to compile additional LibSass tools
# there is a good chance the commands below will fail
# due to different systems this is more than unflexible
# but I also do not have an idea how to make it better
################################################################################

# subclass EU::MM
package MY;
use Config;

my @targets;
my @cleanups;
my @commands;
my $static = 0;
my $reported = 0;

# http://perldoc.perl.org/ExtUtils/MakeMaker.html#make-install
sub inst_lib {
	my ($mm) = @_;
	warn "Installing as a ", $mm->{INSTALLDIRS}, " module\n"
		unless $reported; $reported = 1;
	return '$(INSTALLARCHLIB)' if $mm->{INSTALLDIRS} eq "perl";
	return '$(INSTALLSITEARCH)' if $mm->{INSTALLDIRS} eq "site";
	return '$(INSTALLVENDORLIB)' if $mm->{INSTALLDIRS} eq "vendor";
	die "invalid INSTALLDIRS setting, abort";
}


sub compile_lib {
	my ($mm, $name) = @_;
	my @args = (
		'$(LD) $(OPTIMIZE) -lstdc++ -shared', "-o ${name}",
	);
	# need special path on windows and MSVC (cl)
	if ($^O eq 'MSWin32' && $Config{cc} =~ /^cl/) {
		die "plugins are not available under MSVC";
	}
	elsif ($^O eq 'MSWin32' && $Config{cc} =~ /gcc/) {
		push @args, "-Wl,--out-implib,${name}.a";
		push @args, '-Wl,--major-image-version,0.0.9';
		push @args, '-Wl,--minor-image-version,0.0.9';
	}
	# add explicit path to libsass lib
	# needed to resolve lib from plugins
	unless ($^O eq 'MSWin32' && $Config{cc} =~ /^cl/) {
		push @args, '-Wl,-rpath,' . inst_lib($mm);
	}
	# -static-libgcc -static-libstdc++
	return join(' ', @args, @libs);
}


sub libsass_sassc
{
	# register our source and object files
	my @ret = 'SASSC_OBJ = plugins/sassc/sassc$(OBJ_EXT)';
	# location of the created object
	push @ret, 'SASSC_EXE = $(INST_BIN)/sassc$(EXE_EXT)';
	# create the target for the makefile
	push @ret, '$(SASSC_EXE): $(SASSC_OBJ) $(LIBSASS_LIB)';
	# need special path on windows and MSVC (cl)
	if ($^O eq 'MSWin32' && $Config{cc} =~ /^cl/) {
		die "plugins are not available under MSVC";
	}
	# otherwise we asume gcc
	else {
		# create the sassc executable by linking against sassc and libsass
		push @ret, "\t" . '$(LD) -o $(SASSC_EXE) $(LDFLAGS) $(SASSC_OBJ) $(LIBS)'
		         . ' ' . ($static ? '$(LIBSASS_OBJ)' : '-L$(INST_ARCHLIB) -lsass')
		         . ' $(OPTIMIZE) -lstdc++ -std=c++0x ' . join(" ", @libs)
		         . ($^O eq "linux" ? ' -ldl' : '')
		         . ' -Wl,-rpath,' . inst_lib($_[0]);
	}
	# add target to virtual "pure_all"
	push @cleanups, '$(SASSC_OBJ)';
	push @cleanups, '$(SASSC_EXE)';
	push @targets, '$(SASSC_EXE)';
	# return makefile part
	return join "\n", @ret;
}

sub libsass_lib
{
	# register our source and object files
	my @ret = 'LIBSASS_OBJ = ' . join(" ", @SOURCES);
	# location of the created object
	push @ret, 'LIBSASS_LIB = $(INST_ARCHLIB)/libsass.$(SO)';
	# create the target for the makefile
	push @ret, '$(LIBSASS_LIB): $(LIBSASS_OBJ)';
	# create the libsass shared library by linking against all objects
	push @ret, "\t" . compile_lib($_[0], '$(LIBSASS_LIB)') . ' $(LIBSASS_OBJ)';
	# add target to virtual "pure_all"
	push @cleanups, '$(LIBSASS_OBJ)';
	push @cleanups, '$(LIBSASS_LIB)';
	push @targets, '$(LIBSASS_LIB)';
	# return makefile part
	return join "\n", @ret;
}

sub libsass_plugin_math
{
	my @ret = 'MATH_OBJ = plugins/math/src/math$(OBJ_EXT)';
	# location of the created object
	push @ret, 'MATH_LIB = $(INST_ARCHAUTODIR)/plugins/math/math.$(SO)';
	# create the target for the makefile
	push @ret, '$(MATH_LIB): $(LIBSASS_LIB) $(MATH_OBJ)';
	# make sure the plugin path exists for output
	push @ret, "\t" . '$(MKPATH) $(INST_ARCHAUTODIR)/plugins/math';
	# create the libsass shared library by linking against all objects
	push @ret, "\t" . compile_lib($_[0], '$(MATH_LIB)') . ' $(MATH_OBJ)'
		     . ' ' . ($static ? '$(LIBSASS_OBJ)' : '-L$(INST_ARCHLIB) -lsass');
	# add target to virtual "pure_all"
	push @cleanups, '$(MATH_OBJ)';
	push @cleanups, '$(MATH_LIB)';
	push @targets, '$(MATH_LIB)';
	# return makefile part
	return join "\n", @ret;
}

sub libsass_plugin_img_size
{
	my @ret = 'IMG_SIZE_OBJ = plugins/img-size/src/img-size$(OBJ_EXT)';
	# location of the created object
	push @ret, 'IMG_SIZE_LIB = $(INST_ARCHAUTODIR)/plugins/img-size/img-size.$(SO)';
	# create the target for the makefile
	push @ret, '$(IMG_SIZE_LIB): $(LIBSASS_LIB) $(IMG_SIZE_OBJ)';
	# make sure the plugin path exists for output
	push @ret, "\t" . '$(MKPATH) $(INST_ARCHAUTODIR)/plugins/img-size';
	# create the libsass shared library by linking against all objects
	push @ret, "\t" . compile_lib($_[0], '$(IMG_SIZE_LIB)') . ' $(IMG_SIZE_OBJ)'
		     . ' ' . ($static ? '$(LIBSASS_OBJ)' : '-L$(INST_ARCHLIB) -lsass');
	# add target to virtual "pure_all"
	push @cleanups, '$(IMG_SIZE_OBJ)';
	push @cleanups, '$(IMG_SIZE_LIB)';
	push @targets, '$(IMG_SIZE_LIB)';
	# return makefile part
	return join "\n", @ret;
}

sub libsass_plugin_digest
{
	my @ret = 'DIGEST_OBJ = ' . join' ',
		'plugins/digest/src/digest$(OBJ_EXT)',
		'plugins/digest/vendor/md5/md5$(OBJ_EXT)',
		'plugins/digest/vendor/b64/cencode$(OBJ_EXT)',
		'plugins/digest/vendor/crc/crc_16$(OBJ_EXT)',
		'plugins/digest/vendor/crc/crc_32$(OBJ_EXT)';
	# location of the created object
	push @ret, 'DIGEST_LIB = $(INST_ARCHAUTODIR)/plugins/digest/digest.$(SO)';
	# create the target for the makefile
	push @ret, '$(DIGEST_LIB): $(LIBSASS_LIB) $(DIGEST_OBJ)';
	# make sure the plugin path exists for output
	push @ret, "\t" . '$(MKPATH) $(INST_ARCHAUTODIR)/plugins/digest';
	# create the libsass shared library by linking against all objects
	push @ret, "\t" . compile_lib($_[0], '$(DIGEST_LIB)') . ' $(DIGEST_OBJ)'
	         . ' ' . ($static ? '$(LIBSASS_OBJ)' : '-L$(INST_ARCHLIB) -lsass');
	# add target to virtual "pure_all"
	push @cleanups, '$(DIGEST_OBJ)';
	push @cleanups, '$(DIGEST_LIB)';
	push @targets, '$(DIGEST_LIB)';
	# return makefile part
	return join "\n", @ret;
}

sub libsass_plugin_glob
{
	my @ret = 'GLOB_OBJ = plugins/glob/src/glob$(OBJ_EXT)'
	        . ' plugins/glob/vendor/FS$(OBJ_EXT)';
	# location of the created object
	push @ret, 'GLOB_LIB = $(INST_ARCHAUTODIR)/plugins/glob/glob.$(SO)';
	# special case (does not compile with perl inc path)
	# readdir and friends were not available from headers
	push @ret, 'plugins/glob/vendor/FS$(OBJ_EXT):';
	push @ret, "\t" . '$(CCCMD) $(CCCDLFLAGS) $(PASTHRU_DEFINE) $(DEFINE) -xc++ -std=c++0x $*.cpp';
	# create the target for the makefile
	push @ret, '$(GLOB_LIB): $(LIBSASS_LIB) $(GLOB_OBJ)';
	# make sure the plugin path exists for output
	push @ret, "\t" . '$(MKPATH) $(INST_ARCHAUTODIR)/plugins/glob';
	# create the libsass shared library by linking against all objects
	push @ret, "\t" . compile_lib($_[0], '$(GLOB_LIB)') . ' $(GLOB_OBJ)'
	         . ' ' . ($static ? '$(LIBSASS_OBJ)' : '-L$(INST_ARCHLIB) -lsass');
	# add target to virtual "pure_all"
	push @cleanups, '$(GLOB_OBJ)';
	push @cleanups, '$(GLOB_LIB)';
	push @targets, '$(GLOB_LIB)';
	# return makefile part
	return join "\n", @ret;
}

my $ran = 0;
sub runOnce
{
	return if $ran;
	# get instance
	my $mm = shift;
	# collect Makefile commands
	@commands = (
		# call parent class first
		$mm->SUPER::postamble,
	);
	if ($install_plugins || $install_sassc) {
		push @commands, '', libsass_lib($mm);
	}
	if ($install_sassc) {
		push @commands, '', libsass_sassc($mm);
	}
	if ($install_plugins) {
		push @commands, '', libsass_plugin_glob($mm);
		push @commands, '', libsass_plugin_math($mm);
		push @commands, '', libsass_plugin_img_size($mm);
		# needs a few C-API changes not yet released
		# push @commands, '', libsass_plugin_digest();
	}
	# add new targets to virtual Makefile targets
	push @commands, '', 'pure_all :: ' . join(" ", @targets);
	# mark as run once
	$ran = 1;
};

# main overload
sub postamble
{
	# get instance
	my $mm = shift;
	runOnce($mm);
	# return code for Makefile
	return join "\n", @commands;
}

# cleanups
sub clean
{
	# get instance
	my $mm = shift;
	runOnce($mm);
	# collect parent clean targets
	return $mm->SUPER::clean . "\t- \$(RM_F) \\\n"
	       . join("\n",	map { "\t  $_ \\" } @cleanups);
}
