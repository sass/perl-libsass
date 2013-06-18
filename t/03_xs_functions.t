# -*- perl -*-

# Usefult for debugging the xs with prints:
# cd text-sass-xs && ./Build && perl -Mlib=blib/arch -Mlib=blib/lib t/03_xs_functions.t

use strict;
use warnings;

use Test::More tests => 42;

use CSS::Sass;

no warnings;
sub CSS::Sass::sass_function_callback { # Override the fancy .pm stuff so we test right to the metal.
    shift->(@_);
}
use warnings;

my $r;
# Boolean input/output
$r = CSS::Sass::compile_sass('.valid { color: test(false); }', {
    sass_functions => [ [ 'test($x)' => sub { [ CSS::Sass::SASS_BOOLEAN, !$_[1]->[1] ]} ] ]});
is    ($r->{error_status},  0,                                    "sass_function boolean no error_status");
is    ($r->{error_message}, undef,                                "sass_function boolean error_message is undef");
like  ($r->{output_string}, qr@color: true;@,                     "sass_function boolean works");

# Number input/output
$r = CSS::Sass::compile_sass('.valid { color: test(4); }', {
    sass_functions => [ [ 'test($x)' => sub { [ CSS::Sass::SASS_NUMBER, $_[1]->[1]*2 ]} ] ]});
is    ($r->{error_status},  0,                                    "sass_function number no error_status");
is    ($r->{error_message}, undef,                                "sass_function number error_message is undef");
like  ($r->{output_string}, qr@color: 8;@,                        "sass_function number works");

# Percentage input/output
$r = CSS::Sass::compile_sass('.valid { color: test(40%); }', {
    sass_functions => [ [ 'test($x)' => sub { [ CSS::Sass::SASS_PERCENTAGE, $_[1]->[1]*2 ]} ] ]});
is    ($r->{error_status},  0,                                      "sass_function percentage no error_status");
is    ($r->{error_message}, undef,                                  "sass_function percentage error_message is undef");
like  ($r->{output_string}, qr@color: 80%;@,                        "sass_function percentage works");

# Dimension input/output
$r = CSS::Sass::compile_sass('.valid { color: test(40cubits); }', {
    sass_functions => [ [ 'test($x)' => sub { [ CSS::Sass::SASS_DIMENSION, $_[1]->[1]*2, $_[1]->[2]."pergallon" ]} ] ]});
is    ($r->{error_status},  0,                                      "sass_function dimension no error_status");
is    ($r->{error_message}, undef,                                  "sass_function dimension error_message is undef");
like  ($r->{output_string}, qr@color: 80cubitspergallon;@,          "sass_function dimension works");

# Color input/output
$r = CSS::Sass::compile_sass('.valid { color: test(rgba(30,30,30,.10)); }', {
    sass_functions => [ [ 'test($x)' => sub { [ CSS::Sass::SASS_COLOR, $_[1]->[1]/2, $_[1]->[2]/2,
                                                $_[1]->[3]/2, $_[1]->[4]/2 ]} ] ]});
is    ($r->{error_status},  0,                                      "sass_function color no error_status");
is    ($r->{error_message}, undef,                                  "sass_function color error_message is undef");
like  ($r->{output_string}, qr@color: rgba\(15, 15, 15, 0.05\);@,   "sass_function color works");

# String input/output
$r = CSS::Sass::compile_sass('.valid { color: test("a b c"); }', {
    sass_functions => [ [ 'test($x)' => sub {
                              my $str = $_[1]->[1];
                              $str =~ s/^"(.*)"$/$1/;
                              [ CSS::Sass::SASS_STRING, "\"$str$str\"" ]} ] ]});
is    ($r->{error_status},  0,                                      "sass_function string no error_status");
is    ($r->{error_message}, undef,                                  "sass_function string error_message is undef");
like  ($r->{output_string}, qr@color: a b ca b c;@,                 "sass_function string works");

# Error output
$r = CSS::Sass::compile_sass('.valid { color: test(doesnt matter); }', {
    sass_functions => [ [ 'test($x)' => sub { [ CSS::Sass::SASS_ERROR, "Fake Error" ] } ] ]});
is    ($r->{error_status},  1,                                      "sass_function error has error_status");
like  ($r->{error_message}, qr/Fake Error/,                         "sass_function error error_message is returned from function");
is    ($r->{output_string}, undef,                                  "sass_function error fails");

# List output
$r = CSS::Sass::compile_sass('.valid { color: test(5%); }', {
    sass_functions => [ [ 'test($x)' => sub { [ CSS::Sass::SASS_LIST, CSS::Sass::SASS_COMMA,
                                                $_[1], $_[1], $_[1] ] } ] ]});
is    ($r->{error_status},  0,                                      "sass_function comma list no error_status");
is    ($r->{error_message}, undef,                                  "sass_function comma list error_message is undef");
like  ($r->{output_string}, qr@color: 5%, 5%, 5%;@,                 "sass_function comma list works");

$r = CSS::Sass::compile_sass('.valid { color: test(5%); }', {
    sass_functions => [ [ 'test($x)' => sub { [ CSS::Sass::SASS_LIST, CSS::Sass::SASS_SPACE,
                                                $_[1], $_[1], $_[1] ] } ] ]});
is    ($r->{error_status},  0,                                      "sass_function space list no error_status");
is    ($r->{error_message}, undef,                                  "sass_function space list error_message is undef");
like  ($r->{output_string}, qr@color: 5% 5% 5%;@,                   "sass_function space list works");

# List input/output
$r = CSS::Sass::compile_sass('.valid { color: test(1, 5%, rgba(4,3,2,.5)); }', {
    sass_functions => [ [ 'test($x,$y,$z)' => sub { [ CSS::Sass::SASS_LIST, CSS::Sass::SASS_COMMA,
                                                      $_[3], $_[2], $_[1] ] } ] ]});
is    ($r->{error_status},  0,                                      "sass_function list i/o no error_status");
is    ($r->{error_message}, undef,                                  "sass_function list i/o error_message is undef");
like  ($r->{output_string}, qr@color: rgba\(4, 3, 2, 0.5\), 5%, 1;@,"sass_function list i/o works");

# Invalid tag
$r = CSS::Sass::compile_sass('.valid { color: test(1, 5%, rgba(4,3,2,.5)); }', {
    sass_functions => [ [ 'test($x,$y,$z)' => sub { [ 123456, 1,2,3,4, $_[3], $_[2], $_[1] ] } ] ]});
is    ($r->{error_status},  1,                                      "sass_function bad tag has error_status");
like  ($r->{error_message}, qr/123456/,                             "sass_function bad tag error_message contains bad tag");
is    ($r->{output_string}, undef,                                  "sass_function bad tag fails");

# Wrong type
$r = CSS::Sass::compile_sass('.valid { color: test(1, 5%, rgba(4,3,2,.5)); }', {
    sass_functions => { x=> [ 'test($x,$y,$z)' => sub { [ 123456, 1,2,3,4, $_[3], $_[2], $_[1] ] } ] }});
is    ($r->{error_status},  1,                                      "sass_function bad type has error_status");
like  ($r->{error_message}, qr/sass_functions.*arrayref/,           "sass_function bad type error_message explains itself");
is    ($r->{output_string}, undef,                                  "sass_function bad type fails");

$r = CSS::Sass::compile_sass('.valid { color: test(1, 5%, rgba(4,3,2,.5)); }', {
    sass_functions => [ { 'test($x,$y,$z)' => sub { [ 123456, 1,2,3,4, $_[3], $_[2], $_[1] ] } } ]});
is    ($r->{error_status},  1,                                      "sass_function bad entry type has error_status");
like  ($r->{error_message}, qr/sass_function entry.*arrayref/,      "sass_function bad entry type error_message explains itself");
is    ($r->{output_string}, undef,                                  "sass_function bad entry type fails");

$r = CSS::Sass::compile_sass('.valid { color: test(1, 5%, rgba(4,3,2,.5)); }', {
    sass_functions => [ [ 'test($x,$y,$z)' => sub { { 123456 => $_[3], $_[2] => $_[1] } } ] ]});
is    ($r->{error_status},  1,                                      "sass_function bad perl type has error_status");
like  ($r->{error_message}, qr/perl type.*arrayref/,                "sass_function bad perl type error_message explains itself");
is    ($r->{output_string}, undef,                                  "sass_function bad perl type fails");

