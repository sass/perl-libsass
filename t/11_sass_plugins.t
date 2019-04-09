# -*- perl -*-

use utf8;
use strict;
use warnings;

use CSS::Sass;

use CSS::Sass::Plugins qw(%plugins);

use Test::More tests => 7;

my ($r, $err, $rv);

if (exists $plugins{"glob"}) {
  my %options = ( "plugin_paths" => [$plugins{"glob"}] );
  ($r, $err, $rv) = CSS::Sass::sass_compile('@import "t/inc/**/ba*.scss"', %options);
  like  ($rv->{included_files}->[0],   qr/bar\.scss$/,   "Correct first import found");
  like  ($rv->{included_files}->[1],   qr/baz\.scss$/,   "Correct first import found");
  is    ($err, undef,                                    "Import did not fail");
} else {
  SKIP: { skip("glob plugin not installed", 3); }
}

if (exists $plugins{"math"}) {
  my %options = ( "plugin_paths" => [$plugins{"math"}] );
  ($r, $err) = CSS::Sass::sass_compile('test { sin: sin($TAU); }', %options);
  like  ($r,   qr/sin: 0;/,                              "Sass math plugin works");
  is    ($err, undef,                                    "Sass math plugin did not fail");
} else {
  SKIP: { skip("math plugin not installed", 2); }
}

if (exists $plugins{"img-size"}) {
  my %options = ( "plugin_paths" => [$plugins{"img-size"}] );
  ($r, $err) = CSS::Sass::sass_compile('test { img: img-size("t/inc/test.png"); }', %options);
  like  ($r,   qr/img: 84px 42px;/,                      "Sass img-size plugin works");
  is    ($err, undef,                                    "Sass img-size plugin did not fail");
} else {
  SKIP: { skip("img-size plugin not installed", 2); }
}
