# -*- perl -*-

# Usefult for debugging the xs with prints:
# cd text-sass-xs && ./Build && perl -Mlib=blib/arch -Mlib=blib/lib t/04_perl_functions.t

use strict;
use warnings;

use Test::More tests => 20;

use CSS::Sass;

use Data::Dumper;
#use CSS::Sass::Type;

my ($r, $err);
# Boolean input/output
($r, $err) = CSS::Sass::sass_compile('.valid { color: test(false); }',
    sass_functions => { 'test($x)' => sub { CSS::Sass::Type::Boolean->new(!shift->value) } } );
like  ($r,   qr/color: true;/,                         "Sass function boolean works");
is    ($err, undef,                                    "Sass function boolean returns no errors");

# Number input/output
($r, $err) = CSS::Sass::sass_compile('.valid { color: test(40); }',
    sass_functions => { 'test($x)' => sub { CSS::Sass::Type::Number->new(shift->value**2) } } );
like  ($r,   qr/color: 1600;/,                         "Sass function number works");
is    ($err, undef,                                    "Sass function number returns no errors");

# Percentage input/output
($r, $err) = CSS::Sass::sass_compile('.valid { color: test(40%); }',
    sass_functions => { 'test($x)' => sub { CSS::Sass::Type::Percentage->new(shift->value/2) } } );
like  ($r,   qr/color: 20%;/,                          "Sass function percentage works");
is    ($err, undef,                                    "Sass function percentage returns no errors");

# Dimension input/output
($r, $err) = CSS::Sass::sass_compile('.valid { color: test(20rods); }',
    sass_functions => { 'test($x)' => sub { CSS::Sass::Type::Dimension->new($_[0]->value*2,
                                                                            $_[0]->units."perhogshead") } } );
like  ($r,   qr/color: 40rodsperhogshead;/,            "Sass function dimension works");
is    ($err, undef,                                    "Sass function dimension returns no errors");

# Color input/output
($r, $err) = CSS::Sass::sass_compile('.valid { color: test(rgba(40,30,20,.3)); }',
    sass_functions => { 'test($x)' => sub { CSS::Sass::Type::Color->new($_[0]->r*2, $_[0]->g*2, $_[0]->b*2, $_[0]->a*2) } } );
like  ($r,   qr/color: rgba\(80, 60, 40, 0.6\);/,      "Sass function color works");
is    ($err, undef,                                    "Sass function color returns no errors");

# String input/output
($r, $err) = CSS::Sass::sass_compile(".valid { color: test('x y z'); }",
    sass_functions => { 'test($x)' => sub { CSS::Sass::Type::String->new($_[0]->value . "_" . $_[0]->value) } } );
like  ($r,   qr/color: x y z_x y z;/,                  "Sass function string works");
is    ($err, undef,                                    "Sass function string returns no errors");

# Error output
($r, $err) = CSS::Sass::sass_compile('.valid { color: test("x"); }',
    sass_functions => { 'test($x)' => sub { die "Perl Error" } } );
is    ($r,   undef,                                    "Sass function die returns no css");
like  ($err, qr/Perl Error/,                           "Sass function die returns informative error message");


# List output
($r, $err) = CSS::Sass::sass_compile(".valid { color: test(5%); }",
    sass_functions => { 'test($x)' => sub { CSS::Sass::Type::List->new(CSS::Sass::SASS_COMMA,
                                                                       [ CSS::Sass::Type::Percentage->new($_[0]->value * 2),
                                                                         CSS::Sass::Type::Percentage->new($_[0]->value * 3),
                                                                         CSS::Sass::Type::Percentage->new($_[0]->value * 4) ])
                                          } } );
like  ($r,   qr/color: 10%, 15%, 20%;/,                "Sass function comma list works");
is    ($err, undef,                                    "Sass function comma list returns no errors");

($r, $err) = CSS::Sass::sass_compile(".valid { color: test(5%); }",
    sass_functions => { 'test($x)' => sub { CSS::Sass::Type::List->new(CSS::Sass::SASS_SPACE,
                                                                       [ CSS::Sass::Type::Percentage->new($_[0]->value * 2),
                                                                         CSS::Sass::Type::Percentage->new($_[0]->value * 3),
                                                                         CSS::Sass::Type::Percentage->new($_[0]->value * 4) ])
                                          } } );
like  ($r,   qr/color: 10% 15% 20%;/,                  "Sass function space list works");
is    ($err, undef,                                    "Sass function space list returns no errors");

# List input/output
($r, $err) = CSS::Sass::sass_compile(".valid { color: test(5%,40in,rgba(4,3,2,.5)); }",
    sass_functions => { 'test($x,$y,$z)' => sub { CSS::Sass::Type::List->new(CSS::Sass::SASS_SPACE,
                                                                       [ $_[2], $_[1], $_[0] ]) } });
like  ($r,   qr/color: rgba\(4, 3, 2, 0.5\) 40in 5%;/, "Sass function list i/o works");
is    ($err, undef,                                    "Sass function list i/o returns no errors");
