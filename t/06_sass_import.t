# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 10;

use CSS::Sass qw(sass2scss);

sub read_file
{
  local $/=undef;
  open my $fh, $_[0] or die "Couldn't open file: $!";
  binmode $fh; return <$fh>;
}

my $sass;
my ($r, $stats, $map, $err);
my ($src, $expect);
my $ignore_whitespace = 0;

my %mapopt = (source_map_file => 'test.map', omit_source_map => 1);

$mapopt{'sass_functions'}->{'custom()'} = sub { 'red' };

$sass = CSS::Sass->new(include_paths => ['t/inc'], %mapopt);
($r, $stats) = $sass->compile_file('t/inc/sass/test-incs.sass');
$expect = read_file('t/inc/scss/test-incs.scss');
$expect =~ s/[\r\n]+/\n/g if $ignore_whitespace;
$r =~ s/[\r\n]+/\n/g if $ignore_whitespace;
chomp($expect) if $ignore_whitespace;
chomp($r) if $ignore_whitespace;

is    ($r, $expect,                                    "Handle SASS imports relative to file");
is    ($err, undef,                                    "Handle SASS imports relative to file");

$sass = CSS::Sass->new(include_paths => ['t/inc'], %mapopt);
($r, $stats) = eval { $sass->compile_file('sass/test-incs.sass') };
$expect = read_file('t/inc/scss/test-incs.scss');
$expect =~ s/[\r\n]+/\n/g if $ignore_whitespace;
$r =~ s/[\r\n]+/\n/g if $ignore_whitespace;
chomp($expect) if $ignore_whitespace;
chomp($r) if $ignore_whitespace;

is    ($r, $expect,                                    "Handle SASS imports relative to inc path");
is    ($err, undef,                                    "Handle SASS imports relative to inc path");

$sass = CSS::Sass->new(include_paths => ['t/inc/sass'], %mapopt);
my $input = read_file('t/inc/sass/test-incs.sass');
die "could not read t/inc/sass/test-incs.sass" unless $input;
($r, $stats) = eval { $sass->compile(sass2scss($input, 1)) };
$expect = read_file('t/inc/scss/test-incs.scss');
$expect =~ s/[\r\n]+/\n/g if $ignore_whitespace;
$r =~ s/[\r\n]+/\n/g if $ignore_whitespace;
chomp($expect) if $ignore_whitespace;
chomp($r) if $ignore_whitespace;

is    ($r, $expect,                                    "Handle SASS imports relative to inc path (string data)");
is    ($err, undef,                                    "Handle SASS imports relative to inc path (string data)");

chdir "t";

$sass = CSS::Sass->new(include_paths => ['inc/sass'], input_path => 'virtual.sass', %mapopt);
$input = read_file('inc/sass/test-incs.sass');
die "could not read inc/sass/test-incs.sass" unless $input;
($r, $stats) = $sass->compile(sass2scss($input, 1));
$map = $stats->{'source_map_string'};
$expect = read_file('inc/scss/test-incs.scss');
$expect =~ s/[\r\n]+/\n/g if $ignore_whitespace;
$r =~ s/[\r\n]+/\n/g if $ignore_whitespace;
chomp($expect) if $ignore_whitespace;
chomp($r) if $ignore_whitespace;

is    ($r, $expect,                                    "Handle SASS imports relative to inc path (string data)");
is    ($err, undef,                                    "Handle SASS imports relative to inc path (string data)");
ok    ($map =~ m/virtual\.sass/,                       "Can overwrite input_path for string compilation");
is    ($stats->{'included_files'}->[0], 'inc/sass/test-inc-01.sass', "Got the correct include in status array");

chdir "..";