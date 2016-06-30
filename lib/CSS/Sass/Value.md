# NAME

CSS::Sass::Value - Data Types for custom Sass Functions

# Mapping `Sass_Values` to perl data structures

You can use `maps` and `lists` like normal `hash` or `array` references. Lists
can have two different separators used for stringification. This is detected by
checking if the object is derived from `CSS::Sass::Value::List::Space`. The default
is a comma separated list, which you get by instantiating `CSS::Sass::Value::List`
or `CSS::Sass::Value::List::Comma`.

    my $null = CSS::Sass::Value->new(undef); # => 'null'
    my $number = CSS::Sass::Value->new(42.35); # => 42.35
    my $string = CSS::Sass::Value->new("foobar"); # => 'foobar'
    my $map = CSS::Sass::Value->new({ key => "foobar" }); # 'key: foobar'
    my $list = CSS::Sass::Value->new([ "foo", 42, "bar" ]); # 'foo, 42, bar'
    my $space = CSS::Sass::Value::List::Space->new("foo", "bar"); # 'foo bar'
    my $comma = CSS::Sass::Value::List::Comma->new("foo", "bar"); # 'foo, bar'

You can also return these native perl types from custom functions. They will
automatically be upgraded to real `CSS::Sass::Value` objects. All types
overload the `stringify` and `eq` operators (so far).

## CSS::Sass::Value

Acts as a base class for all other types and is mainly an abstract class.
It only implements a generic constructor, which accepts native perl data types
(undef, numbers, strings, array-refs and hash-refs) and `CSS::Sass::Value` objects.

## CSS::Sass::Value::Null

    my $null = CSS::Sass::Value::Null->new;
    my $string = "$null"; # eq 'null'
    my $value = $null->value; # == undef

## CSS::Sass::Value::Boolean

    my $bool = CSS::Sass::Value::Boolean->new(42);
    my $string = "$bool"; # eq 'true'
    my $value = $bool->value; # == 1

## CSS::Sass::Value::Number

    my $number = CSS::Sass::Value::Boolean->new(42, 'px');
    my $string = "$number"; # eq '42px'
    my $value = $number->value; # == 42
    my $unit = $number->unit; # eq 'px'

## CSS::Sass::Value::String

    my $string = CSS::Sass::Value->new("foo bar"); # => "foo bar"
    my $quoted = "$string"; # eq '"foo bar"'
    my $unquoted = $string->value; # eq 'foo bar'

## CSS::Sass::Value::Color

    my $color = CSS::Sass::Value::Color->new(64, 128, 32, 0.25);
    my $string = "$color"; # eq 'rgba(64, 128, 32, 0.25)'
    my $r = $color->r; # == 64
    my $g = $color->g; # == 128
    my $b = $color->b; # == 32
    my $a = $color->a; # == 0.25

## CSS::Sass::Value::Map

    my $map = CSS::Sass::Value::Map->new(key => 'value');
    my $string = "$map"; # eq 'key: "value"'
    my $value = $map->{'key'}; # eq '"value"'

## CSS::Sass::Value::List::Comma

    my $list = CSS::Sass::Value::List::Comma->new('foo', 'bar');
    my $string = "$list"; # eq '"foo", "bar"'
    my $value = $list->[0]; # eq 'foo'

## CSS::Sass::Value::List::Space

    my $list = CSS::Sass::Value::List::Space->new('foo', 'bar');
    my $string = "$list"; # eq '"foo" "bar"'
    my $value = $list->[-1]; # eq 'bar'

# SEE ALSO

[CSS::Sass](https://metacpan.org/pod/CSS::Sass)

# AUTHOR

David Caldwell &lt;david@porkrind.org>  
Marcel Greter &lt;perl-libsass@ocbnet.ch>

# LICENSE

The MIT License (MIT)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
