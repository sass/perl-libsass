# -*- perl -*-

# Usefult for debugging the xs with prints:
# cd text-sass-xs && ./Build && perl -Mlib=blib/arch -Mlib=blib/lib t/04_perl_functions.t

use strict;
use warnings;

use Test::More tests => 61;

use CSS::Sass;

sub read_file
{
  local $/=undef;
  open my $fh, $_[0] or die "Couldn't open file: $!";
  binmode $fh; return <$fh>;
}

my $sass = read_file('t/inc/sass/pretty.sass');
my $pretty0 = read_file('t/inc/scss/pretty-0.scss');
my $pretty1 = read_file('t/inc/scss/pretty-1.scss');
my $pretty2 = read_file('t/inc/scss/pretty-2.scss');
my $pretty3 = read_file('t/inc/scss/pretty-3.scss');

my $ignore_whitespace = 0;

my ($r, $err);

($r, $err) = CSS::Sass::sass2scss($sass);
$r =~ s/[\r\n]+/\n/g if $ignore_whitespace;
$pretty1 =~ s/[\r\n]+/\n/g if $ignore_whitespace;
chomp($pretty1) if $ignore_whitespace;
chomp($r) if $ignore_whitespace;
is    ($r,   $pretty1,                                  "Default pretty print");

($r, $err) = CSS::Sass::sass2scss($sass, SASS2SCSS_PRETTIFY_0);
$r =~ s/[\r\n]+/\n/g if $ignore_whitespace;
$pretty0 =~ s/[\r\n]+/\n/g if $ignore_whitespace;
chomp($pretty0) if $ignore_whitespace;
chomp($r) if $ignore_whitespace;
is    ($r,   $pretty0,                                 "Pretty print option 0");

($r, $err) = CSS::Sass::sass2scss($sass, SASS2SCSS_PRETTIFY_1);
$pretty1 =~ s/[\r\n]+/\n/g if $ignore_whitespace;
$r =~ s/[\r\n]+/\n/g if $ignore_whitespace;
chomp($pretty1) if $ignore_whitespace;
chomp($r) if $ignore_whitespace;
is    ($r,   $pretty1,                                 "Pretty print option 1");

($r, $err) = CSS::Sass::sass2scss($sass, SASS2SCSS_PRETTIFY_2);
$pretty2 =~ s/[\r\n]+/\n/g if $ignore_whitespace;
$r =~ s/[\r\n]+/\n/g if $ignore_whitespace;
chomp($pretty2) if $ignore_whitespace;
chomp($r) if $ignore_whitespace;
is    ($r,   $pretty2,                                 "Pretty print option 2");

($r, $err) = CSS::Sass::sass2scss($sass, SASS2SCSS_PRETTIFY_3);
$r =~ s/[\r\n]+/\n/g if $ignore_whitespace;
$pretty3 =~ s/[\r\n]+/\n/g if $ignore_whitespace;
chomp($pretty3) if $ignore_whitespace;
chomp($r) if $ignore_whitespace;
is    ($r,   $pretty3,                                 "Pretty print option 3");


my ($src, $expect);

# \/\/\/ -- https://github.com/ArnaudRinquin/sass2scss/blob/master/test/ -- \/\/\/

$src = read_file('t/inc/sass/t-01.sass');
($r, $err) = CSS::Sass::sass2scss($src);
$r =~ s/[\r\n]+/\n/g if $ignore_whitespace;
$expect = read_file('t/inc/scss/t-01.scss');
$expect =~ s/[\r\n]+/\n/g if $ignore_whitespace;
chomp($expect) if $ignore_whitespace;
chomp($r) if $ignore_whitespace;

is    ($r, $expect,                                    "Very basic convertion (01)");
is    ($err, undef,                                    "Very basic convertion (01)");

$src = read_file('t/inc/sass/t-02.sass');
($r, $err) = CSS::Sass::sass2scss($src);
$r =~ s/[\r\n]+/\n/g if $ignore_whitespace;
$expect = read_file('t/inc/scss/t-02.scss');
$expect =~ s/[\r\n]+/\n/g if $ignore_whitespace;
chomp($expect) if $ignore_whitespace;
chomp($r) if $ignore_whitespace;

is    ($r, $expect,                                    "Converts sass mixin and include aliases (02)");
is    ($err, undef,                                    "Converts sass mixin and include aliases (02)");

$src = read_file('t/inc/sass/t-03.sass');
($r, $err) = CSS::Sass::sass2scss($src);
$r =~ s/[\r\n]+/\n/g if $ignore_whitespace;
$expect = read_file('t/inc/scss/t-03.scss');
$expect =~ s/[\r\n]+/\n/g if $ignore_whitespace;
chomp($expect) if $ignore_whitespace;
chomp($r) if $ignore_whitespace;

is    ($r, $expect,                                    "Ignore comments on block last line (03)");
is    ($err, undef,                                    "Ignore comments on block last line (03)");

$src = read_file('t/inc/sass/t-04.sass');
($r, $err) = CSS::Sass::sass2scss($src);
$r =~ s/[\r\n]+/\n/g if $ignore_whitespace;
$expect = read_file('t/inc/scss/t-04.scss');
$expect =~ s/[\r\n]+/\n/g if $ignore_whitespace;
chomp($expect) if $ignore_whitespace;
chomp($r) if $ignore_whitespace;

is    ($r, $expect,                                    "Handle selectors not containing alphanumeric characters (04)");
is    ($err, undef,                                    "Handle selectors not containing alphanumeric characters (04)");

# /\/\/\ -- https://github.com/ArnaudRinquin/sass2scss/blob/master/test/ -- /\/\/\

$src = read_file('t/inc/sass/t-05.sass');
($r, $err) = CSS::Sass::sass2scss($src);
$r =~ s/[\r\n]+/\n/g if $ignore_whitespace;
$expect = read_file('t/inc/scss/t-05.scss');
$expect =~ s/[\r\n]+/\n/g if $ignore_whitespace;
chomp($expect) if $ignore_whitespace;
chomp($r) if $ignore_whitespace;

is    ($r, $expect,                                    "Handle strange comment indentation (05)");
is    ($err, undef,                                    "Handle strange comment indentation (05)");

$src = read_file('t/inc/sass/t-06.sass');
($r, $err) = CSS::Sass::sass2scss($src);
$r =~ s/[\r\n]+/\n/g if $ignore_whitespace;
$expect = read_file('t/inc/scss/t-06.scss');
$expect =~ s/[\r\n]+/\n/g if $ignore_whitespace;
chomp($expect) if $ignore_whitespace;
chomp($r) if $ignore_whitespace;

is    ($r, $expect,                                    "Handle not closed multiline comments (06)");
is    ($err, undef,                                    "Handle not closed multiline comments (06)");

$src = read_file('t/inc/sass/t-07.sass');
($r, $err) = CSS::Sass::sass2scss($src);
$r =~ s/[\r\n]+/\n/g if $ignore_whitespace;
$expect = read_file('t/inc/scss/t-07.scss');
$expect =~ s/[\r\n]+/\n/g if $ignore_whitespace;
chomp($expect) if $ignore_whitespace;
chomp($r) if $ignore_whitespace;

is    ($r, $expect,                                    "Handle self closing multiline comments (07)");
is    ($err, undef,                                    "Handle self closing multiline comments (07)");

$src = read_file('t/inc/sass/t-08.sass');
($r, $err) = CSS::Sass::sass2scss($src, SASS2SCSS_PRETTIFY_1 | SASS2SCSS_KEEP_COMMENT);
$r =~ s/[\r\n]+/\n/g if $ignore_whitespace;
$expect = read_file('t/inc/scss/t-08.scss');
$expect =~ s/[\r\n]+/\n/g if $ignore_whitespace;
chomp($expect) if $ignore_whitespace;
chomp($r) if $ignore_whitespace;

is    ($r, $expect,                                    "Handle \"keep_comments\" option (08)");
is    ($err, undef,                                    "Handle \"keep_comments\" option (08)");

$src = read_file('t/inc/sass/t-09.sass');
($r, $err) = CSS::Sass::sass2scss($src, SASS2SCSS_PRETTIFY_1 | SASS2SCSS_CONVERT_COMMENT);
$r =~ s/[\r\n]+/\n/g if $ignore_whitespace;
$expect = read_file('t/inc/scss/t-09.scss');
$expect =~ s/[\r\n]+/\n/g if $ignore_whitespace;
chomp($expect) if $ignore_whitespace;
chomp($r) if $ignore_whitespace;

is    ($r, $expect,                                    "Handle \"convert_comment\" option (09)");
is    ($err, undef,                                    "Handle \"convert_comment\" option (09)");

$src = read_file('t/inc/sass/t-10.sass');
($r, $err) = CSS::Sass::sass2scss($src, SASS2SCSS_PRETTIFY_1 | SASS2SCSS_CONVERT_COMMENT | SASS2SCSS_STRIP_COMMENT);
$r =~ s/[\r\n]+/\n/g if $ignore_whitespace;
$expect = read_file('t/inc/scss/t-10.scss');
$expect =~ s/[\r\n]+/\n/g if $ignore_whitespace;
chomp($expect) if $ignore_whitespace;
chomp($r) if $ignore_whitespace;

is    ($r, $expect,                                    "Handle \"strip_comment\" option (10)");
is    ($err, undef,                                    "Handle \"strip_comment\" option (10)");

$src = read_file('t/inc/sass/t-11.sass');
($r, $err) = CSS::Sass::sass2scss($src, SASS2SCSS_PRETTIFY_1 | SASS2SCSS_CONVERT_COMMENT | SASS2SCSS_STRIP_COMMENT);
$r =~ s/[\r\n]+/\n/g if $ignore_whitespace;
$expect = read_file('t/inc/scss/t-11.scss');
$expect =~ s/[\r\n]+/\n/g if $ignore_whitespace;
chomp($expect) if $ignore_whitespace;
chomp($r) if $ignore_whitespace;

is    ($r, $expect,                                    "Handle unquoted import statements (11)");
is    ($err, undef,                                    "Handle unquoted import statements (11)");

$src = read_file('t/inc/sass/t-12.sass');
($r, $err) = CSS::Sass::sass2scss($src, SASS2SCSS_PRETTIFY_1);
$r =~ s/[\r\n]+/\n/g if $ignore_whitespace;
$expect = read_file('t/inc/scss/t-12.scss');
$expect =~ s/[\r\n]+/\n/g if $ignore_whitespace;
chomp($expect) if $ignore_whitespace;
chomp($r) if $ignore_whitespace;

is    ($r, $expect,                                    "Handle comma separated selctors (12)");
is    ($err, undef,                                    "Handle comma separated selctors (12)");

$src = read_file('t/inc/sass/t-13.sass');
($r, $err) = CSS::Sass::sass2scss($src, SASS2SCSS_PRETTIFY_1);
$r =~ s/[\r\n]+/\n/g if $ignore_whitespace;
$expect = read_file('t/inc/scss/t-13.scss');
$expect =~ s/[\r\n]+/\n/g if $ignore_whitespace;
chomp($expect) if $ignore_whitespace;
chomp($r) if $ignore_whitespace;

is    ($r, $expect,                                    "Handle pseudo-selectors and sass property syntax (13)");
is    ($err, undef,                                    "Handle pseudo-selectors and sass property syntax (13)");

$src = read_file('t/inc/sass/t-14.sass');
($r, $err) = CSS::Sass::sass2scss($src, SASS2SCSS_PRETTIFY_1);
$r =~ s/[\r\n]+/\n/g if $ignore_whitespace;
$expect = read_file('t/inc/scss/t-14.scss');
$expect =~ s/[\r\n]+/\n/g if $ignore_whitespace;
chomp($expect) if $ignore_whitespace;
chomp($r) if $ignore_whitespace;

is    ($r, $expect,                                    "Handle empty selectors (14)");
is    ($err, undef,                                    "Handle empty selectors (14)");

$src = read_file('t/inc/sass/t-15.sass');
($r, $err) = CSS::Sass::sass2scss($src, SASS2SCSS_PRETTIFY_1);
$r =~ s/[\r\n]+/\n/g if $ignore_whitespace;
$expect = read_file('t/inc/scss/t-15.scss');
$expect =~ s/[\r\n]+/\n/g if $ignore_whitespace;
chomp($expect) if $ignore_whitespace;
chomp($r) if $ignore_whitespace;

is    ($r, $expect,                                    "Handle \@content keyword (15)");
is    ($err, undef,                                    "Handle \@content keyword (15)");

$src = read_file('t/inc/sass/t-16.sass');
($r, $err) = CSS::Sass::sass2scss($src, SASS2SCSS_PRETTIFY_1);
$r =~ s/[\r\n]+/\n/g if $ignore_whitespace;
$expect = read_file('t/inc/scss/t-16.scss');
$expect =~ s/[\r\n]+/\n/g if $ignore_whitespace;
chomp($expect) if $ignore_whitespace;
chomp($r) if $ignore_whitespace;

is    ($r, $expect,                                    "Handle \@return keyword (16)");
is    ($err, undef,                                    "Handle \@return keyword (16)");

$src = read_file('t/inc/sass/t-17.sass');
($r, $err) = CSS::Sass::sass2scss($src, SASS2SCSS_PRETTIFY_1);
$r =~ s/[\r\n]+/\n/g if $ignore_whitespace;
$expect = read_file('t/inc/scss/t-17.scss');
$expect =~ s/[\r\n]+/\n/g if $ignore_whitespace;
chomp($expect) if $ignore_whitespace;
chomp($r) if $ignore_whitespace;

is    ($r, $expect,                                    "Handle \@extend keyword (17)");
is    ($err, undef,                                    "Handle \@extend keyword (17)");

$src = read_file('t/inc/sass/t-18.sass');
($r, $err) = CSS::Sass::sass2scss($src, SASS2SCSS_PRETTIFY_1);
$r =~ s/[\r\n]+/\n/g if $ignore_whitespace;
$expect = read_file('t/inc/scss/t-18.scss');
$expect =~ s/[\r\n]+/\n/g if $ignore_whitespace;
chomp($expect) if $ignore_whitespace;
chomp($r) if $ignore_whitespace;

is    ($r, $expect,                                    "Handle plus char fallowed by whitespace (18)");
is    ($err, undef,                                    "Handle plus char fallowed by whitespace (18)");

$src = read_file('t/inc/sass/t-19.sass');
($r, $err) = CSS::Sass::sass2scss($src, SASS2SCSS_PRETTIFY_1);
$r =~ s/[\r\n]+/\n/g if $ignore_whitespace;
$expect = read_file('t/inc/scss/t-19.scss');
$expect =~ s/[\r\n]+/\n/g if $ignore_whitespace;
chomp($expect) if $ignore_whitespace;
chomp($r) if $ignore_whitespace;

is    ($r, $expect,                                    "Handle comments with less indentation (19)");
is    ($err, undef,                                    "Handle comments with less indentation (19)");

$src = read_file('t/inc/sass/t-20.sass');
($r, $err) = CSS::Sass::sass2scss($src, SASS2SCSS_PRETTIFY_1 | SASS2SCSS_KEEP_COMMENT);
$r =~ s/[\r\n]+/\n/g if $ignore_whitespace;
$expect = read_file('t/inc/scss/t-20.scss');
$expect =~ s/[\r\n]+/\n/g if $ignore_whitespace;
chomp($expect) if $ignore_whitespace;
chomp($r) if $ignore_whitespace;

is    ($r, $expect,                                    "Handle in line comments (20)");
is    ($err, undef,                                    "Handle in line comments (20)");

$src = read_file('t/inc/sass/t-21.sass');
($r, $err) = CSS::Sass::sass2scss($src, SASS2SCSS_PRETTIFY_1 | SASS2SCSS_KEEP_COMMENT);
$r =~ s/[\r\n]+/\n/g if $ignore_whitespace;
$expect = read_file('t/inc/scss/t-21.scss');
$expect =~ s/[\r\n]+/\n/g if $ignore_whitespace;
chomp($expect) if $ignore_whitespace;
chomp($r) if $ignore_whitespace;

is    ($r, $expect,                                    "Handle optional semicolons (21)");
is    ($err, undef,                                    "Handle optional semicolons (21)");

$src = read_file('t/inc/sass/t-22.sass');
($r, $err) = CSS::Sass::sass2scss($src, SASS2SCSS_PRETTIFY_1 | SASS2SCSS_KEEP_COMMENT);
$r =~ s/[\r\n]+/\n/g if $ignore_whitespace;
$expect = read_file('t/inc/scss/t-22.scss');
$expect =~ s/[\r\n]+/\n/g if $ignore_whitespace;
chomp($expect) if $ignore_whitespace;
chomp($r) if $ignore_whitespace;

is    ($r, $expect,                                    "Handle selectors and sass property syntax (22)");
is    ($err, undef,                                    "Handle selectors and sass property syntax (22)");

$src = read_file('t/inc/sass/t-23.sass');
($r, $err) = CSS::Sass::sass2scss($src, SASS2SCSS_PRETTIFY_1 | SASS2SCSS_KEEP_COMMENT);
$r =~ s/[\r\n]+/\n/g if $ignore_whitespace;
$expect = read_file('t/inc/scss/t-23.scss');
$expect =~ s/[\r\n]+/\n/g if $ignore_whitespace;
chomp($expect) if $ignore_whitespace;
chomp($r) if $ignore_whitespace;

is    ($r, $expect,                                    "Handle pseudo selectors and sass property syntax (23)");
is    ($err, undef,                                    "Handle pseudo selectors and sass property syntax (23)");

$src = read_file('t/inc/sass/t-24.sass');
($r, $err) = CSS::Sass::sass2scss($src, SASS2SCSS_PRETTIFY_1 | SASS2SCSS_KEEP_COMMENT);
$r =~ s/[\r\n]+/\n/g if $ignore_whitespace;
$expect = read_file('t/inc/scss/t-24.scss');
$expect =~ s/[\r\n]+/\n/g if $ignore_whitespace;
chomp($expect) if $ignore_whitespace;
chomp($r) if $ignore_whitespace;

is    ($r, $expect,                                    "Handle urls in quotes/apos correctly (24)");
is    ($err, undef,                                    "Handle urls in quotes/apos correctly (24)");

$src = read_file('t/inc/sass/comment.sass');
($r, $err) = CSS::Sass::sass2scss($src, SASS2SCSS_PRETTIFY_1 | SASS2SCSS_KEEP_COMMENT);
$r =~ s/[\r\n]+/\n/g if $ignore_whitespace;
$expect = read_file('t/inc/scss/comment-keep.scss');
$expect =~ s/[\r\n]+/\n/g if $ignore_whitespace;
chomp($expect) if $ignore_whitespace;
chomp($r) if $ignore_whitespace;

is    ($r, $expect,                                    "Handle \"keep_comment\" option");
is    ($err, undef,                                    "Handle \"keep_comment\" option");

$src = read_file('t/inc/sass/comment.sass');
($r, $err) = CSS::Sass::sass2scss($src, SASS2SCSS_PRETTIFY_1 | SASS2SCSS_CONVERT_COMMENT);
$r =~ s/[\r\n]+/\n/g if $ignore_whitespace;
$expect = read_file('t/inc/scss/comment-convert.scss');
$expect =~ s/[\r\n]+/\n/g if $ignore_whitespace;
chomp($expect) if $ignore_whitespace;
chomp($r) if $ignore_whitespace;

is    ($r, $expect,                                    "Handle \"convert_comment\" option");
is    ($err, undef,                                    "Handle \"convert_comment\" option");

$src = read_file('t/inc/sass/comment.sass');
($r, $err) = CSS::Sass::sass2scss($src, SASS2SCSS_PRETTIFY_1 | SASS2SCSS_KEEP_COMMENT | SASS2SCSS_CONVERT_COMMENT);
$r =~ s/[\r\n]+/\n/g if $ignore_whitespace;
$expect = read_file('t/inc/scss/comment-keep-convert.scss');
$expect =~ s/[\r\n]+/\n/g if $ignore_whitespace;
chomp($expect) if $ignore_whitespace;
chomp($r) if $ignore_whitespace;

is    ($r, $expect,                                    "Handle \"keep_comment|convert_comment\" option");
is    ($err, undef,                                    "Handle \"keep_comment|convert_comment\" option");

$src = read_file('t/inc/sass/comment.sass');
($r, $err) = CSS::Sass::sass2scss($src, SASS2SCSS_PRETTIFY_1 | SASS2SCSS_STRIP_COMMENT);
$r =~ s/[\r\n]+/\n/g if $ignore_whitespace;
$expect = read_file('t/inc/scss/comment-strip.scss');
$expect =~ s/[\r\n]+/\n/g if $ignore_whitespace;
chomp($expect) if $ignore_whitespace;
chomp($r) if $ignore_whitespace;

is    ($r, $expect,                                    "Handle \"strip_comment\" option");
is    ($err, undef,                                    "Handle \"strip_comment\" option");

