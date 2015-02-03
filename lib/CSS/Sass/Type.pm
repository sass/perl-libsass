# Copyright (c) 2013 David Caldwell,
# Copyright (c) 2014 Marcel Greter,
# All Rights Reserved. -*- cperl -*-

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

# missing: error, boolean, color, number with unit



use strict;
use warnings;
use CSS::Sass;

################################################################################
package CSS::Sass::Type;
our $VERSION = "v3.1.1";
################################################################################
use CSS::Sass qw(import_sv);
################################################################################
sub new { import_sv($_[1]) }


################################################################################
package CSS::Sass::Type::Null;
################################################################################
use base 'CSS::Sass::Type';
################################################################################
use overload '""' => 'stringify';
use overload 'eq' => 'equals';
################################################################################

sub new {
	my ($class) = @_;
	my $null = undef;
	bless \\ $null, $class;
}

sub value { undef }

sub stringify { "null" }

sub equals { ! defined $_[0] }

################################################################################
package CSS::Sass::Type::Error;
################################################################################
use base 'CSS::Sass::Type';
################################################################################
use overload '""' => 'stringify';
use overload 'eq' => 'equals';
################################################################################

sub new {
	my ($class, @msg) = @_;
	bless \\ [ @msg ], $class;
}

sub message {
	wantarray ? @{${${$_[0]}}} :
	            join "", @{${${$_[0]}}};
}

sub stringify {
	scalar(@{${${$_[0]}}}) ?
	  join "", @{${${$_[0]}}}
	  : "error";
}

sub equals {
	shift->stringify eq $_[0]
}

################################################################################
package CSS::Sass::Type::Boolean;
################################################################################
use base 'CSS::Sass::Type';
################################################################################
use overload '""' => 'stringify';
use overload 'eq' => 'equals';
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

sub stringify {
	shift->value ? "true" : "false";
}

sub equals {
	shift->stringify eq $_[0]
}

################################################################################
package CSS::Sass::Type::String;
################################################################################
use base 'CSS::Sass::Type';
################################################################################
use CSS::Sass qw(quote unquote);
################################################################################
use overload '""' => 'stringify';
use overload 'eq' => 'equals';
################################################################################

sub new {
	my ($class, $string) = @_;
	$string = "" unless defined $string;
	# we may can unquote the string!
	# should we really do this here?
	bless \ $string, $class;
}

sub value {
	if (scalar(@_) > 1) {
		${$_[0]} = defined $_[1] ? $_[1] : "";
	}
	defined ${$_[0]} ? unquote(${$_[0]}) : "";
}

sub stringify {
	$_ = shift->value;
	m/^\w*$/ ? $_ : quote($_);
}

sub equals {
	shift->stringify eq $_[0]
}

################################################################################
package CSS::Sass::Type::Number;
################################################################################
use base 'CSS::Sass::Type';
################################################################################
use overload '""' => 'stringify';
use overload 'eq' => 'equals';
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

sub stringify {
	sprintf "%g%s", @{${$_[0]}};
}

sub equals {
	shift->stringify eq $_[0]
}

################################################################################
package CSS::Sass::Type::Color;
################################################################################
use base 'CSS::Sass::Type';
################################################################################
use overload '""' => 'stringify';
use overload 'eq' => 'equals';
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
	} elsif ($r || $g || $b) {
		sprintf("rgb(%s, %s, %s)", $r, $g, $b)
	} else {
		"null"
	}
}

sub equals {
	shift->stringify eq $_[0]
}


################################################################################
package CSS::Sass::Type::Map;
################################################################################
use base 'CSS::Sass::Type';
################################################################################
use overload '""' => 'stringify';
use overload 'eq' => 'equals';
################################################################################

sub new {
	my $class = shift;
	my $hash = { @_ };
	foreach (values %{$hash}) {
		$_ = CSS::Sass::Type->new($_);
	}
	bless $hash , $class;
}

sub keys { CORE::keys %{$_[0]} }
sub values { CORE::values %{$_[0]} }

sub stringify {
	join ', ', map { join ": ", $_, $_[0]->{$_} } CORE::keys %{$_[0]};
}

sub equals {
	shift->stringify eq $_[0]
}


################################################################################
package CSS::Sass::Type::List;
################################################################################
use base 'CSS::Sass::Type';
################################################################################
use overload '""' => 'stringify';
use overload 'eq' => 'equals';
################################################################################

sub new {
	my $class = shift;
	my $list = [ map { CSS::Sass::Type->new($_) } @_ ];
	bless $list, $class;
}

sub values { @{$_[0]} }

sub stringify { join ', ', @{$_[0]} }
sub equals { shift->stringify eq $_[0] }

################################################################################
package CSS::Sass::Type::List::Comma;
################################################################################
use base 'CSS::Sass::Type::List';
################################################################################
use CSS::Sass qw(SASS_COMMA);
################################################################################
sub new { shift->SUPER::new(@_) }
sub separator { return SASS_COMMA }
sub stringify { join ', ', @{$_[0]} }

################################################################################
package CSS::Sass::Type::List::Space;
################################################################################
use base 'CSS::Sass::Type::List';
################################################################################
use CSS::Sass qw(SASS_SPACE);
################################################################################
sub new { shift->SUPER::new(@_) }
sub separator { return SASS_SPACE }
sub stringify { join ' ', @{$_[0]} }

################################################################################
package CSS::Sass::Type;
################################################################################
1;

__END__

=head1 NAME

CSS::Sass::Type - Data Types for custom Sass Functions

=head1 Mapping C<Sass_Values> to perl data structures

You can use C<maps> and C<lists> like normal C<hash> or C<array> references. Lists
can have two different separators used for stringification. This is detected by
checking if the object is derived from C<CSS::Sass::Type::List::Space>. The default
is a comma separated list, which you get by instantiating C<CSS::Sass::Type::List>
or C<CSS::Sass::Type::List::Comma>.

    my $null = CSS::Sass::Type->new(undef); # => 'null'
    my $number = CSS::Sass::Type->new(42.35); # => 42.35
    my $string = CSS::Sass::Type->new("foobar"); # => 'foobar'
    my $map = CSS::Sass::Type->new({ key => "foobar" }); # 'key: foobar'
    my $list = CSS::Sass::Type->new([ "foo", 42, "bar" ]); # 'foo, 42, bar'
    my $space = CSS::Sass::Type::List::Space->new("foo", "bar"); # 'foo bar'
    my $comma = CSS::Sass::Type::List::Comma->new("foo", "bar"); # 'foo, bar'

You can also return these native perl types from custom functions. They will
automatically be upgraded to real C<CSS::Sass::Type> objects. All types
overload the C<stringify> and C<eq> operators (so far).

=head2 CSS::Sass::Type

Acts as a base class for all other types and is mainly an abstract class.
It only implements a generic constructor, which accepts native perl data types
(undef, numbers, strings, array-refs and hash-refs) and C<CSS::Sass::Type> objects.

=head2 CSS::Sass::Type::Null

    my $null = CSS::Sass::Type::Null->new;
    my $string = "$null"; # eq 'null'
    my $value = $null->value; # == undef

=head2 CSS::Sass::Type::Boolean

    my $bool = CSS::Sass::Type::Boolean->new(42);
    my $string = "$bool"; # eq 'true'
    my $value = $bool->value; # == 1

=head2 CSS::Sass::Type::Number

    my $number = CSS::Sass::Type::Boolean->new(42, 'px');
    my $string = "$number"; # eq '42px'
    my $value = $number->value; # == 42
    my $unit = $number->unit; # eq 'px'

=head2 CSS::Sass::Type::String

    my $string = CSS::Sass::Type->new("foo bar"); # => "foo bar"
    my $quoted = "$string"; # eq '"foo bar"'
    my $unquoted = $string->value; # eq 'foo bar'

=head2 CSS::Sass::Type::Color

    my $color = CSS::Sass::Type::Color->new(64, 128, 32, 0.25);
    my $string = "$color"; # eq 'rgba(64, 128, 32, 0.25)'
    my $r = $color->r; # == 64
    my $g = $color->g; # == 128
    my $b = $color->b; # == 32
    my $a = $color->a; # == 0.25

=head2 CSS::Sass::Type::Map

    my $map = CSS::Sass::Type::Map->new(key => 'value');
    my $string = "$map"; # eq 'key: value'
    my $value = $map->{'key'}; # eq 'value'

=head2 CSS::Sass::Type::List::Comma

    my $list = CSS::Sass::Type::List::Comma->new('foo', 'bar');
    my $string = "$list"; # eq 'foo, bar'
    my $value = $list->[0]; # eq 'foo'

=head2 CSS::Sass::Type::List::Space

    my $list = CSS::Sass::Type::List::Space->new('foo', 'bar');
    my $string = "$list"; # eq 'foo bar'
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
