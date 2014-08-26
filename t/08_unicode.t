# -*- perl -*-

use utf8;
use strict;
use warnings;

use Encode::Locale;
use Test::More tests => 7;

BEGIN { use_ok('CSS::Sass') };

my %options = ( dont_die => 1 );

my ($fh, $sass, $r);

require Win32::Unicode::File if $^O eq "MSWin32";

unless ($^O eq "MSWin32") { open($fh, ">", 't/inc/unicode_äöü.scss'); }
else { $fh = Win32::Unicode::File->new(">", 't/inc/unicode_äöü.scss'); }
print $fh '.class { content: "[umlaut] äöü"; }'; undef $fh;

unless ($^O eq "MSWin32") { open($fh, ">", 't/inc/unicode_тра.scss'); }
else { $fh = Win32::Unicode::File->new(">", 't/inc/unicode_тра.scss'); }
print $fh '.class { content: "тра"; }'; undef $fh;

$sass = CSS::Sass->new(include_paths => ['t/inc'], %options);
unless ($^O eq "MSWin32") { ok(-e 't/inc/unicode_äöü.scss', "found unicode file [1]"); }
else { ok (Win32::Unicode::File::file_type('e', 't/inc/unicode_äöü.scss'), "found unicode file [1]"); }
unless ($^O eq "MSWin32") { ok(-e 't/inc/unicode_тра.scss', "found unicode file [2]"); }
else { ok (Win32::Unicode::File::file_type('e', 't/inc/unicode_тра.scss'), "found unicode file [2]"); }

# this should work on windows ansi api if chars are in ansi page
($r) = $sass->compile_file('t/inc/unicode_äöü.scss');
warn $sass->last_error if $sass->last_error;
ok    ($r,                                    "Passed unicode filename test 1a");
is    ($sass->last_error,    undef,           "Passed unicode filename test 1b");

# this should fail on windows ansi api if chars are not in ansi page
$sass = CSS::Sass->new(include_paths => ['t/inc'], %options);
($r) = $sass->compile_file('t/inc/unicode_тра.scss');
warn $sass->last_error if $sass->last_error;
ok    ($r,                                    "Passed unicode filename test 2a");
is    ($sass->last_error,    undef,           "Passed unicode filename test 2b");


unless ($^O eq "MSWin32") { unlink('t/inc/unicode_äöü.scss'); }
else { $fh = Win32::Unicode::File::unlinkW('t/inc/unicode_äöü.scss'); }

unless ($^O eq "MSWin32") { unlink('t/inc/unicode_тра.scss'); }
else { $fh = Win32::Unicode::File::unlinkW('t/inc/unicode_тра.scss'); }
