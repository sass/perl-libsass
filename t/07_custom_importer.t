# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 30;

BEGIN { use_ok('CSS::Sass') };

my ($r, $err, $stat);

($r, $err, $stat) = CSS::Sass::sass_compile('@import "http://www.host.dom/red";',
    source_map_file => "test.css.map",
    headers => [
      [sub { return [['header-02', 'div { b: .5; }']]; }, .5],
      [sub { return [['header-03', 'div { c: .1; }']]; }, .1],
      [sub { return [['header-01', 'div { @include mixme; }']]; }, .9],
      [sub { return [['mixin-01', '@mixin mixme { a: .9; }']]; }, 1009],
    ],
    importers => [[sub {

      if ($_[0] eq "http://www.host.dom/red") {
        is ($_[1], "stdin", "import parent[0]");
        return [["red.css", '@import "brown";']];
      }
      if ($_[0] eq "green") {
        is ($_[1], "red.css", "import parent[1]");
        return [['http://www.host.dom/green', '@import "yellow";']];
      }
      is ($_[1], "http://www.host.dom/green", "import parent[2]");
      return [['http://www.host.dom/final', 'A { color: ' . $_[0] . '; }']]; # yellow
    }, 10], [sub {

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
    }, 25]]
);

like  ($r,   qr/a:\s*\.9;.*b:\s*\.5;.*c:\s*\.1;/s,       "Custom header works");
like  ($r,   qr/color:\s*yellow;/,                     "Custom importer works");
is    ($err, undef,                                    "Custom importer returns no errors");

is    (scalar(@{$stat->{'included_files'}}), 3,        "included_files has correct size");
is    ($stat->{'included_files'}->[0], "http://www.host.dom/final", "included_files[0] has correct url");
is    ($stat->{'included_files'}->[1], "http://www.host.dom/green", "included_files[1] has correct url");
is    ($stat->{'included_files'}->[2], "red.css", "included_files[2] has correct url");

is    (scalar(@{$stat->{'included_files'}}), 3,        "included_files has correct size");

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

chomp ($r); $r =~ s/(?:\r?\n)+/\n/g;
chomp ($expected); $expected =~ s/(?:\r?\n)+/\n/g;

is  ($err, undef,                         "Custom importer has no error");
is  ($r,   $expected,                     "Custom importer yields expected result");

is    (scalar(@{$stat->{'included_files'}}), 3,     "included_files has correct size");
is    ($stat->{'included_files'}->[0], "bar.scss",  "included_files[0] has correct url");
is    ($stat->{'included_files'}->[1], "bar2.scss", "included_files[1] has correct url");
is    ($stat->{'included_files'}->[2], "foo.scss",  "included_files[2] has correct url");


####### load handling #######

($r, $err, $stat) = CSS::Sass::sass_compile(
    '@import "foobar";',
    importer => sub {
      return [
        "t/inc/_colors.scss",
        [ "t/inc/_colors.scss", undef, undef ],
        [ "non-existing-import", 'foo { color: $red; }', undef ]
      ];
    }
);

is ($r, "foo {\n  color: #ff1111; }\n", "correctly report error file");

####### load handling #######

($r, $err, $stat) = CSS::Sass::sass_compile(
    '@import "foobar";',
    importer => sub {
      return "t/inc/simple"
    }
);

is ($r, "foo {\n  color: red; }\n", "correctly report error file");

####### error handling #######

my $err_msg = "my error msg";

($r, $err, $stat) = CSS::Sass::sass_compile(
    $files{'index.scss'},
    input_file => "index.scss",
    output_file => "index.css",
    source_map_file => "index.css.map",
    importer => sub {
      if ($_[0] ne "bar2.scss") { return [ [ $_[0], $files{$_[0]}, "" ] ]; }
      else { return [ [ $_[0], $files{$_[0]}, "", $err_msg, 42, 84 ] ]; }
    }
);

is ($stat->{'error_file'}, "foo.scss", "correctly report error file");
is ($stat->{'error_status'}, 1, "correctly report error status");
is ($stat->{'error_line'}, 42+1, "correctly report error line");
is ($stat->{'error_column'}, 84+1, "correctly report error column");
is ($stat->{'error_text'}, $err_msg, "correctly report error text");

####### die handling #######

$err_msg = "sudden death\n";

($r, $err, $stat) = CSS::Sass::sass_compile(
    $files{'index.scss'},
    input_file => "index.scss",
    output_file => "index.css",
    source_map_file => "index.css.map",
    importer => sub {
      die $err_msg;
    }
);

is ($stat->{'error_file'}, "stdin", "correctly report error file");
is ($stat->{'error_status'}, 1, "correctly report error status");
is ($stat->{'error_line'}, 2, "correctly report error line");
is ($stat->{'error_column'}, 13, "correctly report error column");
is ($stat->{'error_text'}, $err_msg, "correctly report error text");
