# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 16;

BEGIN { use_ok('CSS::Sass') };

my ($r, $err, $stat);

($r, $err, $stat) = CSS::Sass::sass_compile('@import "http://www.host.dom/red";',
    source_map_file => "test.css.map",
    importer => sub {
      if ($_[0] eq "http://www.host.dom/red") {
        is ($_[1], "stdin", "import parent[0]");
        return [["red.css", '@import "green";']];
      }
      if ($_[0] eq "green") {
        is ($_[1], "red.css", "import parent[1]");
        return [['http://www.host.dom/green', '@import "yellow";']];
      }
      is ($_[1], "http://www.host.dom/green", "import parent[2]");
      return [['http://www.host.dom/final', 'A { color: ' . $_[0] . '; }']]; # yellow
    }
);

like  ($r,   qr/color:\s*yellow;/,                     "Custom importer works");
is    ($err, undef,                                    "Custom importer returns no errors");

is    (scalar(@{$stat->{'included_files'}}), 3,        "included_files has correct size");
is    ($stat->{'included_files'}->[0], "green", "included_files[0] has correct url");
is    ($stat->{'included_files'}->[1], "http://www.host.dom/red", "included_files[1] has correct url");
is    ($stat->{'included_files'}->[2], "yellow", "included_files[2] has correct url");


## from https://github.com/sass/libsass/pull/691#issuecomment-67130937

my %files = (

  "index.scss" => "
    \@import 'foo.scss';
    \@import 'bar.scss';
  ",
  "foo.scss" => "
    \@import 'bar2.scss';
    body { color: red; }
  ",
  "bar.scss" => "
    p { color: grey; }
  ",
  "bar2.scss" => "
    span { z-index: 4; }
  "
);

my $expected = "span {
  z-index: 4; }

body {
  color: red; }

p {
  color: grey; }

/*# sourceMappingURL=index.css.map */";

($r, $err, $stat) = CSS::Sass::sass_compile(
    $files{'index.scss'},
    input_file => "index.scss",
    output_file => "index.css",
    source_map_file => "index.css.map",
    importer => sub {
      return $_[0] unless exists $files{$_[0]};
      return [ [ $_[0], $files{$_[0]} ] ];
    }
);

is  ($err, undef,                         "Custom importer has no error");
is  ($r,   $expected,                     "Custom importer yields expected result");

is    (scalar(@{$stat->{'included_files'}}), 3,     "included_files has correct size");
is    ($stat->{'included_files'}->[0], "bar.scss",  "included_files[0] has correct url");
is    ($stat->{'included_files'}->[1], "bar2.scss", "included_files[1] has correct url");
is    ($stat->{'included_files'}->[2], "foo.scss",  "included_files[2] has correct url");
