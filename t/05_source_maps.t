# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 17;

use CSS::Sass;

sub read_file
{
  local $/=undef;
  open my $fh, $_[0] or die "Couldn't open file: $!";
  binmode $fh; return <$fh>;
}

my $sass;
my ($r, $err, $stat);
my ($src, $expect);
my $ignore_whitespace = 0;

my %options = ( source_map_file => 'test.map', dont_die => 1);

$sass = CSS::Sass->new(include_paths => ['t/inc'], %options);
($r, $stat) = $sass->compile_file('t/inc/sass/test-incs.sass');
$expect = read_file('t/inc/scss/test-incs.scss');
$expect =~ s/[\r\n]+/\n/g if $ignore_whitespace;
$r =~ s/[\r\n]+/\n/g if $ignore_whitespace;
chomp($expect) if $ignore_whitespace;
chomp($r) if $ignore_whitespace;
ok    ($stat->{'source_map_string'},                    "Created source map 1");
like  ($r, qr/# sourceMappingURL=\.\.\/\.\.\/\.\.\/test.map/, "SourceMap relative url test 1");

$sass = CSS::Sass->new(include_paths => ['t/inc'], %options, source_map_comment => 0);
($r, $stat) = eval { $sass->compile_file('sass/test-incs.sass') };
$expect = read_file('t/inc/scss/test-incs.scss');
$expect =~ s/[\r\n]+/\n/g if $ignore_whitespace;
$r =~ s/[\r\n]+/\n/g if $ignore_whitespace;
chomp($expect) if $ignore_whitespace;
chomp($r) if $ignore_whitespace;

ok    ($stat->{'source_map_string'},                    "Created source map 2");
unlike  ($r, qr/# sourceMappingURL=\.\.\/\.\.\/\.\.\/test.map/, "SourceMap relative url test 2");

$sass = CSS::Sass->new(include_paths => ['t/inc'], %options);
($r, $stat) = $sass->compile_file('t/inc/sass/test-incs.sass');
ok    ($stat->{'source_map_string'},                    "Created source map 3");
like  ($r, qr/# sourceMappingURL=\.\.\/\.\.\/\.\.\/test.map/, "SourceMap relative url test 3");

$sass = CSS::Sass->new(include_paths => ['t/inc'], %options);
($r, $stat) = $sass->compile_file('sass/test-incs.sass');
ok    ($stat->{'source_map_string'},                    "Created source map 4");
like  ($r, qr/# sourceMappingURL=\.\.\/test.map/, "SourceMap relative url test 4");

$options{'output_path'} = 'some/dir/output.css';

$sass = CSS::Sass->new(include_paths => ['t/inc'], %options);
($r, $stat) = $sass->compile_file('sass/test-incs.sass');
ok    ($stat->{'source_map_string'},                    "Created source map 5");
like  ($r, qr/# sourceMappingURL=\.\.\/\.\.\/test.map/, "SourceMap relative url test 5");

$sass = CSS::Sass->new(include_paths => ['t/inc'], %options);
($r, $stat) = $sass->compile('A { color: red }');
ok    ($stat->{'source_map_string'},                    "Created source map 6");
like  ($r, qr/# sourceMappingURL=\.\.\/\.\.\/test.map/, "SourceMap relative url test 6");

$sass = CSS::Sass->new(include_paths => ['t/inc'], %options, source_comments => 1, omit_source_map => 1);
($r, $stat) = $sass->compile_file('sass/test-incs.sass');
ok    ($stat->{'source_map_string'},                    "Created source map 7");
like  ($r, qr{line 1, t/inc/sass/test-inc-01.sass}, "SourceMap relative url test 7");

$options{'source_map_root'} = '/foo/bar';

$sass = CSS::Sass->new(include_paths => ['t/inc'], %options, source_comments => 1, omit_source_map => 1);
($r, $stat) = $sass->compile('A { color: red }');
ok    ($stat->{'source_map_string'},                    "Created source map 8");
like  ($r, qr/line 1, stdin/, "SourceMap relative url test 8");

like  ($stat->{"source_map_string"}, qr/"sourceRoot":\s*"\/foo\/bar",/, "sourceRoot option is passed through");
