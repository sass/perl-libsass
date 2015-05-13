# -*- perl -*-

# Usefult for debugging the xs with prints:
# cd text-sass-xs && ./Build && perl -Mlib=blib/arch -Mlib=blib/lib t/01_xs.t

use strict;
use warnings;

use Test::More tests => 518;
BEGIN { use_ok('CSS::Sass') };

use CSS::Sass qw(SASS_ERROR);
use CSS::Sass qw(SASS_NULL);
use CSS::Sass qw(SASS_BOOLEAN);
use CSS::Sass qw(SASS_NUMBER);
use CSS::Sass qw(SASS_STRING);
use CSS::Sass qw(SASS_COLOR);
use CSS::Sass qw(SASS_LIST);
use CSS::Sass qw(SASS_MAP);

use CSS::Sass qw(SASS_COMMA);
use CSS::Sass qw(SASS_SPACE);

sub test_bool
{

	# test internal (xs) data structure of a boolean
	ok UNIVERSAL::isa($_[0], 'REF'), "boolean type is a reference";
	ok UNIVERSAL::isa(${$_[0]}, 'SCALAR'), "boolean type points to a scalar";
	ok UNIVERSAL::isa($_[0], 'CSS::Sass::Value::Boolean'), "boolean has correct package";

	# test the representation of the value (should never be undef)
	like ${${$_[0]}}, qr/^[01]$/, "boolean value matches specified type";

};

sub test_null
{

	# test internal (xs) data structure of a null
	ok UNIVERSAL::isa($_[0], 'REF'), "null type is a reference";
	ok UNIVERSAL::isa(${$_[0]}, 'SCALAR'), "null type points to a scalar";
	ok UNIVERSAL::isa($_[0], 'CSS::Sass::Value::Null'), "null has correct package";

	is $_[0] eq undef, 1, "null equals to undef";
	is $_[0] ne undef, 0, "null not equals undef";
	is $_[0] == undef, 1, "null is numeric equal to undef";
	is $_[0] != undef, 0, "null is numeric equal to undef";
	is $_[0] == 0, 0, "null equals to undef";
	is $_[0] != 0, 1, "null equals to undef";

	# test the representation of the value (must always be undef)
	ok ! defined ${${$_[0]}}, "null value matches specified type";

};

sub test_string
{

	# test internal (xs) data structure of a string
	ok UNIVERSAL::isa($_[0], 'SCALAR'), "string type points to a scalar";
	ok UNIVERSAL::isa($_[0], 'CSS::Sass::Value::String'), "string type has package";

	my $clone = $_[0]->clone;
	is $_[0] eq $clone, 1, "string is stringify equal to its clone";
	is $_[0] == $clone, 1, "string is numerical equal to its clone";
	is $_[0] ne $clone, 0, "string not not stringify equal to its clone";
	is $_[0] != $clone, 0, "string not not numerical equal to its clone";

	# test the representation of the value (must always be undef)
	ok defined ${$_[0]}, "string value must not be undefined";

};

sub test_number
{

	# test internal (xs) data structure of a boolean
	ok UNIVERSAL::isa($_[0], 'REF'), "number type is a reference";
	ok UNIVERSAL::isa(${$_[0]}, 'ARRAY'), "number type points to array";
	ok UNIVERSAL::isa($_[0], 'CSS::Sass::Value::Number'), "number has correct package";

	my $clone = $_[0]->clone;
	is $_[0] eq $clone, 1, "number is stringify equal to its clone";
	is $_[0] == $clone, 1, "number is numerical equal to its clone";
	is $_[0] ne $clone, 0, "number not not stringify equal to its clone";
	is $_[0] != $clone, 0, "number not not numerical equal to its clone";

};

sub test_color
{

	# test internal (xs) data structure of a boolean
	ok UNIVERSAL::isa($_[0], 'REF'), "color type is a reference";
	ok UNIVERSAL::isa(${$_[0]}, 'HASH'), "color type points to hash";
	ok UNIVERSAL::isa($_[0], 'CSS::Sass::Value::Color'), "color has correct package";

	my $clone = $_[0]->clone;
	# warn $clone;
	is $_[0] eq $clone, 1, "color is stringify equal to its clone";
	is $_[0] == $clone, 1, "color is numerical equal to its clone";
	is $_[0] ne $clone, 0, "color not not stringify equal to its clone";
	is $_[0] != $clone, 0, "color not not numerical equal to its clone";

};

sub test_map
{

	# test internal (xs) data structure of a map
	ok UNIVERSAL::isa($_[0], 'HASH'), "map type points to hash";
	ok UNIVERSAL::isa($_[0], 'CSS::Sass::Value::Map'), "map type has package";

	my $clone = $_[0]->clone;
	is $_[0] eq $clone, 1, "map is stringify equal to its clone";
	is $_[0] == $clone, 1, "map is numerical equal to its clone";
	is $_[0] ne $clone, 0, "map not not stringify equal to its clone";
	is $_[0] != $clone, 0, "map not not numerical equal to its clone";

};

sub test_list
{

	# test internal (xs) data structure of a list
	ok UNIVERSAL::isa($_[0], 'ARRAY'), "map type points to array";
	ok UNIVERSAL::isa($_[0], 'CSS::Sass::Value::List'), "map type has package";

	my $clone = $_[0]->clone;
	is $_[0] eq $clone, 1, "list is stringify equal to its clone";
	is $_[0] == $clone, 1, "list is numerical equal to its clone";
	is $_[0] ne $clone, 0, "list not not stringify equal to its clone";
	is $_[0] != $clone, 0, "list not not numerical equal to its clone";

};

sub test_error
{

	ok UNIVERSAL::isa($_[0], 'REF'), "error type is a reference";
	ok UNIVERSAL::isa(${$_[0]}, 'REF'), "error type points to a scalar";
	ok UNIVERSAL::isa($_[0], 'CSS::Sass::Value::Error'), "error has correct package";

	my $clone = $_[0]->clone;
	is $_[0] eq $clone, 1, "error is stringify equal to its clone";
	is $_[0] == $clone, 1, "error is numerical equal to its clone";
	is $_[0] ne $clone, 0, "error not not stringify equal to its clone";
	is $_[0] != $clone, 0, "error not not numerical equal to its clone";

};

################################################################################

test_null(CSS::Sass::Value->new());
test_null(CSS::Sass::Value->new(undef));
test_number(CSS::Sass::Value->new(42));
test_string(CSS::Sass::Value->new("foobar"));
test_list(CSS::Sass::Value->new([ "foo", "bar" ]));
test_map(CSS::Sass::Value->new({ "foo" => "bar" }));
test_null(CSS::Sass::Value->new(\[ "foobar" ]));
test_error(CSS::Sass::Value->new(\\[ "foobar" ]));
my $err = CSS::Sass::Value->new(\\[ "foobar" ]);
is $err->message, "foobar", "error correctly parsed";

# force stringification
is (CSS::Sass::Value->new(undef) . "", "null", "null stringify ok");
is (CSS::Sass::Value->new(42.35), "42.35", "number stringify ok");
is (CSS::Sass::Value->new(42.35)->unit, "", "number unit ok");
is (CSS::Sass::Value->new(42.35)->value, "42.35", "number value ok");
is (CSS::Sass::Value->new("foobar"), "foobar", "string stringify ok");
is (CSS::Sass::Value->new("foo bar"), '"foo bar"', "string stringify ok");
is (CSS::Sass::Value->new({ "key" => "foobar" }), '{ key: foobar }', "map stringify ok");
is (CSS::Sass::Value->new([ "foo baz", 42, "bar" ]), '[ "foo baz", 42, bar ]', "list stringify ok");
is (CSS::Sass::Value->new(["foo", "bar"]), '[ foo, bar ]', "list comma stringify ok");

# force stringification
is (CSS::Sass::Value::Null->new(undef) . "", "null", "null stringify ok");
is (CSS::Sass::Value::Number->new(42.35), "42.35", "number stringify ok");
is (CSS::Sass::Value::String->new("foobar"), "foobar", "string stringify ok");
is (CSS::Sass::Value::String::Quoted->new("foobar"), "\"foobar\"", "string stringify ok");
is (CSS::Sass::Value::String::Constant->new("foo bar"), "foo bar", "string stringify ok");
is (CSS::Sass::Value::Map->new("key" => "foobar"), '{ key: foobar }', "map stringify ok");
is (CSS::Sass::Value::List->new("foo baz", 42, "bar"), '[ "foo baz", 42, bar ]', "list stringify ok");
is (CSS::Sass::Value::List::Comma->new("foo", "bar"), '[ foo, bar ]', "list comma stringify ok");
is (CSS::Sass::Value::List::Space->new("foo", "bar"), '[ foo bar ]', "list space stringify ok");

################################################################################
################################################################################

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
my $regex = CSS::Sass::Value->new(qr/regex/);

################################################################################

test_null($null);

is "$null", 'null', "null stringify value is correct";
is $null->value, undef, "null value is correct";

################################################################################

test_bool($bool);
test_bool($bool_null);
test_bool($bool_true);
test_bool($bool_false);

is $bool, 'false', "bool stringify value is correct";
is $bool->value, 0, "bool value is correct";
is $bool_null, "false", "bool_null stringify value is correct";
is $bool_null->value, 0, "bool_null value is correct";
is $bool_true, "true", "bool_true stringify value is correct";
is $bool_true->value, 1, "bool_true value is correct";
is $bool_false, "false", "bool_false stringify value is correct";
is $bool_false->value, 0, "bool_false value is correct";

################################################################################

test_string($string);
test_string($string_null);
test_string($string_foobar);

is $string, "", "string stringify value is correct";
is $string->value, "", "string value is correct";
is $string_null, "", "string_null stringify value is correct";
is $string_null->value, "", "string_null value is correct";
is $string_foobar, "foobar", "string_foobar stringify value is correct";
is $string_foobar->value, "foobar", "string_foobar value is correct";

################################################################################

test_color($color);
test_color($color_rgb);
test_color($color_rgba);

is $color, "null", "color stringify is correct";
is $color->r, undef, "color r is correct";
is $color->g, undef, "color g is correct";
is $color->b, undef, "color b is correct";
is $color->a, 1, "color a is correct";

is $color_rgb, "rgb(42, 43, 44)", "color_rgb stringify is correct";
is $color_rgb->r, 42, "color_rgb r is correct";
is $color_rgb->g, 43, "color_rgb g is correct";
is $color_rgb->b, 44, "color_rgb b is correct";
is $color_rgb->a, 1, "color_rgb a is correct";

is $color_rgba, "rgba(1, 2, 3, 0.4)", "color_rgba stringify is correct";
is $color_rgba->r, 1, "color_rgba r is correct";
is $color_rgba->g, 2, "color_rgba g is correct";
is $color_rgba->b, 3, "color_rgba b is correct";
is $color_rgba->a, 0.4, "color_rgba a is correct";

is $color_trans, "transparent", "color without opacity is transparent";

################################################################################

test_number($number);
test_number($number_null);
test_number($number_42);
test_number($number_px);
test_number($number_percent);

is $number, "0", "number stringify is correct";
is $number->value, 0, "number value is correct";
is $number->unit, "", "number unit is correct";

is $number_null, "0", "number_null stringify is correct";
is $number_null->value, 0, "number_null value is correct";
is $number_null->unit, "", "number_null unit is correct";

is $number_42, "42", "number_42 stringify is correct";
is $number_42->value, 42, "number_42 value is correct";
is $number_42->unit, "", "number_42 unit is correct";

is $number_px, "42px", "number_px stringify is correct";
is $number_px->value, 42, "number_px value is correct";
is $number_px->unit, "px", "number_px unit is correct";

is $number_percent, "42%", "number_percent stringify is correct";
is $number_percent->value, 42, "number_percent value is correct";
is $number_percent->unit, "%", "number_percent unit is correct";

################################################################################

test_list($list);
test_list($list_comma);
test_list($list_space);

is $list, '[ foo, bar ]', "list stringify is correct";
is $list->[0], 'foo', "list[0] is correct";
is $list->[1], 'bar', "list[1] is correct";
is $list->[-1], 'bar', "list[-1] is correct";

is $list_comma, '[ foo, bar, baz ]', "list_comma stringify is correct";
is $list_comma->[0], 'foo', "list_comma[0] is correct";
is $list_comma->[1], 'bar', "list_comma[1] is correct";
is $list_comma->[2], 'baz', "list_comma[2] is correct";
is $list_comma->[-1], 'baz', "list_comma[-1] is correct";

is $list_space, '[ foo bar baz ]', "list_space stringify is correct";
is $list_space->[0], 'foo', "list_space[0] is correct";
is $list_space->[1], 'bar', "list_space[1] is correct";
is $list_space->[2], 'baz', "list_space[2] is correct";
is $list_space->[-1], 'baz', "list_space[-1] is correct";

is join("", $list->values), "foobar", "list values method works";
is $list_comma->separator, SASS_COMMA, "comma separator method works";
is $list_space->separator, SASS_SPACE, "space separator method works";

################################################################################

test_map($map);

is $map, '{ foo: bar }', "map stringify is correct";
is $map->{'foo'}, 'bar', "map->foo is correct";

is join("", $map->keys), "foo", "map keys method works";
is join("", $map->values), "bar", "map values method works";

################################################################################

test_error($error);
test_error($error_msg);

is $error, 'error', "error stringify is correct";
is $error_msg, 'message', "error_msg stringify is correct";
is $error_msg->message, 'message', "error message method return ok";

################################################################################

test_string($regex);

SKIP: {
	skip ("known regex issue in perl < 5.12", 1) if $] < 5.012000;
	is $regex, qr/regex/, "regex stringify value is correct";
}

################################################################################
################################################################################

my $bar = CSS::Sass::Value::String->new('bar');
my $bar_c1 = CSS::Sass::Value::String->new('bar', 0);
my $bar_q1 = CSS::Sass::Value::String->new('bar', 1);
my $bar_c2 = CSS::Sass::Value::String::Constant->new('bar');
my $bar_q2 = CSS::Sass::Value::String::Quoted->new('bar');

my $bar_3 = CSS::Sass::Value::String->new('b a r');
my $bar_c3 = CSS::Sass::Value::String::Constant->new('b a r');
my $bar_q3 = CSS::Sass::Value::String::Quoted->new('b a r');

is $bar . "baz", "barbaz", "string concat test #01";
is $bar_c1 . "baz", "barbaz", "string concat test #02";
is $bar_q1 . "baz", '"barbaz"', "string concat test #03";
is $bar_c2 . "baz", "barbaz", "string concat test #04";
is $bar_q2 . "baz", '"barbaz"', "string concat test #05";

is "foo" . $bar . "baz", "foobarbaz", "string concat test #06";
is "foo" . $bar_c1 . "baz", "foobarbaz", "string concat test #07";
is "foo" . $bar_q1 . "baz", 'foobarbaz', "string concat test #08";
is "foo" . $bar_c2 . "baz", "foobarbaz", "string concat test #09";
is "foo" . $bar_q2 . "baz", 'foobarbaz', "string concat test #10";

is $bar_3 . "baz", "b a rbaz", "string concat test #01";
is $bar_c3 . "baz", "b a rbaz", "string concat test #02";
is $bar_q3 . "baz", '"b a rbaz"', "string concat test #03";

is "foo" . $bar_3 . "baz", 'foob a rbaz', "string concat test #11";
is "foo" . $bar_c3 . "baz", "foob a rbaz", "string concat test #12";
is "foo" . $bar_q3 . "baz", 'foob a rbaz', "string concat test #13";

################################################################################
################################################################################

my $sass = CSS::Sass->new;

use CSS::Sass qw(SASS_SPACE SASS_COMMA SASS_STYLE_COMPRESSED);
$sass->options->{'output_style'} = SASS_STYLE_COMPRESSED;

$sass->options->{'sass_functions'}->{'var-pl-nil'} = sub { return undef };
$sass->options->{'sass_functions'}->{'var-pl-int'} = sub { return 42 };
$sass->options->{'sass_functions'}->{'var-pl-dbl'} = sub { return 4.2 };
$sass->options->{'sass_functions'}->{'var-pl-str'} = sub { return 'foobar' };
$sass->options->{'sass_functions'}->{'var-pl-map'} = sub { return { foo => 'bar' } };
$sass->options->{'sass_functions'}->{'var-pl-list'} = sub { return [ 'foo', 'bar', 'baz' ] };
$sass->options->{'sass_functions'}->{'var-pl-die'} = sub { die "died in function" };
$sass->options->{'sass_functions'}->{'var-pl-regex'} = sub { qr/foobar/ };

$sass->options->{'sass_functions'}->{'var-pl-new-nil'} = sub { return CSS::Sass::Value::Null->new };
$sass->options->{'sass_functions'}->{'var-pl-new-int'} = sub { return CSS::Sass::Value::Number->new(42) };
$sass->options->{'sass_functions'}->{'var-pl-new-dbl'} = sub { return CSS::Sass::Value::Number->new(4.2) };
$sass->options->{'sass_functions'}->{'var-pl-new-str'} = sub { return CSS::Sass::Value::String->new('foobar') };
$sass->options->{'sass_functions'}->{'var-pl-new-map'} = sub { return CSS::Sass::Value::Map->new(foo => 'bar') };
$sass->options->{'sass_functions'}->{'var-pl-new-list-comma'} = sub { return CSS::Sass::Value::List::Comma->new('foo', 'bar') };
$sass->options->{'sass_functions'}->{'var-pl-new-list-space'} = sub { return CSS::Sass::Value::List::Space->new('foo', 'bar') };
$sass->options->{'sass_functions'}->{'var-pl-new-error'} = sub { return CSS::Sass::Value::Error->new('message') };
$sass->options->{'sass_functions'}->{'var-pl-new-boolean'} = sub { return CSS::Sass::Value::Boolean->new(1) };

################################################################################
# basic test if functions can return unblessed types
################################################################################

my $css_nil = $sass->compile('$nil: var-pl-nil(); A { color: $nil; }');
is $css_nil, '', "function returned native null type";

my $css_int = $sass->compile('$int: var-pl-int(); A { color: $int; }');
is $css_int, "A{color:42}\n", "function returned native integer type";

my $css_dbl = $sass->compile('$dbl: var-pl-dbl(); A { color: $dbl; }');
is $css_dbl, "A{color:4.2}\n", "function returned native double type";

my $css_str = $sass->compile('$str: var-pl-str(); A { color: $str; }');
is $css_str, "A{color:foobar}\n", "function returned native string type";

my $css_list = $sass->compile('$list: var-pl-list(); A { color: nth($list, 1); }');
is $css_list, "A{color:foo}\n", "function returned native array type";
$css_list = $sass->compile('$list: var-pl-list(); A { color: nth($list, -1); }');
is $css_list, "A{color:baz}\n", "function returned native array type";

my $css_map = $sass->compile('$map: var-pl-map(); A { color: map-get($map, foo); }');
#is $css_map, 'A{color:bar}', "function returned native hash type";

################################################################################

$sass->options->{'sass_functions'}->{'var-pl-str-quote'} = sub { return "foo bar" };
$css_str = $sass->compile('$str: var-pl-str-quote(); A { color: $str; }');
is $css_str, "A{color:foo bar}\n", "function returned native string type";

$sass->options->{'sass_functions'}->{'var-pl-str-quote'} = sub { return "\"foo\\\"s\"" };
$css_str = $sass->compile('$str: var-pl-str-quote(); A { color: $str; }');
is $css_str, "A{color:foo\"s}\n", "function returned native string type";

$sass->options->{'sass_functions'}->{'var-pl-str-quote'} = sub { return "\'foo\\'s\'" };
$css_str = $sass->compile('$str: var-pl-str-quote(); A { color: $str; }');
is $css_str, "A{color:foo\'s}\n", "function returned native string type";

################################################################################
# test if functions get passed correct var structures
################################################################################

$sass->options->{'sass_functions'}->{'test-nul($nul)'} = sub { test_null($_[0]); return $_[0]; };
$sass->options->{'sass_functions'}->{'test-int($int)'} = sub { test_number($_[0]); return $_[0]; };
$sass->options->{'sass_functions'}->{'test-dbl($int)'} = sub { test_number($_[0]); return $_[0]; };
$sass->options->{'sass_functions'}->{'test-str($int)'} = sub { test_string($_[0]); return $_[0]; };
$sass->options->{'sass_functions'}->{'test-map($int)'} = sub { test_map($_[0]); return $_[0]; };
$sass->options->{'sass_functions'}->{'test-lst($int)'} = sub { test_list($_[0]); return $_[0]; };
$sass->options->{'sass_functions'}->{'test-err($int)'} = sub { test_error($_[0]); return $_[0]; };
$sass->options->{'sass_functions'}->{'test-bol($int)'} = sub { test_bool($_[0]); return $_[0]; };

################################################################################
# test values from sass inline declaration
################################################################################

$sass->compile('$nul: test-nul(null);');
$sass->compile('$int: test-int(42);');
$sass->compile('$dbl: test-dbl(.5);');
$sass->compile('$str: test-str("foobar");');
$sass->compile('$map: test-map(( foo : bar ));');
$sass->compile('$lst: test-lst(( foo, bar ));');

################################################################################
# test values from perl function returns
################################################################################
$sass->options->{'dont_die'} = 1;
is $sass->compile('$nul: test-nul(var-pl-nil()); A { value: $nul; }'),
   '', 'test returned blessed variable of type null';
is $sass->compile('$int: test-int(var-pl-int()); A { value: $int; }'),
   "A{value:42}\n", 'test returned blessed variable of type integer number';
is $sass->compile('$dbl: test-dbl(var-pl-dbl()); A { value: $dbl; }'),
   "A{value:4.2}\n", 'test returned blessed variable of type double number';
is $sass->compile('$str: test-str(var-pl-str()); A { value: $str; }'),
   "A{value:foobar}\n", 'test returned blessed variable of type string';
is $sass->compile('$map: test-map(var-pl-map()); A { value: $map; }'),
   "A{value:(foo:bar)}\n", 'test returned blessed variable of type map';
is $sass->compile('$err: test-err(var-pl-die()); A { value: $err; }'),
   undef, 'test returned blessed variable of type error';
is $sass->compile('$lst: test-lst(var-pl-list()); A { value: $lst; }'),
   "A{value:foo,bar,baz}\n", 'test returned blessed variable of type comma list';

is $sass->compile('$nul: test-nul(var-pl-new-nil()); A { value: $nul; }'),
   '', 'test returned blessed variable of type null';
is $sass->compile('$int: test-int(var-pl-new-int()); A { value: $int; }'),
   "A{value:42}\n", 'test returned blessed variable of type integer number';
is $sass->compile('$dbl: test-dbl(var-pl-new-dbl()); A { value: $dbl; }'),
   "A{value:4.2}\n", 'test returned blessed variable of type double number';
is $sass->compile('$str: test-str(var-pl-new-str()); A { value: $str; }'),
   "A{value:foobar}\n", 'test returned blessed variable of type string';
is $sass->compile('$map: test-map(var-pl-new-map()); A { value: $map; }'),
   "A{value:(foo:bar)}\n", 'test returned blessed variable of type map';
is $sass->compile('$lst: test-lst(var-pl-new-list-comma()); A { value: $lst; }'),
   "A{value:foo,bar}\n", 'test returned blessed variable of type comma list';
is $sass->compile('$lst: test-lst(var-pl-new-list-space()); A { value: $lst; }'),
   "A{value:foo bar}\n", 'test returned blessed variable of type space list';
is $sass->compile('$bol: test-bol(var-pl-new-boolean()); A { value: $bol; }'),
   "A{value:true}\n", 'test returned blessed variable of type boolean';
is $sass->compile('$err: test-err(var-pl-new-error()); A { value: $err; }'),
   undef, 'test returned blessed variable of type error';

SKIP: {
	skip ("known regex issue in perl < 5.12", 4) if $] < 5.012000;
	is $sass->compile('$rgx: test-str(var-pl-regex()); A { value: $rgx; }'),
	   "A{value:".qr/foobar/."}\n", 'test returned blessed variable of type "regex"';
}

################################################################################
$sass->options->{'dont_die'} = 0;
################################################################################

eval { $sass->compile('$err: var-pl-die();'); };
like $@, qr/died in function/, "returning an error dies within sass";

eval { $sass->compile('$err: test-err(var-pl-new-error());'); };
like $@, qr/message/, "returning an error dies within sass";

################################################################################

$list = CSS::Sass::Value::List->new("'foo'", 42, "bar");
is $list->[0]->value, "'foo'", "string in list was upgraded correctly";
is $list->[1]->unit, "", "number in list was upgraded correctly";
is $list->[2]->value, "bar", "string in list was upgraded correctly";

$list = CSS::Sass::Value::Map->new(key => "'foo'", bar => 42);
is $list->{'key'}->value, "'foo'", "string in map was upgraded correctly";
is $list->{'bar'}->unit, "", "number in map was upgraded correctly";

################################################################################
# test some setters
################################################################################

is $bool_true->value(1), 1, "bool value setter works";
is $bool_true->value, 1, "bool value getter works";
is $bool_true->value(undef), 0, "bool value reset works";
is $bool_true->value, 0, "bool value regetter works";

is $string_foobar->value('baz'), "baz", "string value setter works";
is $string_foobar->value, "baz", "string value getter works";
is $string_foobar->value(undef), "", "string value reset works";
is $string_foobar->value, "", "string value regetter works";

is $number_px->value(-32), -32, "number_px value setter works";
is $number_px->value, -32, "number_px value getter works";
is $number_px->value(undef), 0, "number_px value reset works";
is $number_px->value, 0, "number_px value regetter works";

is $number_px->unit('%'), '%', "number_px unit setter works";
is $number_px->unit, '%', "number_px unit getter works";
is $number_px->unit(undef), '', "number_px unit reset works";
is $number_px->unit, '', "number_px unit regetter works";

################################################################################
# test some known error conditions
################################################################################

$sass->options->{'dont_die'} = 1;
require IO::Handle; my $fh = new IO::Handle;

$sass->options->{'sass_functions'}->{'error_no_return()'} = sub { return (1,99); };
is $sass->compile('$nul: error_no_return(); A { key: $nul; }'),
   undef, 'error_invalid_key returned undef';
like $sass->last_error, qr/Perl sub must not return a list of values/,
  'error_invalid_value was correctly captured';

is $sass->compile('$err: test-err(var-pl-new-error()); A { value: $err; }'),
   undef, 'test returned blessed variable of type error';
like $sass->last_error, qr/error in C function var-pl-new-error: message/,
  'error_invalid_value was correctly captured';

################################################################################
# specific edge case test
################################################################################

