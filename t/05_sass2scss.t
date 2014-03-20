# -*- perl -*-

# Usefult for debugging the xs with prints:
# cd text-sass-xs && ./Build && perl -Mlib=blib/arch -Mlib=blib/lib t/04_perl_functions.t

use strict;
use warnings;

use Test::More tests => 10;

use CSS::Sass;

use Data::Dumper;
#use CSS::Sass::Type;

my $sass = <<SASS;

outer
  inner
    color: red

SASS

my $pretty0 = 'outer { inner { color: red; } }';

my $pretty1 = <<SASS;
outer {
  inner {
    color: red; } }
SASS

my $pretty2 = <<SASS;
outer {
  inner {
    color: red;
  }
}
SASS

my $pretty3 = <<SASS;
outer
{
  inner
  {
    color: red;
  }
}
SASS



my ($r, $err);

($r, $err) = CSS::Sass::sass2scss($sass);
is    ($r,   $pretty1,                                 "Sass to scss converter works");
is    ($err, undef,                                    "Sass to scss converter");

($r, $err) = CSS::Sass::sass2scss($sass, 0);
is    ($r,   $pretty0,                                 "Sass to scss converter works");
is    ($err, undef,                                    "Sass to scss converter (pretty 0)");

($r, $err) = CSS::Sass::sass2scss($sass, 1);
is    ($r,   $pretty1,                                 "Sass to scss converter works");
is    ($err, undef,                                    "Sass to scss converter (pretty 1)");

($r, $err) = CSS::Sass::sass2scss($sass, 2);
is    ($r,   $pretty2,                                 "Sass to scss converter works");
is    ($err, undef,                                    "Sass to scss converter (pretty 2)");

($r, $err) = CSS::Sass::sass2scss($sass, 3);
is    ($r,   $pretty3,                                 "Sass to scss converter works");
is    ($err, undef,                                    "Sass to scss converter (pretty 3)");

