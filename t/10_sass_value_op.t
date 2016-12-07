# -*- perl -*-

use utf8;
use strict;
use warnings;

BEGIN {
	use Test::More;
}

use Test::Differences;
use Test::More tests => 40;

BEGIN { use_ok('CSS::Sass') };

my %options = ( dont_die => 1 );

use CSS::Sass qw(sass_operation);

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
my $number_42px = CSS::Sass::Value::Number->new(42, 'px');
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

# test number with number operations
my $num_mul_1 = sass_operation(CSS::Sass::MUL, $number_42, $number_42px);
my $num_div_1 = sass_operation(CSS::Sass::DIV, $number_42, $number_42px);
my $num_add_1 = sass_operation(CSS::Sass::ADD, $number_42, $number_42px);
my $num_sub_1 = sass_operation(CSS::Sass::SUB, $number_42, $number_42px);
my $num_mod_1 = sass_operation(CSS::Sass::MOD, $number_42, $number_42px);
my $num_eq_1 = sass_operation(CSS::Sass::EQ, $number_42, $number_42);
my $num_eq_2 = sass_operation(CSS::Sass::EQ, $number_42, $number_42px);
my $num_eq_3 = sass_operation(CSS::Sass::EQ, $number_42px, $number_42px);

is($num_mul_1, CSS::Sass::Value::Number->new(42 * 42, "px"), "number_42 * number_42px ok");
is($num_div_1, CSS::Sass::Value::Number->new(42 / 42, "/px"), "number_42 - number_42px ok");
is($num_add_1, CSS::Sass::Value::Number->new(42 + 42, "px"), "number_42 + number_42px ok");
is($num_sub_1, CSS::Sass::Value::Number->new(42 - 42, "px"), "number_42 - number_42px ok");
is($num_mod_1, CSS::Sass::Value::Number->new(42 % 42, "px"), "number_42 % number_42px ok");
is($num_eq_1, CSS::Sass::Value::Boolean->new(1), "number_42 == number_42 ok");
is($num_eq_2, CSS::Sass::Value::Boolean->new(1), "number_42 == number_42px ok");
is($num_eq_3, CSS::Sass::Value::Boolean->new(1), "number_42px == number_42px ok");

# test string with string operations
my $str_mul_1 = sass_operation(CSS::Sass::MUL, $string_foobar, $string_foobar);
my $str_div_1 = sass_operation(CSS::Sass::DIV, $string_foobar, $string_foobar);
my $str_add_1 = sass_operation(CSS::Sass::ADD, $string_foobar, $string_foobar);
my $str_sub_1 = sass_operation(CSS::Sass::SUB, $string_foobar, $string_foobar);
my $str_mod_1 = sass_operation(CSS::Sass::MOD, $string_foobar, $string_foobar);
my $str_eq_1 = sass_operation(CSS::Sass::EQ, $string_foobar, $string_foobar);
my $str_eq_2 = sass_operation(CSS::Sass::EQ, $string_foobar, "foobar");
my $str_eq_3 = sass_operation(CSS::Sass::EQ, "foobar", $string_foobar);

is($str_mul_1, CSS::Sass::Value::Error->new("Undefined operation: \"foobar times foobar\"."), "string multiplication error ok");
is($str_div_1, CSS::Sass::Value::String->new("foobar/foobar"), "string_foobar / string_foobar ok");
is($str_add_1, CSS::Sass::Value::String->new("foobarfoobar"), "string_foobar + string_foobar ok");
is($str_sub_1, CSS::Sass::Value::String->new("foobar-foobar"), "string_foobar - string_foobar ok");
is($str_mod_1, CSS::Sass::Value::Error->new("Undefined operation: \"foobar mod foobar\"."), "string modulo error ok");
is($str_eq_1, CSS::Sass::Value::Boolean->new(1), "string_foobar eq string_foobar ok");
is($str_eq_2, CSS::Sass::Value::Boolean->new(1), "string_foobar eq 'foobar' ok");
is($str_eq_3, CSS::Sass::Value::Boolean->new(1), "'foobar' eq string_foobar ok");

# test color with color operations
my $col_mul_1 = sass_operation(CSS::Sass::MUL, $color_rgb, $color_rgb);
my $col_div_1 = sass_operation(CSS::Sass::DIV, $color_rgb, $color_rgb);
my $col_add_1 = sass_operation(CSS::Sass::ADD, $color_rgb, $color_rgb);
my $col_sub_1 = sass_operation(CSS::Sass::SUB, $color_rgb, $color_rgb);
my $col_mod_1 = sass_operation(CSS::Sass::MOD, $color_rgb, $color_rgb);

is($col_mul_1, CSS::Sass::Value::Color->new(1764, 1849, 1936, 1), "color_rgb * color_rgb ok");
is($col_div_1, CSS::Sass::Value::Color->new(1, 1, 1, 1), "color_rgb / color_rgb ok");
is($col_add_1, CSS::Sass::Value::Color->new(84, 86, 88, 1), "color_rgb + color_rgb ok");
is($col_sub_1, CSS::Sass::Value::Color->new(0, 0, 0, 1), "color_rgb - color_rgb ok");
is($col_mod_1, CSS::Sass::Value::Color->new(0, 0, 0, 1), "color_rgb % color_rgb ok");

is(CSS::Sass::Value::String->new("42")->has_quotes, 1, "string is quoted test #0");
is(CSS::Sass::Value::String->new("foobar")->has_quotes, 0, "string is quoted test #1");
is(CSS::Sass::Value::String->new("'baz'")->has_quotes, 1, "string is quoted test #2");
is(CSS::Sass::Value::String->new("foo bar")->has_quotes, 1, "string is quoted test #3");
is(CSS::Sass::Value::String::Quoted->new("foobar")->has_quotes, 1, "qstring is quoted test #1");
is(CSS::Sass::Value::String::Quoted->new("'baz'")->has_quotes, 1, "qstring is quoted test #2");
is(CSS::Sass::Value::String::Quoted->new("foo bar")->has_quotes, 1, "qstring is quoted test #3");
is(CSS::Sass::Value::String::Constant->new("foobar")->has_quotes, 0, "cstring is quoted test #1");
is(CSS::Sass::Value::String::Constant->new("'baz'")->has_quotes, 0, "cstring is quoted test #2");
is(CSS::Sass::Value::String::Constant->new("foo bar")->has_quotes, 0, "cstring is quoted test #3");

is(
  sass_operation(
    CSS::Sass::ADD,
    CSS::Sass::Value::String->new("foo"),
    CSS::Sass::Value::String->new("bar")
  ),
  "foobar",
  "string add test #1"
);

is(
  sass_operation(
    CSS::Sass::ADD,
    CSS::Sass::Value::String::Quoted->new("foo"),
    CSS::Sass::Value::String::Quoted->new("bar")
  ),
  "foobar",
  "string add test #2"
);

is(
  sass_operation(
    CSS::Sass::ADD,
    CSS::Sass::Value::String::Quoted->new("foo bar"),
    CSS::Sass::Value::String::Quoted->new("baz")
  ),
  "foo barbaz",
  "string add test #3"
);

is(
  sass_operation(
    CSS::Sass::ADD,
    CSS::Sass::Value::String->new("'foo'"),
    CSS::Sass::Value::String->new("'bar'")
  ),
  "foobar",
  "string add test #5"
);

is(
  sass_operation(
    CSS::Sass::ADD,
    CSS::Sass::Value::String::Quoted->new("'foo'"),
    CSS::Sass::Value::String::Quoted->new("'bar'")
  ),
  "foobar",
  "string add test #5"
);

is(
  sass_operation(
    CSS::Sass::ADD,
    CSS::Sass::Value::String::Quoted->new("'foo'"),
    CSS::Sass::Value::String::Constant->new("'bar'")
  ),
  "foo'bar'",
  "string add test #6"
);

my ($r, $err) = CSS::Sass::sass_compile(
  '
  @mixin test_comp_op($a, $b) {
    /*! #{inspect(op_and($a, $b))} == #{($a and $b)} */
    test-and: op_and($a, $b) == ($a and $b);
    test-custom: inspect(op_and($a, $b));
    test-native: inspect(($a and $b));
    /*! #{inspect(op_or($a, $b))} == #{($a or $b)} */
    test-or: op_or($a, $b) == ($a or $b);
    test-custom: inspect(op_or($a, $b));
    test-native: inspect(($a or $b));
    /*! #{inspect(op_eq($a, $b))} == #{($a == $b)} */
    test-eq: op_eq($a, $b) == ($a == $b);
    test-custom: inspect(op_eq($a, $b));
    test-native: inspect(($a == $b));
    /*! #{inspect(op_neq($a, $b))} == #{($a != $b)} */
    test-neq: op_neq($a, $b) == ($a != $b);
    test-custom: inspect(op_neq($a, $b));
    test-native: inspect(($a != $b));
    // /*! #{inspect(op_gt($a, $b))} == #{($a > $b)} */
    // test-gt: op_gt($a, $b) == ($a > $b);
    test-custom: inspect(op_gt($a, $b));
    test-native: inspect(($a > $b));
    // /*! #{inspect(op_gte($a, $b))} == #{($a >= $b)} */
    // test-gte: op_gte($a, $b) == ($a >= $b);
    test-custom: inspect(op_gte($a, $b));
    test-native: inspect(($a >= $b));
    // /*! #{inspect(op_lt($a, $b))} == #{($a < $b)} */
    // test-lt: op_lt($a, $b) == ($a < $b);
    test-custom: inspect(op_lt($a, $b));
    test-native: inspect(($a < $b));
    // /*! #{inspect(op_lte($a, $b))} == #{($a <= $b)} */
    // test-lte: op_lte($a, $b) == ($a <= $b);
    test-custom: inspect(op_lte($a, $b));
    test-native: inspect(($a <= $b));
  }
  @mixin test_base_op($a, $b) {
    /*! #{inspect(op_add($a, $b))} == #{($a + $b)} */
    test-add: op_add($a, $b) == ($a + $b);
    test-custom: inspect(op_add($a, $b));
    test-native: inspect(($a + $b));
    /*! #{inspect(op_sub($a, $b))} == #{($a - $b)} */
    test-sub: op_sub($a, $b) == ($a - $b);
    test-custom: inspect(op_sub($a, $b));
    test-native: inspect(($a - $b));
    /*! #{inspect(op_div($a, $b))} == #{($a / $b)} */
    test-div: op_div($a, $b) == ($a / $b);
    test-custom: inspect(op_div($a, $b));
    test-native: inspect(($a / $b));
  }
  @mixin test_mul_op($a, $b) {
    /*! #{inspect(op_div($a, $b))} == #{($a * $b)} */
    test-mul: op_mul($a, $b) == ($a * $b);
    test-custom: inspect(op_mul($a, $b));
    test-native: inspect(($a * $b));
    /*! #{inspect(op_mod($a, $b))} == #{($a % $b)} */
    test-mod: op_mod($a, $b) == ($a % $b);
    test-custom: inspect(op_mod($a, $b));
    test-native: inspect(($a % $b));
  }
  numbers {
    @include test_comp_op(42px, 42);
    @include test_base_op(42px, 42);
    @include test_mul_op(42px, 42);
  }
  colors {
    @include test_base_op(red, #F36);
    @include test_mul_op(red, #F36);
  }
  booleans {
    @include test_base_op(true, false);
  }
  ',
  sass_functions => {
    'op_and($a, $b)' => sub { return sass_operation(CSS::Sass::AND, $_[0], $_[1]) },
    'op_or ($a, $b)' => sub { return sass_operation(CSS::Sass::OR,  $_[0], $_[1]) },
    'op_eq ($a, $b)' => sub { return sass_operation(CSS::Sass::EQ,  $_[0], $_[1]) },
    'op_neq($a, $b)' => sub { return sass_operation(CSS::Sass::NEQ, $_[0], $_[1]) },
    'op_gt ($a, $b)' => sub { return sass_operation(CSS::Sass::GT,  $_[0], $_[1]) },
    'op_gte($a, $b)' => sub { return sass_operation(CSS::Sass::GTE, $_[0], $_[1]) },
    'op_lt ($a, $b)' => sub { return sass_operation(CSS::Sass::LT,  $_[0], $_[1]) },
    'op_lte($a, $b)' => sub { return sass_operation(CSS::Sass::LTE, $_[0], $_[1]) },
    'op_add($a, $b)' => sub { return sass_operation(CSS::Sass::ADD, $_[0], $_[1]) },
    'op_sub($a, $b)' => sub { return sass_operation(CSS::Sass::SUB, $_[0], $_[1]) },
    'op_div($a, $b)' => sub { return sass_operation(CSS::Sass::DIV, $_[0], $_[1]) },
    'op_mul($a, $b)' => sub { return sass_operation(CSS::Sass::MUL, $_[0], $_[1]) },
    'op_mod($a, $b)' => sub { return sass_operation(CSS::Sass::MOD, $_[0], $_[1]) },
  }
);


my $expected = <<END_OF_EXPECTED;
numbers {
  /*! 42 == 42 */
  test-and: true;
  test-custom: 42;
  test-native: 42;
  /*! 42px == 42px */
  test-or: true;
  test-custom: 42px;
  test-native: 42px;
  /*! true == true */
  test-eq: true;
  test-custom: true;
  test-native: true;
  /*! false == false */
  test-neq: true;
  test-custom: false;
  test-native: false;
  test-custom: false;
  test-native: false;
  test-custom: true;
  test-native: true;
  test-custom: false;
  test-native: false;
  test-custom: true;
  test-native: true;
  /*! 84px == 84px */
  test-add: true;
  test-custom: 84px;
  test-native: 84px;
  /*! 0px == 0px */
  test-sub: true;
  test-custom: 0px;
  test-native: 0px;
  /*! 1px == 1px */
  test-div: true;
  test-custom: 1px;
  test-native: 1px;
  /*! 1px == 1764px */
  test-mul: true;
  test-custom: 1764px;
  test-native: 1764px;
  /*! 0px == 0px */
  test-mod: true;
  test-custom: 0px;
  test-native: 0px; }

colors {
  /*! #ff3366 == #ff3366 */
  test-add: true;
  test-custom: #ff3366;
  test-native: #ff3366;
  /*! black == black */
  test-sub: true;
  test-custom: black;
  test-native: black;
  /*! #010000 == #010000 */
  test-div: true;
  test-custom: #010000;
  test-native: #010000;
  /*! #010000 == red */
  test-mul: true;
  test-custom: red;
  test-native: red;
  /*! black == black */
  test-mod: true;
  test-custom: black;
  test-native: black; }

booleans {
  /*! truefalse == truefalse */
  test-add: true;
  test-custom: truefalse;
  test-native: truefalse;
  /*! true-false == true-false */
  test-sub: true;
  test-custom: true-false;
  test-native: true-false;
  /*! true/false == true/false */
  test-div: true;
  test-custom: true/false;
  test-native: true/false; }
END_OF_EXPECTED

eq_or_diff ($r, $expected, "big custom operation test");
is ($err, undef, "big custom operation test has no error");
