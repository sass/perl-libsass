# -*- perl -*-

# Usefult for debugging the xs with prints:
# cd text-sass-xs && ./Build && perl -Mlib=blib/arch -Mlib=blib/lib t/01_xs.t

use strict;
use warnings;

use Test::More tests => 42;
BEGIN { use_ok('CSS::Sass') };

my $r;
$r = CSS::Sass::compile_sass("this is invalid sass source", {});
is  ($r->{error_status},  1,           "Failed compile sets error_status");
like($r->{error_message}, qr/error:/,  "Failed compile sets error_message");
is  ($r->{output_string}, undef,       "Failed compile sets output_string to undef");


$r = CSS::Sass::compile_sass(".valid { color: red; }", {});
is  ($r->{error_status},  0,           "Successful compile clears error_status");
is  ($r->{error_message}, undef,       "Successful compile sets error_message to undef");
isnt($r->{output_string}, undef,       "Successful compile sets output_string");


# $options->{output_style}
$r = CSS::Sass::compile_sass(".valid { color: red; }", { output_style => CSS::Sass::SASS_STYLE_NESTED });
is    ($r->{error_status},  0,           "output_style=>SASS_STYLE_NESTED no_error_status");
is    ($r->{error_message}, undef,       "output_style=>SASS_STYLE_NESTED error_message is undef");
like  ($r->{output_string}, qr/\{\n/,    "output_style=>SASS_STYLE_NESTED has returns in output");

$r = CSS::Sass::compile_sass("\n.valid {\n color: red; }", { output_style => CSS::Sass::SASS_STYLE_COMPRESSED });
is    ($r->{error_status},  0,           "output_style=>SASS_STYLE_COMPRESSED no_error_status");
is    ($r->{error_message}, undef,       "output_style=>SASS_STYLE_COMPRESSED error_message is undef");
unlike($r->{output_string}, qr/{\n/,     "output_style=>SASS_STYLE_COMPRESSED has no returns in output");

$r = CSS::Sass::compile_sass(".valid { color: red; }", { output_style => { wrong_type => 1 } });
is    ($r->{error_status},  0,           "output_style=>{} no_error_status and doesn't crash");
is    ($r->{error_message}, undef,       "output_style=>{} error_message is undef");


# $options->{source_comment}
$r = CSS::Sass::compile_sass("\n.valid {\n color: red; }", { source_comments => 1 });
is    ($r->{error_status},  0,           "source_comments=>1 no error_status");
is    ($r->{error_message}, undef,       "source_comments=>1 error_message is undef");
like  ($r->{output_string}, qr@/\*@,     "source_comments=>1 has added comments");

$r = CSS::Sass::compile_sass("\n.valid {\n color: red; }", { source_comments => 0 });
is    ($r->{error_status},  0,           "source_comments=>0 no error_status");
is    ($r->{error_message}, undef,       "source_comments=>0 error_message is undef");
unlike($r->{output_string}, qr@/\*@,     "source_comments=>0 has no added comments");

$r = CSS::Sass::compile_sass("\n.valid {\n color: red; }", { source_comments => [ 'wrong type' ] });
is    ($r->{error_status},  0,           "source_comments=>[] no error_status and doesn't crash");
is    ($r->{error_message}, undef,       "source_comments=>[] error_message is undef");


# $options->{include_paths}
$r = CSS::Sass::compile_sass('@import "colors"; .valid { color: $red; }', { });
is    ($r->{error_status},  1,           "failed import sets error_status");
like  ($r->{error_message}, qr/error:/,  "failed import sets error_message");
is    ($r->{output_string}, undef,       "failed import output_string is undef");

$r = CSS::Sass::compile_sass('@import "colors"; .valid { color: $red; }', { include_paths => 't/inc' });
is    ($r->{error_status},  0,           "import no error_status");
is    ($r->{error_message}, undef,       "import error_message is undef");
like  ($r->{output_string}, qr/#ff1111/, "import imported red");

my $pathsep = $^O eq 'MSWin32' ? ';' : ':';
$r = CSS::Sass::compile_sass('@import "colors"; .valid { color: $red; }', { include_paths => "t/nonexistent${pathsep}t/inc" });
is    ($r->{error_status},  0,           "import w/ 2 paths no error_status");
is    ($r->{error_message}, undef,       "import w/ 2 paths error_message is undef");
like  ($r->{output_string}, qr/#ff1111/, "import w/ 2 paths imported red");

$r = CSS::Sass::compile_sass('@import "colors"; .valid { color: $red; }', { include_paths => [ 'wrong type' ] });
is    ($r->{error_status},  1,           "import w/ bad type sets error_status but doesn't crash");
like  ($r->{error_message}, qr/error:/,  "import w/ bad type sets error_message");


# $options->{image_path}
$r = CSS::Sass::compile_sass('.valid { color: image-url("path"); }', { });
is    ($r->{error_status},  0,                        "image_path default no error_status");
is    ($r->{error_message}, undef,                    "image_path default error_message is undef");
like  ($r->{output_string}, qr@url\("/path"\)@,       "image_path defaults to /");

$r = CSS::Sass::compile_sass('.valid { color: image-url("path"); }', { image_path => "/a/b/c" });
is    ($r->{error_status},  0,                        "image_path paths no error_status");
is    ($r->{error_message}, undef,                    "image_path paths error_message is undef");
like  ($r->{output_string}, qr@url\("/a/b/c/path"\)@, "image_path works");

$r = CSS::Sass::compile_sass('.valid { color: image-url("path"); }', { image_path => { wrong_type => 1 } });
is    ($r->{error_status},  0,                        "image_path w/ bad type no error_status and doesn't crash");
is    ($r->{error_message}, undef,                    "image_path w/ bad type error_message is undef");
