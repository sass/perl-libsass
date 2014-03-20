# -*- perl -*-

# Usefult for debugging the xs with prints:
# cd text-sass-xs && ./Build && perl -Mlib=blib/arch -Mlib=blib/lib t/04_perl_functions.t

use strict;
use warnings;

use Test::More tests => 19;

use CSS::Sass;
use File::Slurp;
use Data::Dumper;

my $sass = read_file('t/inc/sass/pretty.sass');
my $pretty0 = read_file('t/inc/scss/pretty-0.scss');
my $pretty1 = read_file('t/inc/scss/pretty-1.scss');
my $pretty2 = read_file('t/inc/scss/pretty-2.scss');
my $pretty3 = read_file('t/inc/scss/pretty-3.scss');


my ($r, $err);

($r, $err) = CSS::Sass::sass2scss($sass);
is    ($r,   $pretty1,                                  "Default pretty print");

($r, $err) = CSS::Sass::sass2scss($sass, SASS2SCSS_PRETTYFY_0);
is    ($r,   $pretty0,                                 "Pretty print option 0");

($r, $err) = CSS::Sass::sass2scss($sass, SASS2SCSS_PRETTYFY_1);
is    ($r,   $pretty1,                                 "Pretty print option 1");

($r, $err) = CSS::Sass::sass2scss($sass, SASS2SCSS_PRETTYFY_2);
is    ($r,   $pretty2,                                 "Pretty print option 2");

($r, $err) = CSS::Sass::sass2scss($sass, SASS2SCSS_PRETTYFY_3);
is    ($r,   $pretty3,                                 "Pretty print option 3");


my ($src, $expect);

# \/\/\/ -- https://github.com/ArnaudRinquin/sass2scss/blob/master/test/ -- \/\/\/

$src = read_file('t/inc/sass/t-01.sass');
($r, $err) = CSS::Sass::sass2scss($src);
$expect = read_file('t/inc/scss/t-01.scss');

is    ($r, $expect,                                    "Very basic convertion");
is    ($err, undef,                                    "Very basic convertion");

$src = read_file('t/inc/sass/t-02.sass');
($r, $err) = CSS::Sass::sass2scss($src);
$expect = read_file('t/inc/scss/t-02.scss');

is    ($r, $expect,                                    "Converts sass mixin and include aliases");
is    ($err, undef,                                    "Converts sass mixin and include aliases");

$src = read_file('t/inc/sass/t-03.sass');
($r, $err) = CSS::Sass::sass2scss($src);
$expect = read_file('t/inc/scss/t-03.scss');

is    ($r, $expect,                                    "Ignore comments on block last line");
is    ($err, undef,                                    "Ignore comments on block last line");

$src = read_file('t/inc/sass/t-04.sass');
($r, $err) = CSS::Sass::sass2scss($src);
$expect = read_file('t/inc/scss/t-04.scss');

is    ($r, $expect,                                    "Handle selectors not containing alphanumeric characters");
is    ($err, undef,                                    "Handle selectors not containing alphanumeric characters");

# /\/\/\ -- https://github.com/ArnaudRinquin/sass2scss/blob/master/test/ -- /\/\/\

$src = read_file('t/inc/sass/t-05.sass');
($r, $err) = CSS::Sass::sass2scss($src);
$expect = read_file('t/inc/scss/t-05.scss');

is    ($r, $expect,                                    "Handle strange comment indentation");
is    ($err, undef,                                    "Handle strange comment indentation");

$src = read_file('t/inc/sass/t-06.sass');
($r, $err) = CSS::Sass::sass2scss($src);
$expect = read_file('t/inc/scss/t-06.scss');

is    ($r, $expect,                                    "Handle not closed multiline comments");
is    ($err, undef,                                    "Handle not closed multiline comments");

$src = read_file('t/inc/sass/t-07.sass');
($r, $err) = CSS::Sass::sass2scss($src);
$expect = read_file('t/inc/scss/t-07.scss');

is    ($r, $expect,                                    "Handle self closing multiline comments");
is    ($err, undef,                                    "Handle self closing multiline comments");

