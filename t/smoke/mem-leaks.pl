#!/usr/bin/perl
# smoke test to find memory leaks
# will only work optimal on linux

use strict;
use warnings;

use FindBin qw($Bin);

die "lib directory not found" unless -d $Bin . "/../../lib";
die "blib directory not found" unless -d $Bin . "/../../blib";

BEGIN { unshift @INC, $Bin . "/../../blib/lib", $Bin . "/../../blib/arch" }

use CSS::Sass;

use CSS::Sass qw(quote unquote sass2scss);

my $sass = CSS::Sass->new;

use CSS::Sass qw(SASS_SPACE SASS_COMMA SASS_STYLE_COMPRESSED);
$sass->options->{'output_style'} = SASS_STYLE_COMPRESSED;

$sass->options->{'sass_functions'}->{'var-pl-nil'} = sub { return undef };
$sass->options->{'sass_functions'}->{'var-pl-int'} = sub { return 42 };
$sass->options->{'sass_functions'}->{'var-pl-dbl'} = sub { return 4.2 };
$sass->options->{'sass_functions'}->{'var-pl-str'} = sub { return 'foobar' };
$sass->options->{'sass_functions'}->{'var-pl-big'} = sub { return 'foobar' x 200 };
$sass->options->{'sass_functions'}->{'var-pl-map'} = sub { return { foo => 'bar' } };
$sass->options->{'sass_functions'}->{'var-pl-list'} = sub { return [ 'foo', 'bar', 'baz' ] };
$sass->options->{'sass_functions'}->{'var-pl-die'} = sub { die "died in function" };

$sass->options->{'sass_functions'}->{'var-pl-new-nil'} = sub { return CSS::Sass::Value::Null->new };
$sass->options->{'sass_functions'}->{'var-pl-new-int'} = sub { return CSS::Sass::Value::Number->new(42) };
$sass->options->{'sass_functions'}->{'var-pl-new-dbl'} = sub { return CSS::Sass::Value::Number->new(4.2) };
$sass->options->{'sass_functions'}->{'var-pl-new-str'} = sub { return CSS::Sass::Value::String->new('foobar') };
$sass->options->{'sass_functions'}->{'var-pl-new-map'} = sub { return CSS::Sass::Value::Map->new(foo => 'bar') };
$sass->options->{'sass_functions'}->{'var-pl-new-list-comma'} = sub { return CSS::Sass::Value::List::Comma->new('foo', 'bar') };
$sass->options->{'sass_functions'}->{'var-pl-new-list-space'} = sub { return CSS::Sass::Value::List::Space->new('foo', 'bar') };
$sass->options->{'sass_functions'}->{'var-pl-new-error'} = sub { return CSS::Sass::Value::Error->new('message') };
$sass->options->{'sass_functions'}->{'var-pl-new-boolean'} = sub { return CSS::Sass::Value::Boolean->new(1) };

$sass->options->{'sass_functions'}->{'var-pipe($val)'} = sub { return CSS::Sass::Value->new($_[0]) };
$sass->options->{'sass_functions'}->{'var-pipe2($val)'} = sub { return $_[0] };

my $mem_usage = -e "/proc/$$/status" ? 0 : -1;

warn "You need to monitor mem usage yourself!" if $mem_usage eq -1;

sub run_importer_test
{

	my ($r, $err, $stat);

	($r, $err, $stat) = CSS::Sass::sass_compile('@import "http://www.host.dom/red";',
	    source_map_file => "test.css.map",
	    importer => sub {
	      if ($_[0] eq "http://www.host.dom/red") {
	        return [["red.css", '@import "green";']];
	      }
	      if ($_[0] eq "green") {
	        return [['http://www.host.dom/green', '@import "yellow";']];
	      }
	      return [['http://www.host.dom/final', 'A { color: ' . $_[0] . '; }']]; # yellow
	    }
	);


	my %files = (

	  "index.scss" => "
	    \@import 'foo.scss';
	    \@import 'bar.scss';
	  ",
	  "foo.scss" => "
	    \@import 'bar2.scss';
	    body { color: red; }
	  ",
	  "bar.scss" => "
	    p { color: grey; }
	  ",
	  "bar2.scss" => "
	    span { z-index: 4; }
	  "
	);

	my $expected = "span {
	  z-index: 4; }

	body {
	  color: red; }

	p {
	  color: grey; }

	/*# sourceMappingURL=index.css.map */";

	($r, $err, $stat) = CSS::Sass::sass_compile(
	    $files{'index.scss'},
	    input_file => "index.scss",
	    output_file => "index.css",
	    source_map_file => "index.css.map",
	    importer => sub {
	      return $_[0] unless exists $files{$_[0]};
	      return [ [ $_[0], $files{$_[0]} ] ];
	    }
	);

}

sub run_sass_value_test
{

	foreach my $iu (1 .. 1000)
	{
		my $css = sass2scss("A\n  color: red;");
		my $quoted = quote("I am a string");
		my $unquote = unquote("'I am a string'");
		$quoted = quote(CSS::Sass::Value->new("I am a string"));
		$unquote = unquote(CSS::Sass::Value->new("I am a string"));
		$unquote = unquote(CSS::Sass::Value->new("'I am a string'"));
		$quoted = quote(quote(CSS::Sass::Value->new("'I am a string'")));
	}

	my $foo = undef;

	# force stringification
	$foo = CSS::Sass::Value->new(undef);
	$foo = CSS::Sass::Value->new(42.35);
	$foo = CSS::Sass::Value->new("foobar");
	$foo = CSS::Sass::Value::Map->new("key" => "foobar");
	$foo = CSS::Sass::Value::List->new("foo baz", 42, "bar");
	$foo = CSS::Sass::Value::List::Comma->new("foo", "bar");
	$foo = CSS::Sass::Value::List::Space->new("foo", "bar");

	my $null = CSS::Sass::Value::Null->new;
	my $bool = CSS::Sass::Value::Boolean->new();
	my $bool_null = CSS::Sass::Value::Boolean->new(undef);
	my $bool_true = CSS::Sass::Value::Boolean->new(1);
	my $bool_false = CSS::Sass::Value::Boolean->new(0);
	my $string = CSS::Sass::Value::String->new();
	my $string_null = CSS::Sass::Value::String->new(undef);
	my $string_foobar = CSS::Sass::Value::String->new('foobar');
	my $number = CSS::Sass::Value::Number->new();
	my $number_null = CSS::Sass::Value::Number->new(undef);
	my $number_42 = CSS::Sass::Value::Number->new(42);
	my $number_px = CSS::Sass::Value::Number->new(42, 'px');
	my $number_percent = CSS::Sass::Value::Number->new(42, '%');
	my $color = CSS::Sass::Value::Color->new();
	my $color_rgb = CSS::Sass::Value::Color->new(42, 43, 44);
	my $color_rgba = CSS::Sass::Value::Color->new(1, 2, 3, 0.4);
	my $color_trans = CSS::Sass::Value::Color->new(255, 0, 128, 0);
	my $list = CSS::Sass::Value::List->new('foo', 'bar');
	my $list_comma = CSS::Sass::Value::List::Comma->new('foo', 'bar', 'baz');
	my $list_space = CSS::Sass::Value::List::Space->new('foo', 'bar', 'baz');
	my $map = CSS::Sass::Value::Map->new('foo' => 'bar');
	my $error = CSS::Sass::Value::Error->new();
	my $error_msg = CSS::Sass::Value::Error->new('message');

	my $css_tst = $sass->compile('A { color: red; }');
	my $css_nil1 = $sass->compile('A { color: var-pl-nil(); }');
	my $css_nil2 = $sass->compile('$nill: null; A { color: $nill; }');
	my $css_nil3 = $sass->compile('A { color: var-pl-big(); }');
	my $css_nil4 = $sass->compile('A { color: quote(foobar); }');
	my $css_int = $sass->compile('A { color: var-pl-int(); }');
	my $css_dbl = $sass->compile('$dbl: var-pl-dbl(); A { color: $dbl; }');
	my $css_str = $sass->compile('$str: var-pl-str(); A { color: $str; }');
	my $css_list_a = $sass->compile('$list: var-pl-list(); A { color: nth($list, 1); }');
	my $css_list_b = $sass->compile('$list: var-pl-list(); A { color: nth($list, -1); }');
	my $css_map = $sass->compile('$map: var-pipe(var-pl-map()); A { color: $map; }');

	$css_nil1 = $sass->compile('A { color: var-pipe(var-pl-nil()); }');
	$css_nil2 = $sass->compile('$nill: var-pipe(null); A { color: $nill; }');
	$css_nil3 = $sass->compile('A { color: var-pipe(var-pl-big()); }');
	$css_nil4 = $sass->compile('A { color: var-pipe(quote(foobar)); }');
	$css_int = $sass->compile('A { color: var-pipe(var-pl-int()); }');
	$css_dbl = $sass->compile('$dbl: var-pipe(var-pl-dbl()); A { color: $dbl; }');
	$css_str = $sass->compile('$str: var-pipe(var-pl-str()); A { color: $str; }');
	$css_list_a = $sass->compile('$list: var-pipe(var-pl-list()); A { color: nth($list, 1); }');
	$css_list_b = $sass->compile('$list: var-pipe(var-pl-list()); A { color: nth($list, -1); }');
	$css_map = $sass->compile('$map: var-pipe(var-pl-map()); A { color: $map; }');

	$css_nil1 = $sass->compile('A { color: var-pipe2(var-pl-nil()); }');
	$css_nil2 = $sass->compile('$nill: var-pipe2(null); A { color: $nill; }');
	$css_nil3 = $sass->compile('A { color: var-pipe2(var-pl-big()); }');
	$css_nil4 = $sass->compile('A { color: var-pipe2(quote(foobar)); }');
	$css_int = $sass->compile('A { color: var-pipe2(var-pl-int()); }');
	$css_dbl = $sass->compile('$dbl: var-pipe2(var-pl-dbl()); A { color: $dbl; }');
	$css_str = $sass->compile('$str: var-pipe2(var-pl-str()); A { color: $str; }');
	$css_list_a = $sass->compile('$list: var-pipe2(var-pl-list()); A { color: nth($list, 1); }');
	$css_list_b = $sass->compile('$list: var-pipe2(var-pl-list()); A { color: nth($list, -1); }');
	$css_map = $sass->compile('$map: var-pipe2(var-pl-map()); A { color: $map; }');

	$css_nil1 = $sass->compile('A { color: var-pipe(var-pipe2(var-pl-nil())); }');
	$css_nil2 = $sass->compile('$nill: var-pipe(var-pipe2(null)); A { color: $nill; }');
	$css_nil3 = $sass->compile('A { color: var-pipe(var-pipe2(var-pl-big())); }');
	$css_nil4 = $sass->compile('A { color: var-pipe(var-pipe2(quote(foobar))); }');
	$css_int = $sass->compile('A { color: var-pipe(var-pipe2(var-pl-int())); }');
	$css_dbl = $sass->compile('$dbl: var-pipe(var-pipe2(var-pl-dbl())); A { color: $dbl; }');
	$css_str = $sass->compile('$str: var-pipe(var-pipe2(var-pl-str())); A { color: $str; }');
	$css_list_a = $sass->compile('$list: var-pipe(var-pipe2(var-pl-list())); A { color: nth($list, 1); }');
	$css_list_b = $sass->compile('$list: var-pipe(var-pipe2(var-pl-list())); A { color: nth($list, -1); }');
	$css_map = $sass->compile('$map: var-pipe(var-pipe2(var-pl-map())); A { color: $map; }');

	$css_nil1 = $sass->compile('A { color: var-pipe2(var-pipe(var-pl-nil())); }');
	$css_nil2 = $sass->compile('$nill: var-pipe2(var-pipe(null)); A { color: $nill; }');
	$css_nil3 = $sass->compile('A { color: var-pipe2(var-pipe(var-pl-big())); }');
	$css_nil4 = $sass->compile('A { color: var-pipe2(var-pipe(quote(foobar))); }');
	$css_int = $sass->compile('A { color: var-pipe2(var-pipe(var-pl-int())); }');
	$css_dbl = $sass->compile('$dbl: var-pipe2(var-pipe(var-pl-dbl())); A { color: $dbl; }');
	$css_str = $sass->compile('$str: var-pipe2(var-pipe(var-pl-str())); A { color: $str; }');
	$css_list_a = $sass->compile('$list: var-pipe2(var-pipe(var-pl-list())); A { color: nth($list, 1); }');
	$css_list_b = $sass->compile('$list: var-pipe2(var-pipe(var-pl-list())); A { color: nth($list, -1); }');
	$css_map = $sass->compile('$map: var-pipe2(var-pipe(var-pl-map())); A { color: $map; }');

}

# 200000 proved to be a very safe value
# leaking one byte should be exposed by then
for (my $i = 0; $i < 200000; $i ++)
{


	run_sass_value_test();
	run_importer_test();

	if ($mem_usage != -1 && $i % 100 == 0)
	{
		my $mem = $1 if qx{ grep VmSize /proc/$$/status } =~ m/(\d+)/;
		if (defined $mem && $mem_usage != $mem) {
			warn "Memory increased to $mem (step $i)\n";
			$mem_usage = $mem;
		}
	}

	# print a dot to the console (we are still alive)
	if ($i % 500 == 0) { local $| = 1; print "."; }

}
