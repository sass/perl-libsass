#  Copyright (c) 2013 David Caldwell,  All Rights Reserved. -*- cperl -*-

use strict; use warnings;

use CSS::Sass;

package CSS::Sass::Type;
use base 'Class::Accessor::Fast';

my %field;
my %tag_from_class;
my %class_from_tag;

sub add_field {
    my ($class, $tag, @new_field) = @_;
    $class->mk_accessors(@new_field);
    push @{$field{$class}}, @new_field;
    $tag_from_class{$class} = $tag if defined $tag;
    $class_from_tag{$tag} = $class if defined $tag;
}
sub xs_rep {
    my $self = shift;
    [ $tag_from_class{ref $self}, map { $self->{$_} } @{$field{ref $self}} ];
}
sub new_from_xs_rep {
    my ($baseclass, $xsrep) = @_;
    my $tag = shift @$xsrep;
    my $class = $class_from_tag{$tag};
    die "Couldn't find class for tag $tag!" unless $class;
    $class->new(@$xsrep);
}
sub new {
    my $class = shift;
    my %param;
    $param{$field{$class}->[$_]} = $_[$_] for (0..$#_);
    # warn Data::Dumper->Dump([\%param], ['param']);
    bless \%param, $class;
}
__PACKAGE__->add_field(undef, qw());

package CSS::Sass::Type::Boolean;
use base 'CSS::Sass::Type';
__PACKAGE__->add_field(CSS::Sass::SASS_BOOLEAN, qw(value));

package CSS::Sass::Type::Number;
use base 'CSS::Sass::Type';
__PACKAGE__->add_field(CSS::Sass::SASS_NUMBER, qw(value));

package CSS::Sass::Type::Percentage;
use base 'CSS::Sass::Type';
__PACKAGE__->add_field(CSS::Sass::SASS_PERCENTAGE, qw(value));

package CSS::Sass::Type::Dimension;
use base 'CSS::Sass::Type';
__PACKAGE__->add_field(CSS::Sass::SASS_DIMENSION, qw(value units));

package CSS::Sass::Type::Color;
use base 'CSS::Sass::Type';
__PACKAGE__->add_field(CSS::Sass::SASS_COLOR, qw(r g b a));

package CSS::Sass::Type::String;
use base 'CSS::Sass::Type';
__PACKAGE__->add_field(CSS::Sass::SASS_STRING, qw(value));
sub value {
    # libsass adds quotes around the strings for some reason, but works fine without them. So we just strip them in the accessor.
    my $self = shift;
    my $rep = $self->{value};
    $rep =~ s/(["'])(.*)\1/$2/;
    $rep;
}

package CSS::Sass::Type::List;
use base 'CSS::Sass::Type';
__PACKAGE__->add_field(CSS::Sass::SASS_LIST, qw(separator values));
sub xs_rep {
    # Need to recurse for lists.
    my $self = shift;
    [ CSS::Sass::SASS_LIST, $self->separator, map { $_->xs_rep } @{$self->values} ];
}

package CSS::Sass::Type::Error;
use base 'CSS::Sass::Type';
__PACKAGE__->add_field(CSS::Sass::SASS_ERROR, qw(message));
1;
