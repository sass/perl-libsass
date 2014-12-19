# -*- perl -*-

# Usefult for debugging the xs with prints:
# cd text-sass-xs && ./Build && perl -Mlib=blib/arch -Mlib=blib/lib t/01_xs.t

use strict;
use warnings;

use Test::More tests => 297;
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
	ok UNIVERSAL::isa($_[0], 'CSS::Sass::Type::Boolean'), "boolean has correct package";

	# test the representation of the value (should never be undef)
	like ${${$_[0]}}, qr/^[01]$/, "boolean value matches specified type";

};

sub test_null
{

	# test internal (xs) data structure of a null
	ok UNIVERSAL::isa($_[0], 'REF'), "null type is a reference";
	ok UNIVERSAL::isa(${$_[0]}, 'SCALAR'), "null type points to a scalar";
	ok UNIVERSAL::isa($_[0], 'CSS::Sass::Type::Null'), "null has correct package";

	# test the representation of the value (must always be undef)
	ok ! defined ${${$_[0]}}, "null value matches specified type";

};

sub test_string
{

	# test internal (xs) data structure of a string
	ok UNIVERSAL::isa($_[0], 'SCALAR'), "string type points to a scalar";
	ok UNIVERSAL::isa($_[0], 'CSS::Sass::Type::String'), "string type has package";

	# test the representation of the value (must always be undef)
	ok defined ${$_[0]}, "string value must not be undefined";

};

sub test_number
{

	# test internal (xs) data structure of a boolean
	ok UNIVERSAL::isa($_[0], 'REF'), "number type is a reference";
	ok UNIVERSAL::isa(${$_[0]}, 'ARRAY'), "number type points to array";
	ok UNIVERSAL::isa($_[0], 'CSS::Sass::Type::Number'), "number has correct package";

};

sub test_color
{

	# test internal (xs) data structure of a boolean
	ok UNIVERSAL::isa($_[0], 'REF'), "color type is a reference";
	ok UNIVERSAL::isa(${$_[0]}, 'HASH'), "color type points to hash";
	ok UNIVERSAL::isa($_[0], 'CSS::Sass::Type::Color'), "color has correct package";

};

sub test_map
{

	# test internal (xs) data structure of a map
	ok UNIVERSAL::isa($_[0], 'HASH'), "map type points to hash";
	ok UNIVERSAL::isa($_[0], 'CSS::Sass::Type::Map'), "map type has package";

};

sub test_list
{

	# test internal (xs) data structure of a list
	ok UNIVERSAL::isa($_[0], 'ARRAY'), "map type points to array";
	ok UNIVERSAL::isa($_[0], 'CSS::Sass::Type::List'), "map type has package";

};

sub test_error
{

	ok UNIVERSAL::isa($_[0], 'REF'), "error type is a reference";
	ok UNIVERSAL::isa(${$_[0]}, 'REF'), "error type points to a scalar";
	ok UNIVERSAL::isa($_[0], 'CSS::Sass::Type::Error'), "error has correct package";

};

################################################################################

test_null(CSS::Sass::Type->new());
test_null(CSS::Sass::Type->new(undef));
test_number(CSS::Sass::Type->new(42));
test_string(CSS::Sass::Type->new("foobar"));
test_list(CSS::Sass::Type->new([ "foo", "bar" ]));
test_map(CSS::Sass::Type->new({ "foo" => "bar" }));
test_null(CSS::Sass::Type->new(\[ "foobar" ]));
test_error(CSS::Sass::Type->new(\\[ "foobar" ]));
my $err = CSS::Sass::Type->new(\\[ "foobar" ]);
is $err->message, "foobar", "error correctly parsed";

# force stringification
is "" . CSS::Sass::Type->new(undef), "null", "null stringify ok";
is "" . CSS::Sass::Type->new(42.35), "42.35", "number stringify ok";
is "" . CSS::Sass::Type->new(42.35)->unit, "", "number unit ok";
is "" . CSS::Sass::Type->new(42.35)->value, "42.35", "number value ok";
is "" . CSS::Sass::Type->new("foobar"), "foobar", "string stringify ok";
is "" . CSS::Sass::Type->new({ "key" => "foobar" }), "key: foobar", "map stringify ok";
is "" . CSS::Sass::Type->new([ "foo baz", 42, "bar" ]), "\"foo baz\", 42, bar", "list stringify ok";
is "" . CSS::Sass::Type->new(["foo", "bar"]), "foo, bar", "list comma stringify ok";

# force stringification
is "" . CSS::Sass::Type::Null->new(undef), "null", "null stringify ok";
is "" . CSS::Sass::Type::Number->new(42.35), "42.35", "null stringify ok";
is "" . CSS::Sass::Type::String->new("foobar"), "foobar", "null stringify ok";
is "" . CSS::Sass::Type::Map->new("key" => "foobar"), "key: foobar", "map stringify ok";
is "" . CSS::Sass::Type::List->new("foo baz", 42, "bar"), "\"foo baz\", 42, bar", "list stringify ok";
is "" . CSS::Sass::Type::List::Comma->new("foo", "bar"), "foo, bar", "list comma stringify ok";
is "" . CSS::Sass::Type::List::Space->new("foo", "bar"), "foo bar", "list space stringify ok";

################################################################################
################################################################################

my $null = CSS::Sass::Type::Null->new;
my $bool = CSS::Sass::Type::Boolean->new();
my $bool_null = CSS::Sass::Type::Boolean->new(undef);
my $bool_true = CSS::Sass::Type::Boolean->new(1);
my $bool_false = CSS::Sass::Type::Boolean->new(0);
my $string = CSS::Sass::Type::String->new();
my $string_null = CSS::Sass::Type::String->new(undef);
my $string_foobar = CSS::Sass::Type::String->new('foobar');
my $number = CSS::Sass::Type::Number->new();
my $number_null = CSS::Sass::Type::Number->new(undef);
my $number_42 = CSS::Sass::Type::Number->new(42);
my $number_px = CSS::Sass::Type::Number->new(42, 'px');
my $number_percent = CSS::Sass::Type::Number->new(42, '%');
my $color = CSS::Sass::Type::Color->new();
my $color_rgb = CSS::Sass::Type::Color->new(42, 43, 44);
my $color_rgba = CSS::Sass::Type::Color->new(1, 2, 3, 0.4);
my $color_trans = CSS::Sass::Type::Color->new(255, 0, 128, 0);
my $list = CSS::Sass::Type::List->new('foo', 'bar');
my $list_comma = CSS::Sass::Type::List::Comma->new('foo', 'bar', 'baz');
my $list_space = CSS::Sass::Type::List::Space->new('foo', 'bar', 'baz');
my $map = CSS::Sass::Type::Map->new('foo' => 'bar');
my $error = CSS::Sass::Type::Error->new();
my $error_msg = CSS::Sass::Type::Error->new('message');
my $regex = CSS::Sass::Type->new(qr/regex/);

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

is $list, 'foo, bar', "list stringify is correct";
is $list->[0], 'foo', "list[0] is correct";
is $list->[1], 'bar', "list[1] is correct";
is $list->[-1], 'bar', "list[-1] is correct";

is $list_comma, 'foo, bar, baz', "list_comma stringify is correct";
is $list_comma->[0], 'foo', "list_comma[0] is correct";
is $list_comma->[1], 'bar', "list_comma[1] is correct";
is $list_comma->[2], 'baz', "list_comma[2] is correct";
is $list_comma->[-1], 'baz', "list_comma[-1] is correct";

is $list_space, 'foo bar baz', "list_space stringify is correct";
is $list_space->[0], 'foo', "list_space[0] is correct";
is $list_space->[1], 'bar', "list_space[1] is correct";
is $list_space->[2], 'baz', "list_space[2] is correct";
is $list_space->[-1], 'baz', "list_space[-1] is correct";

is join("", $list->values), "foobar", "list values method works";
is $list_comma->separator, SASS_COMMA, "comma separator method works";
is $list_space->separator, SASS_SPACE, "space separator method works";

################################################################################

test_map($map);

is $map, 'foo: bar', "map stringify is correct";
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

is $regex, '"'.qr/regex/.'"', "regex stringify value is correct";

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

$sass->options->{'sass_functions'}->{'var-pl-new-nil'} = sub { return CSS::Sass::Type::Null->new };
$sass->options->{'sass_functions'}->{'var-pl-new-int'} = sub { return CSS::Sass::Type::Number->new(42) };
$sass->options->{'sass_functions'}->{'var-pl-new-dbl'} = sub { return CSS::Sass::Type::Number->new(4.2) };
$sass->options->{'sass_functions'}->{'var-pl-new-str'} = sub { return CSS::Sass::Type::String->new('foobar') };
$sass->options->{'sass_functions'}->{'var-pl-new-map'} = sub { return CSS::Sass::Type::Map->new(foo => 'bar') };
$sass->options->{'sass_functions'}->{'var-pl-new-list-comma'} = sub { return CSS::Sass::Type::List::Comma->new('foo', 'bar') };
$sass->options->{'sass_functions'}->{'var-pl-new-list-space'} = sub { return CSS::Sass::Type::List::Space->new('foo', 'bar') };
$sass->options->{'sass_functions'}->{'var-pl-new-error'} = sub { return CSS::Sass::Type::Error->new('message') };
$sass->options->{'sass_functions'}->{'var-pl-new-boolean'} = sub { return CSS::Sass::Type::Boolean->new(1) };

################################################################################
# basic test if functions can return unblessed types
################################################################################

my $css_nil = $sass->compile('$nil: var-pl-nil(); A { color: $nil; }');
is $css_nil, 'A{}', "function returned native null type";

my $css_int = $sass->compile('$int: var-pl-int(); A { color: $int; }');
is $css_int, 'A{color:42}', "function returned native integer type";

my $css_dbl = $sass->compile('$dbl: var-pl-dbl(); A { color: $dbl; }');
is $css_dbl, 'A{color:4.2}', "function returned native double type";

my $css_str = $sass->compile('$str: var-pl-str(); A { color: $str; }');
is $css_str, 'A{color:foobar}', "function returned native string type";

my $css_list = $sass->compile('$list: var-pl-list(); A { color: nth($list, 1); }');
is $css_list, 'A{color:foo}', "function returned native array type";
$css_list = $sass->compile('$list: var-pl-list(); A { color: nth($list, -1); }');
is $css_list, 'A{color:baz}', "function returned native array type";

my $css_map = $sass->compile('$map: var-pl-map(); A { color: map-get($map, foo); }');
#is $css_map, 'A{color:bar}', "function returned native hash type";

################################################################################

$sass->options->{'sass_functions'}->{'var-pl-str-quote'} = sub { return "foo bar" };
$css_str = $sass->compile('$str: var-pl-str-quote(); A { color: $str; }');
is $css_str, 'A{color:foo bar}', "function returned native string type";

$sass->options->{'sass_functions'}->{'var-pl-str-quote'} = sub { return "\"foo\\\"s\"" };
$css_str = $sass->compile('$str: var-pl-str-quote(); A { color: $str; }');
is $css_str, 'A{color:"foo\\"s"}', "function returned native string type";

$sass->options->{'sass_functions'}->{'var-pl-str-quote'} = sub { return "\'foo\\'s\'" };
$css_str = $sass->compile('$str: var-pl-str-quote(); A { color: $str; }');
is $css_str, 'A{color:\'foo\\\'s\'}', "function returned native string type";

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
   'A{}', 'test returned blessed variable of type null';
is $sass->compile('$int: test-int(var-pl-int()); A { value: $int; }'),
   'A{value:42}', 'test returned blessed variable of type integer number';
is $sass->compile('$dbl: test-dbl(var-pl-dbl()); A { value: $dbl; }'),
   'A{value:4.2}', 'test returned blessed variable of type double number';
is $sass->compile('$str: test-str(var-pl-str()); A { value: $str; }'),
   'A{value:foobar}', 'test returned blessed variable of type string';
is $sass->compile('$map: test-map(var-pl-map()); A { value: $map; }'),
   'A{value:(foo: bar)}', 'test returned blessed variable of type map';
is $sass->compile('$err: test-err(var-pl-die()); A { value: $err; }'),
   undef, 'test returned blessed variable of type error';
is $sass->compile('$lst: test-lst(var-pl-list()); A { value: $lst; }'),
   'A{value:foo,bar,baz}', 'test returned blessed variable of type comma list';

is $sass->compile('$nul: test-nul(var-pl-new-nil()); A { value: $nul; }'),
   'A{}', 'test returned blessed variable of type null';
is $sass->compile('$int: test-int(var-pl-new-int()); A { value: $int; }'),
   'A{value:42}', 'test returned blessed variable of type integer number';
is $sass->compile('$dbl: test-dbl(var-pl-new-dbl()); A { value: $dbl; }'),
   'A{value:4.2}', 'test returned blessed variable of type double number';
is $sass->compile('$str: test-str(var-pl-new-str()); A { value: $str; }'),
   'A{value:foobar}', 'test returned blessed variable of type string';
is $sass->compile('$map: test-map(var-pl-new-map()); A { value: $map; }'),
   'A{value:(foo: bar)}', 'test returned blessed variable of type map';
is $sass->compile('$lst: test-lst(var-pl-new-list-comma()); A { value: $lst; }'),
   'A{value:foo,bar}', 'test returned blessed variable of type comma list';
is $sass->compile('$lst: test-lst(var-pl-new-list-space()); A { value: $lst; }'),
   'A{value:foo bar}', 'test returned blessed variable of type space list';
is $sass->compile('$bol: test-bol(var-pl-new-boolean()); A { value: $bol; }'),
   'A{value:true}', 'test returned blessed variable of type boolean';
is $sass->compile('$err: test-err(var-pl-new-error()); A { value: $err; }'),
   undef, 'test returned blessed variable of type error';

is $sass->compile('$rgx: test-str(var-pl-regex()); A { value: $rgx; }'),
   "A{value:".qr/foobar/."}", 'test returned blessed variable of type "regex"';

################################################################################
$sass->options->{'dont_die'} = 0;
################################################################################

eval { $sass->compile('$err: var-pl-die();'); };
like $@, qr/died in function/, "returning an error dies within sass";

eval { $sass->compile('$err: test-err(var-pl-new-error());'); };
like $@, qr/message/, "returning an error dies within sass";

################################################################################

$list = CSS::Sass::Type::List->new("'foo'", 42, "bar");
is $list->[0]->value, "foo", "string in list was upgraded correctly";
is $list->[1]->unit, "", "number in list was upgraded correctly";
is $list->[2]->value, "bar", "string in list was upgraded correctly";

$list = CSS::Sass::Type::Map->new(key => "'foo'", bar => 42);
is $list->{'key'}->value, "foo", "string in map was upgraded correctly";
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

