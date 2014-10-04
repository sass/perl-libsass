# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 8;

use CSS::Sass;

sub read_file
{
  local $/=undef;
  open my $fh, $_[0] or die "Couldn't open file: $!";
  binmode $fh; return <$fh>;
}

my $sass;
my ($r, $err, $smap);
my ($src, $expect);
my $ignore_whitespace = 0;

my %options = ( source_map_file => 'test.map', dont_die => 1);

$sass = CSS::Sass->new(include_paths => ['t/inc'], %options);
($r, $smap) = $sass->compile_file('t/inc/sass/test-incs.sass');
$expect = read_file('t/inc/scss/test-incs.scss');
$expect =~ s/[\r\n]+/\n/g if $ignore_whitespace;
$r =~ s/[\r\n]+/\n/g if $ignore_whitespace;
chomp($expect) if $ignore_whitespace;
chomp($r) if $ignore_whitespace;
ok    ($smap,                                    "Created source map 1");
like  ($r, qr/# sourceMappingURL=\.\.\/\.\.\/\.\.\/test.map/, "SourceMap relative url test 1");

$sass = CSS::Sass->new(include_paths => ['t/inc'], %options, source_map_comment => 0);
($r, $smap) = eval { $sass->compile_file('sass/test-incs.sass') };
$expect = read_file('t/inc/scss/test-incs.scss');
$expect =~ s/[\r\n]+/\n/g if $ignore_whitespace;
$r =~ s/[\r\n]+/\n/g if $ignore_whitespace;
chomp($expect) if $ignore_whitespace;
chomp($r) if $ignore_whitespace;

ok    ($smap,                                    "Created source map 2");
unlike  ($r, qr/# sourceMappingURL=\.\.\/\.\.\/\.\.\/test.map/, "SourceMap relative url test 2");

$sass = CSS::Sass->new(include_paths => ['t/inc'], %options, source_map_comment => 1);
($r, $smap) = $sass->compile_file('t/inc/sass/test-incs.sass');
ok    ($smap,                                    "Created source map 3");
like  ($r, qr/# sourceMappingURL=\.\.\/\.\.\/\.\.\/test.map/, "SourceMap relative url test 3");

$sass = CSS::Sass->new(include_paths => ['t/inc'], %options, source_map_comment => 1);
($r, $smap) = $sass->compile_file('sass/test-incs.sass');
ok    ($smap,                                    "Created source map 4");
like  ($r, qr/# sourceMappingURL=\.\.\/test.map/, "SourceMap relative url test 4");
