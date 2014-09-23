# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 4;

use CSS::Sass;

sub read_file
{
  local $/=undef;
  open my $fh, $_[0] or die "Couldn't open file: $!";
  binmode $fh; return <$fh>;
}

my $sass;
my ($r, $err);
my ($src, $expect);
my $ignore_whitespace = 0;

$sass = CSS::Sass->new(include_paths => ['t/inc']);
$r = eval { $sass->compile_file('t/inc/sass/test-incs.sass') };
$expect = read_file('t/inc/scss/test-incs.scss');
$expect =~ s/[\r\n]+/\n/g if $ignore_whitespace;
$r =~ s/[\r\n]+/\n/g if $ignore_whitespace;
chomp($expect) if $ignore_whitespace;
chomp($r) if $ignore_whitespace;

is    ($r, $expect,                                    "Handle SASS imports relative to file");
is    ($err, undef,                                    "Handle SASS imports relative to file");

$sass = CSS::Sass->new(include_paths => ['t/inc']);
$r = eval { $sass->compile_file('sass/test-incs.sass') };
$expect = read_file('t/inc/scss/test-incs.scss');
$expect =~ s/[\r\n]+/\n/g if $ignore_whitespace;
$r =~ s/[\r\n]+/\n/g if $ignore_whitespace;
chomp($expect) if $ignore_whitespace;
chomp($r) if $ignore_whitespace;

is    ($r, $expect,                                    "Handle SASS imports relative to inc path");
is    ($err, undef,                                    "Handle SASS imports relative to inc path");
