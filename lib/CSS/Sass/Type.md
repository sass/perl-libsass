# NAME

CSS::Sass::Types - Data Types for custom Sass Functions

# Mapping `Sass_Values` to perl data structures

You can use `maps` and `lists` like normal `hash` or `array` references. Lists
can have two different separators used for stringification. This is detected by
checking if the object is derived from `CSS::Sass::Type::List::Space`. The default
is a comma separated list, which you get by instantiating `CSS::Sass::Type::List`
or `CSS::Sass::Type::List::Comma`.

    my $null = CSS::Sass::Type->new(undef); # => 'null'
    my $number = CSS::Sass::Type->new(42.35); # => 42.35
    my $string = CSS::Sass::Type->new("foobar"); # => 'foobar'
    my $map = CSS::Sass::Type->new({ key => "foobar" }); # 'key: foobar'
    my $list = CSS::Sass::Type->new([ "foo", 42, "bar" ]); # 'foo, 42, bar'
    my $space = CSS::Sass::Type::List::Space->new("foo", "bar"); # 'foo bar'
    my $comma = CSS::Sass::Type::List::Comma->new("foo", "bar"); # 'foo, bar'

You can also return these native perl types from custom functions. They will
automatically be upgraded to real `CSS::Sass::Type` objects. All types
overload the `stringify` and `eq` function (so far).

## `CSS::Sass::Type`

Acts as a base class for all other types and is mainly an abstract class.
It only implements a generic constructor, which accepts native perl data types
(undef, numbers, strings, array-refs and hash-refs) and `CSS::Sass::Type` objects.

## `CSS::Sass::Type::Null`

    my $null = CSS::Sass::Type::Null->new;
    my $string = "$null"; # eq 'null'
    my $value = $null->value; # == undef

## `CSS::Sass::Type::Boolean`

    my $bool = CSS::Sass::Type::Boolean->new(42);
    my $string = "$bool"; # eq 'true'
    my $value = $bool->value; # == 1

## `CSS::Sass::Type::Number`

    my $number = CSS::Sass::Type::Boolean->new(42, 'px');
    my $string = "$number"; # eq '42px'
    my $value = $number->value; # == 42
    my $unit = $number->unit; # eq 'px'

## `CSS::Sass::Type::String`

    my $string = CSS::Sass::Type->new("foo bar"); # => "foo bar"
    my $quoted = "$string"; # eq '"foo bar"'
    my $unquoted = $string->value; # eq 'foo bar'

## `CSS::Sass::Type::Color`

    my $color = CSS::Sass::Type::Color->new(64, 128, 32, 0.25);
    my $string = "$color"; # eq 'rgba(64, 128, 32, 0.25)'
    my $r = $color->r; # == 64
    my $g = $color->g; # == 128
    my $b = $color->b; # == 32
    my $a = $color->a; # == 0.25

## `CSS::Sass::Type::Map`

    my $map = CSS::Sass::Type::Map->new(key => 'value');
    my $string = "$map"; # eq 'key: value'
    my $value = $map->{'key'}; # eq 'value'

## `CSS::Sass::Type::List::Comma`

    my $list = CSS::Sass::Type::List::Comma->new('foo', 'bar');
    my $string = "$list"; # eq 'foo, bar'
    my $value = $list->[0]; # eq 'foo'

## `CSS::Sass::Type::List::Space`

    my $list = CSS::Sass::Type::List::Space->new('foo', 'bar');
    my $string = "$list"; # eq 'foo bar'
    my $value = $list->[-1]; # eq 'bar'

# SEE ALSO

[CSS::Sass](https://metacpan.org/pod/CSS::Sass)

# AUTHOR

David Caldwell <david@porkrind.org>  
Marcel Greter <perl-libsass@ocbnet.ch>

# COPYRIGHT AND LICENSE

Copyright (C) 2013 by David Caldwell  
Copyright (C) 2014 by Marcel Greter

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.
