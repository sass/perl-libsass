# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 6;

use CSS::Sass;

sub read_file
{
  local $/ = undef;
  open my $fh, $_[0] or die "Couldn't open file: $!";
  binmode $fh; return <$fh>;
}

my $sass;
my ($r, $err, $smap);
my ($src, $expect);
my $ignore_whitespace = 0;

$expect = '{
  "version": 3,
  "file": "",
  "sources": ["stdin"],
  "names": [],
  "mappings": "AAAA;EAAS,OAAO"
}';

my %options = ( source_comments => SASS_SOURCE_COMMENTS_MAP, source_map_file => 'test.map', dont_die => 1 );

$sass = CSS::Sass->new(%options);
($r, $smap) = $sass->compile('.class { color: red; }');
ok    ($smap,                                    "Source map created");
is    ($smap, $expect,                           "Matches expected result");
like  ($r, qr/\/\*# sourceMappingURL=test.map \*\/\n*\z/, "Source map url inserted");

$sass = CSS::Sass->new(%options, omit_source_map_url => 1);
($r, $smap) = $sass->compile('.class { color: green; }');
ok    ($smap,                                    "Source map created");
is    ($smap, $expect,                           "Matches expected result");
unlike($r, qr/\/\*# sourceMappingURL=test.map \*\/\n*\z/, "Source map url omitted");
