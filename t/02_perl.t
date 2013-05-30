# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 19;
BEGIN { use_ok('CSS::Sass', qw(:DEFAULT sass_compile)) };

my $r;

# OO interface
my $sass = CSS::Sass->new;
$r = $sass->compile(".valid { color: red; }");
isnt  ($r,                undef,       "Successful compile returns something");

$r = eval { $sass->compile("this is invalid sass source") };
like  ($@,                qr/error:/, "Failed compile dies with error message");

$sass->options->{dont_die} = 1;
eval {
    $r = $sass->compile("this is invalid sass source");
    pass(                             "dont_die option doesn't die");
};
fail  (                               "dont_die option doesn't die") if $@;
is    ($r,                undef,      "dont_die option returns undef on error");
like  ($sass->last_error, qr/error:/, "Failed compile saves error message in last_error");


$sass->options->{dont_die} = 0;
$r = eval { $sass->compile('@import "colors"; .valid { color: $red; }') };
like  ($@,                  qr/error:/,  "failed import dies with error message");

$sass = CSS::Sass->new(include_paths => ['t/inc']);
$r = eval { $sass->compile('@import "colors"; .valid { color: $red; }') };
like  ($r,                  qr/#ff1111/, "import imported red");

unshift @{$sass->options->{include_paths}}, 't/nonexistent';
$r = eval { $sass->compile('@import "colors"; .valid { color: $red; }') };
like  ($r,                  qr/#ff1111/, "import imported red in the face of bad paths");


# Procedural interface
my $err;
($r, $err) = sass_compile(".valid { color: red; }");
isnt  ($r,                  undef,       "Successful compile returns something");
is    ($err,                undef,       "Successful compile returns no errors");

($r, $err) = sass_compile("this is invalid sass source");
is    ($r,                  undef,       "Failed compile returns no code");
like  ($err,                qr/error:/,  "Failed compile returns an error");

$r = sass_compile(".valid { color: red; }");
isnt  ($r,                  undef,       "Successful compile scalar context returns something");

$r = sass_compile("this is invalid sass source");
is    ($r,                  undef,       "Failed compile scalar context returns undef");

($r, $err) = sass_compile(".valid { color: red; }", output_style => SASS_STYLE_NESTED);
is    ($err,                undef,       "output_style=>SASS_STYLE_NESTED error_message is undef");
like  ($r,                  qr/\{\n/,    "output_style=>SASS_STYLE_NESTED has returns in output");

($r, $err) = sass_compile("\n.valid {\n color: red; }", output_style => SASS_STYLE_COMPRESSED);
is    ($err,                undef,       "output_style=>SASS_STYLE_COMPRESSED error_message is undef");
unlike($r,                  qr/{\n/,     "output_style=>SASS_STYLE_COMPRESSED has no returns in output");
