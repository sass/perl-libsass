# Copyright (c) 2013-2014 David Caldwell.
# Copyright (c) 2014-2017 Marcel Greter.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# internal representation
# accepted from functions
# are blessed automatically

# \% -> map
# \undef -> null
# \"foobar" -> string
# \@ -> list (comma sep)
# \42 -> number (no unit)
# \4.2 -> number (no unit)

# internal representations differ slightly
# for list only the blessed class is important

use strict;
use warnings;
use CSS::Sass;

################################################################################
package CSS::Sass::Value;
our $VERSION = "3.4.10";
################################################################################
use CSS::Sass qw(import_sv);
use CSS::Sass qw(sass_operation);
use CSS::Sass qw(sass_stringify);
################################################################################
use overload '""' => 'stringify'; # allow further overloading
################################################################################
use overload 'bool' => sub { sass_operation(CSS::Sass::OR, $_[0], undef)->value ? 1 : 0; };
################################################################################
use overload '&' => sub { sass_operation(CSS::Sass::AND, ($_[2] ? $_[1] : $_[0]), ($_[2] ? $_[0] : $_[1]))->value ? 1 : 0; };
use overload '|' => sub { sass_operation(CSS::Sass::OR, ($_[2] ? $_[1] : $_[0]), ($_[2] ? $_[0] : $_[1]))->value ? 1 : 0; };
################################################################################
use overload 'eq' => sub { sass_stringify($_[0])->value eq sass_stringify($_[1])->value ? 1 : 0; };
use overload 'ne' => sub { sass_stringify($_[0])->value ne sass_stringify($_[1])->value ? 1 : 0; };
use overload '==' => sub { sass_operation(CSS::Sass::EQ, $_[0], $_[1])->value ? 1 : 0; };
use overload '!=' => sub { sass_operation(CSS::Sass::NEQ, $_[0], $_[1])->value ? 1 : 0; };
################################################################################
use overload 'eq' => sub { sass_stringify($_[2] ? $_[1] : $_[0])->value eq sass_stringify($_[2] ? $_[0] : $_[1])->value ? 1 : 0; };
use overload 'ne' => sub { sass_stringify($_[2] ? $_[1] : $_[0])->value ne sass_stringify($_[2] ? $_[0] : $_[1])->value ? 1 : 0; };
use overload '==' => sub { sass_operation(CSS::Sass::EQ, ($_[2] ? $_[1] : $_[0]), ($_[2] ? $_[0] : $_[1]))->value ? 1 : 0; };
use overload '!=' => sub { sass_operation(CSS::Sass::NEQ, ($_[2] ? $_[1] : $_[0]), ($_[2] ? $_[0] : $_[1]))->value ? 1 : 0; };
################################################################################
use overload 'lt' => sub { sass_stringify($_[2] ? $_[1] : $_[0])->value lt sass_stringify($_[2] ? $_[0] : $_[1])->value ? 1 : 0; };
use overload 'le' => sub { sass_stringify($_[2] ? $_[1] : $_[0])->value le sass_stringify($_[2] ? $_[0] : $_[1])->value ? 1 : 0; };
use overload 'gt' => sub { sass_stringify($_[2] ? $_[1] : $_[0])->value gt sass_stringify($_[2] ? $_[0] : $_[1])->value ? 1 : 0; };
use overload 'ge' => sub { sass_stringify($_[2] ? $_[1] : $_[0])->value ge sass_stringify($_[2] ? $_[0] : $_[1])->value ? 1 : 0; };
################################################################################
use overload '<'  => sub { sass_operation(CSS::Sass::LT , ($_[2] ? $_[1] : $_[0]), ($_[2] ? $_[0] : $_[1]))->value ? 1 : 0; };
use overload '<=' => sub { sass_operation(CSS::Sass::LTE, ($_[2] ? $_[1] : $_[0]), ($_[2] ? $_[0] : $_[1]))->value ? 1 : 0; };
use overload '>'  => sub { sass_operation(CSS::Sass::GT , ($_[2] ? $_[1] : $_[0]), ($_[2] ? $_[0] : $_[1]))->value ? 1 : 0; };
use overload '>=' => sub { sass_operation(CSS::Sass::GTE, ($_[2] ? $_[1] : $_[0]), ($_[2] ? $_[0] : $_[1]))->value ? 1 : 0; };
################################################################################
use overload '+' => sub { sass_operation(CSS::Sass::ADD, ($_[2] ? $_[1] : $_[0]), ($_[2] ? $_[0] : $_[1])); };
use overload '-' => sub { sass_operation(CSS::Sass::SUB, ($_[2] ? $_[1] : $_[0]), ($_[2] ? $_[0] : $_[1])); };
use overload '*' => sub { sass_operation(CSS::Sass::MUL, ($_[2] ? $_[1] : $_[0]), ($_[2] ? $_[0] : $_[1])); };
use overload '/' => sub { sass_operation(CSS::Sass::DIV, ($_[2] ? $_[1] : $_[0]), ($_[2] ? $_[0] : $_[1])); };
use overload '%' => sub { sass_operation(CSS::Sass::MOD, ($_[2] ? $_[1] : $_[0]), ($_[2] ? $_[0] : $_[1])); };
################################################################################

sub new { import_sv($_[1]) }
sub clone { import_sv($_[0]) }

# default implementations
sub quoted { sass_stringify($_[0])->value }
sub stringify { sass_stringify($_[0])->value }

################################################################################
package CSS::Sass::Value::Null;
################################################################################
use base 'CSS::Sass::Value';
################################################################################

sub new {
	my ($class) = @_;
	my $null = undef;
	bless \\ $null, $class;
}

sub value { undef }

################################################################################
package CSS::Sass::Value::Error;
################################################################################
use base 'CSS::Sass::Value';
################################################################################

sub new {
	my ($class, @msg) = @_;
	bless \\ [ @msg ], $class;
}

# cloning through sass.xs does not work?
# sub clone { bless \\ [ @{${${$_[0]}}} ] }

sub message {
	wantarray ? @{${${$_[0]}}} :
	            join "", @{${${$_[0]}}};
}

################################################################################
package CSS::Sass::Value::Boolean;
################################################################################
use base 'CSS::Sass::Value';
################################################################################

sub new {
	my ($class, $bool) = @_;
	$bool = $bool ? 1 : 0;
	bless \\ $bool, $class;
}

sub value {
	if (scalar(@_) > 1) {
		${${$_[0]}} = $_[1] ? 1 : 0;
	}
	${${$_[0]}};
}

################################################################################
package CSS::Sass::Value::String;
################################################################################
use base 'CSS::Sass::Value';
################################################################################
use CSS::Sass qw(quote need_quotes sass_stringify);
################################################################################

sub new {
	my ($class, $string, $quotes) = @_;
	if (defined $quotes) {
		if ($quotes) { $class = "CSS::Sass::Value::String::Quoted"; }
		else { $class = "CSS::Sass::Value::String::Constant"; }
	}
	$string = "" unless defined $string;
	bless \ $string, $class;
}

sub value {
	if (scalar(@_) > 1) {
		${$_[0]} = defined $_[1] ? $_[1] : "";
	}
	defined ${$_[0]} ? ${$_[0]} : "";
}

sub has_quotes {
	need_quotes(${$_[0]}) ? 1 : 0;
}

sub quoted { "$_[0]" }

################################################################################
package CSS::Sass::Value::String::Constant;
################################################################################
use base 'CSS::Sass::Value::String';
################################################################################

sub new { shift->SUPER::new($_[0], 0); }

sub has_quotes { 0 }

################################################################################
package CSS::Sass::Value::String::Quoted;
################################################################################
use base 'CSS::Sass::Value::String';
################################################################################

sub new { shift->SUPER::new($_[0], 1); }

sub has_quotes { 1 }

################################################################################
package CSS::Sass::Value::Number;
################################################################################
use base 'CSS::Sass::Value';
################################################################################

sub new {
	my ($class, $number, $unit) = @_;
	$unit = '' unless defined $unit;
	$number = 0 unless defined $number;
	bless \ [ $number, $unit ], $class;
}

sub value {
	if (scalar(@_) > 1) {
		${$_[0]}->[0] = defined $_[1] ? $_[1] : 0;
	}
	sprintf "%g", ${$_[0]}->[0];
}

sub unit {
	if (scalar(@_) > 1) {
		${$_[0]}->[1] = defined $_[1] ? $_[1] : "";
	}
	${$_[0]}->[1];
}

################################################################################
package CSS::Sass::Value::Color;
################################################################################
use base 'CSS::Sass::Value';
################################################################################

sub new {
	my ($class, $r, $g, $b, $a) = @_;
	$a = 1 unless defined $a;
	bless \ { r => $r, g => $g, b => $b, a => $a }, $class;
}

my $accessor = sub {
	if (scalar(@_) > 2) {
		${$_[1]}->{$_[0]} = $_[2];
	}
	${$_[1]}->{$_[0]}
};

sub r { $accessor->('r', @_) }
sub g { $accessor->('g', @_) }
sub b { $accessor->('b', @_) }
sub a { $accessor->('a', @_) }

sub stringify {
	my $r = ${$_[0]}->{'r'};
	my $g = ${$_[0]}->{'g'};
	my $b = ${$_[0]}->{'b'};
	my $a = ${$_[0]}->{'a'};
	unless (defined $a && $a != 0) {
		"transparent"
	} elsif (defined $a && $a != 1) {
		sprintf("rgba(%s, %s, %s, %s)", $r, $g, $b, $a)
	} elsif (defined $r || defined $g || defined $b) {
		sprintf("rgb(%s, %s, %s)", $r || 0, $g || 0, $b || 0)
	} else {
		"null"
	}
}


################################################################################
package CSS::Sass::Value::Map;
################################################################################
use base 'CSS::Sass::Value';
################################################################################
use CSS::Sass qw(quote);
################################################################################

sub new {
	my $class = shift;
	my $hash = { @_ };
	foreach (values %{$hash}) {
		$_ = CSS::Sass::Value->new($_);
	}
	bless $hash , $class;
}

sub keys { CORE::keys %{$_[0]} }
sub values { CORE::values %{$_[0]} }

sub stringify {
	sprintf "{ %s }",
		join ', ', map
			{ join ": ", $_, $_[0]->{$_} }
			CORE::keys %{$_[0]};
}

################################################################################
package CSS::Sass::Value::List;
################################################################################
use base 'CSS::Sass::Value';
################################################################################
use CSS::Sass qw(SASS_COMMA);
################################################################################

sub new {
	my $class = shift;
	my $list = [ map { CSS::Sass::Value->new($_) } @_ ];
	bless $list, $class;
}

sub values { @{$_[0]} }

sub listjoint { ', ' }
sub separator { return SASS_COMMA }

sub stringify
{
	sprintf "[ %s ]",
		join $_[0]->listjoint,
			# force quotes around values
			map { ref $_ ? $_->quoted(1) : $_ }
			@{$_[0]};
}

################################################################################
package CSS::Sass::Value::List::Comma;
################################################################################
use base 'CSS::Sass::Value::List';
################################################################################
use CSS::Sass qw(SASS_COMMA);
################################################################################
sub new { shift->SUPER::new(@_) }
sub separator { return SASS_COMMA }
sub listjoint { ', ' }

################################################################################
package CSS::Sass::Value::List::Space;
################################################################################
use base 'CSS::Sass::Value::List';
################################################################################
use CSS::Sass qw(SASS_SPACE);
################################################################################
sub new { shift->SUPER::new(@_) }
sub separator { return SASS_SPACE }
sub listjoint { ' ' }

################################################################################
package CSS::Sass::Value;
################################################################################
1;

__END__

=head1 NAME

CSS::Sass::Value - Data Types for custom Sass Functions

=head1 Mapping C<Sass_Values> to perl data structures

You can use C<maps> and C<lists> like normal C<hash> or C<array> references. Lists
can have two different separators used for stringification. This is detected by
checking if the object is derived from C<CSS::Sass::Value::List::Space>. The default
is a comma separated list, which you get by instantiating C<CSS::Sass::Value::List>
or C<CSS::Sass::Value::List::Comma>.

    my $null = CSS::Sass::Value->new(undef); # => 'null'
    my $number = CSS::Sass::Value->new(42.35); # => 42.35
    my $string = CSS::Sass::Value->new("foobar"); # => 'foobar'
    my $map = CSS::Sass::Value->new({ key => "foobar" }); # 'key: foobar'
    my $list = CSS::Sass::Value->new([ "foo", 42, "bar" ]); # 'foo, 42, bar'
    my $space = CSS::Sass::Value::List::Space->new("foo", "bar"); # 'foo bar'
    my $comma = CSS::Sass::Value::List::Comma->new("foo", "bar"); # 'foo, bar'

You can also return these native perl types from custom functions. They will
automatically be upgraded to real C<CSS::Sass::Value> objects. All types
overload the C<stringify> and C<eq> operators (so far).

=head2 CSS::Sass::Value

Acts as a base class for all other types and is mainly an abstract class.
It only implements a generic constructor, which accepts native perl data types
(undef, numbers, strings, array-refs and hash-refs) and C<CSS::Sass::Value> objects.

=head2 CSS::Sass::Value::Null

    my $null = CSS::Sass::Value::Null->new;
    my $string = "$null"; # eq 'null'
    my $value = $null->value; # == undef

=head2 CSS::Sass::Value::Boolean

    my $bool = CSS::Sass::Value::Boolean->new(42);
    my $string = "$bool"; # eq 'true'
    my $value = $bool->value; # == 1

=head2 CSS::Sass::Value::Number

    my $number = CSS::Sass::Value::Boolean->new(42, 'px');
    my $string = "$number"; # eq '42px'
    my $value = $number->value; # == 42
    my $unit = $number->unit; # eq 'px'

=head2 CSS::Sass::Value::String

    my $string = CSS::Sass::Value->new("foo bar"); # => "foo bar"
    my $quoted = "$string"; # eq '"foo bar"'
    my $unquoted = $string->value; # eq 'foo bar'

=head2 CSS::Sass::Value::Color

    my $color = CSS::Sass::Value::Color->new(64, 128, 32, 0.25);
    my $string = "$color"; # eq 'rgba(64, 128, 32, 0.25)'
    my $r = $color->r; # == 64
    my $g = $color->g; # == 128
    my $b = $color->b; # == 32
    my $a = $color->a; # == 0.25

=head2 CSS::Sass::Value::Map

    my $map = CSS::Sass::Value::Map->new(key => 'value');
    my $string = "$map"; # eq 'key: "value"'
    my $value = $map->{'key'}; # eq '"value"'

=head2 CSS::Sass::Value::List::Comma

    my $list = CSS::Sass::Value::List::Comma->new('foo', 'bar');
    my $string = "$list"; # eq '"foo", "bar"'
    my $value = $list->[0]; # eq 'foo'

=head2 CSS::Sass::Value::List::Space

    my $list = CSS::Sass::Value::List::Space->new('foo', 'bar');
    my $string = "$list"; # eq '"foo" "bar"'
    my $value = $list->[-1]; # eq 'bar'

=head1 SEE ALSO

L<CSS::Sass>

=head1 AUTHOR

David Caldwell E<lt>david@porkrind.orgE<gt>  
Marcel Greter E<lt>perl-libsass@ocbnet.chE<gt>

=head1 LICENSE

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

=cut
