# -*- perl -*-

use utf8;
use strict;
use warnings;

BEGIN {
	use Test::More;
}

use Test::More tests => 9;

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
my $mul_1 = sass_operation(CSS::Sass::MUL, $number_42, $number_42px);
my $div_1 = sass_operation(CSS::Sass::DIV, $number_42, $number_42px);
my $add_1 = sass_operation(CSS::Sass::ADD, $number_42, $number_42px);
my $sub_1 = sass_operation(CSS::Sass::SUB, $number_42, $number_42px);
my $mod_1 = sass_operation(CSS::Sass::MOD, $number_42, $number_42px);
my $eq_1 = sass_operation(CSS::Sass::EQ, $number_42, $number_42);
my $eq_2 = sass_operation(CSS::Sass::EQ, $number_42, $number_42px);
my $eq_3 = sass_operation(CSS::Sass::EQ, $number_42px, $number_42px);

is($mul_1, CSS::Sass::Value::Number->new(42 * 42, "px"), "number_42 * number_42px ok");
is($div_1, CSS::Sass::Value::Number->new(42 / 42, "/px"), "number_42 - number_42px ok");
is($add_1, CSS::Sass::Value::Number->new(42 + 42, "px"), "number_42 + number_42px ok");
is($sub_1, CSS::Sass::Value::Number->new(42 - 42, "px"), "number_42 - number_42px ok");
is($mod_1, CSS::Sass::Value::Number->new(42 % 42, "px"), "number_42 % number_42px ok");
is($eq_1, CSS::Sass::Value::Boolean->new(1), "number_42 == number_42 ok");
is($eq_2, CSS::Sass::Value::Boolean->new(0), "number_42 == number_42px ok");
is($eq_3, CSS::Sass::Value::Boolean->new(1), "number_42px == number_42px ok");

my ($r, $err) = CSS::Sass::sass_compile(
  '
  @mixin test_op($a, $b) {

    /*! #{inspect(op_div($a, $b))} == #{($a / $b)} */
    valid: op_div($a, $b) == $a / $b;
    valid: inspect(op_div($a, $b));
    valid: inspect(($a / $b));
  }
  test {
    @include test_op(42, 42px);
  }',
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
    'op_mul($a, $b)' => sub { return sass_operation(CSS::Sass::MUL, $_[0], $_[1]) },
    'op_div($a, $b)' => sub { return sass_operation(CSS::Sass::DIV, $_[0], $_[1]) },
    'op_mod($a, $b)' => sub { return sass_operation(CSS::Sass::MOD, $_[0], $_[1]) },


  }
);

