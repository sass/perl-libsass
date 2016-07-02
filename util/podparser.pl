#!/usr/bin/perl

use strict;
use warnings;

use File::Slurp;
use Pod::Select;
use Pod::Markdown;
use FindBin qw($Bin);

my $sass_pm_src = $Bin . '/../lib/CSS/Sass.pm';
my $type_pm_src = $Bin . '/../lib/CSS/Sass/Value.pm';
my $sass_md_src = $Bin . '/../lib/CSS/Sass.md';
my $type_md_src = $Bin . '/../lib/CSS/Sass/Value.md';
my $sass_pod_src = $Bin . '/../lib/CSS/Sass.pod';
my $type_pod_src = $Bin . '/../lib/CSS/Sass/Value.pod';

podselect({-output => $sass_pod_src }, $sass_pm_src);
podselect({-output => $type_pod_src }, $type_pm_src);

my $sass_pod = read_file $sass_pod_src, { binmode => ':raw' };
my $type_pod = read_file $type_pod_src, { binmode => ':raw' };

# working with string did not seem to work with Pod::Markdown!
system "perl -MPod::Markdown -e \"Pod::Markdown->new->filter(\@ARGV)\" $sass_pod_src > $sass_md_src";
system "perl -MPod::Markdown -e \"Pod::Markdown->new->filter(\@ARGV)\" $type_pod_src > $type_md_src";
