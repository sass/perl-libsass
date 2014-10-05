# Copyright © 2013 David Caldwell.
# Copyright © 2014 Marcel Greter.
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself, either Perl version 5.12.4 or,
# at your option, any later version of Perl 5 you may have available.

package CSS::Sass;

use strict;
use warnings;
use Carp;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw(
	sass2scss
	sass_compile
	sass_compile_file
);

our @EXPORT = qw(
	SASS_STYLE_NESTED
	SASS_STYLE_COMPRESSED
	SASS2SCSS_PRETTIFY_0
	SASS2SCSS_PRETTIFY_1
	SASS2SCSS_PRETTIFY_2
	SASS2SCSS_PRETTIFY_3
	SASS2SCSS_KEEP_COMMENT
	SASS2SCSS_STRIP_COMMENT
	SASS2SCSS_CONVERT_COMMENT
);

our $VERSION = "v3.0.0";

require XSLoader;
XSLoader::load('CSS::Sass', $VERSION);
require CSS::Sass::Type;

sub new {
    my ($class, %options) = @_;
    # Ensure initial sub structures on options
    $options{include_paths} = [] unless exists $options{include_paths};
    $options{sass_functions} = {} unless exists $options{sass_functions};
    # Create and return new object with options
    bless { options => \%options }, $class;
};

sub options {
    shift->{options}
}

sub last_error {
    my ($self) = @_;
    $self->{last_error}
}

sub sass_compile {
    my ($sass_code, %options) = @_;
    no warnings 'uninitialized';
    my $r = compile_sass($sass_code, { %options,
                                       # Override sass_functions with the arrayref of arrayrefs that the XS expects.
                                       !$options{sass_functions} ? ()
                                                                 : (sass_functions => [ map { [ $_ => $options{sass_functions}->{$_} ]
                                                                                            } keys %{$options{sass_functions}} ]),
                                       # Override include_paths with a ':' separated list
                                       !$options{include_paths} ? ()
                                                                : (include_paths => join($^O eq 'MSWin32' ? ';' : ':',
                                                                                         @{$options{include_paths}})),
                                     });
    wantarray ? ($r->{output_string}, $r->{error_message}, $r->{source_map_string}) : $r->{output_string}
}

sub sass_compile_file {
    my ($input_path, %options) = @_;
    no warnings 'uninitialized';
    my $r = compile_sass_file($input_path, { %options,
                                            # Override sass_functions with the arrayref of arrayrefs that the XS expects.
                                            !$options{sass_functions} ? ()
                                                                      : (sass_functions => [ map { [ $_ => $options{sass_functions}->{$_} ]
                                                                                                 } keys %{$options{sass_functions}} ]),
                                            # Override include_paths with a ':' separated list
                                            !$options{include_paths} ? ()
                                                                     : (include_paths => join($^O eq 'MSWin32' ? ';' : ':',
                                                                                              @{$options{include_paths}})),
                                          });
    wantarray ? ($r->{output_string}, $r->{error_message}, $r->{source_map_string}) : $r->{output_string}
}

sub compile {
    my ($self, $sass_code) = @_;
    my ($compiled, $srcmap);
    ($compiled, $self->{last_error}, $srcmap) = sass_compile($sass_code, %{$self->options});
    croak $self->{last_error} if $self->{last_error} && !$self->options->{dont_die};
    wantarray ? ($compiled, $srcmap) : $compiled
}

sub compile_file {
    my ($self, $sass_file) = @_;
    my ($compiled, $srcmap);
    ($compiled, $self->{last_error}, $srcmap) = sass_compile_file($sass_file, %{$self->options});
    croak $self->{last_error} if $self->{last_error} && !$self->options->{dont_die};
    wantarray ? ($compiled, $srcmap) : $compiled
}

sub sass_function_callback {
    my $cb = shift;
    my $ret = eval { $cb->(map { CSS::Sass::Type->new_from_xs_rep($_) } @_) };
    return CSS::Sass::Type::Error->new("$@")->xs_rep if $@;
    return CSS::Sass::Type::String->new('')->xs_rep if !defined $ret;
    return CSS::Sass::Type::Error->new("Perl Sass function returned something that wasn't a CSS::Sass::Type")->xs_rep
        unless ref $ret && $ret->isa("CSS::Sass::Type");
    $ret->xs_rep;
}

1;
__END__

=head1 NAME

CSS::Sass - Compile .scss files using libsass

=head1 SYNOPSIS

  # Object Oriented API
  use CSS::Sass;

  # Call default constructor
  my $sass = CSS::Sass->new;
  # Manipulate options for compile calls
  $sass->options->{source_comments} = 1;
  # Call file compilation (may die on errors)
  my $css = $sass->compile_file('styles.scss');

  # Add custom function to use inside your Sass code
  sub foobar { CSS::Sass::Type::String->new('blue') }
  $sass->options->{sass_functions}->{'foobar'} = \ &foobar;

  # Compile string and get css output and source map json
  $sass->options->{source_map_file} = 'output.css.map';
  ($css, $srcmap) = $sass->compile('A { color: foobar(); }');


  # Object Oriented API w/ options
  my $sass = CSS::Sass->new(include_paths   => ['some/include/path'],
                            image_path      => 'base_url',
                            output_style    => SASS_STYLE_COMPRESSED,
                            source_map_file => 'output.css.map',
                            source_comments => 1,
                            dont_die        => 1,
                            sass_functions  => {
                              'foobar($arg)' => sub { $_[0] }
                            });

  # Compile string and use the registered function
  my ($css, $srcmap) = $sass->compile('A { color: foobar(red); }');

  # Result can be undef because 'dont_die' was set
  warn $sass->last_error unless (defined $css);


  # Functional API
  use CSS::Sass qw(:Default sass_compile);

  # Functional API, with error messages and source map
  my ($css, $err, $srcmap) = sass_compile('A { color: red; }');
  die $err if defined $err;

  # Functional API, simple, with no error messages
  my $css = sass_compile('A { color: red; }');
  die unless defined $css;

  # Functional API w/ options
  my ($css, $err, $srcmap) = sass_compile('A { color: red; }',
                                          include_paths   => ['some/include/path'],
                                          image_path      => 'base_url',
                                          output_style    => SASS_STYLE_NESTED,
                                          source_map_file => 'output.css.map');

  # Import sass2scss function
  use CSS::Sass qw(sass2scss);

  # convert indented syntax
  my $scss = sass2scss($sass);

=head1 DESCRIPTION

CSS::Sass provides a perl interface to libsass, a fairly complete Sass
compiler written in C++. It is currently somewhere around ruby sass 3.2
feature parity. It can compile .scss and .sass files.

=head1 OBJECT ORIENTED INTERFACE

=over 4

=item C<new>

  $sass = CSS::Sass->new(options)

Creates a Sass object with the specified options. Example:

  $sass = CSS::Sass->new; # no options
  $sass = CSS::Sass->new(output_style => SASS_STYLE_NESTED);

=item C<compile(source_code)>

  $css = $sass->compile("A { color: blue; }");

This compiles the Sass string that is passed in as the first parameter. It
will C<croak()> if there is an error, unless the C<dont_die> option is set.
It will return C<undef> in that case.

=item C<last_error>

  $sass->last_error

Returns the error encountered by the most recent invocation of
C<compile>. This is only useful if the C<dont_die> option is set.

C<libsass> error messages are in the form ":$line:$column $error_message" so
you can append them to the filename for a standard looking error message.

=item C<options>

  $sass->options->{dont_die} = 1;

Allows you to inspect or change the options after a call to C<new>.

=back

=head1 FUNCTIONAL INTERFACE

=over 4

=item C<$css = sass_compile(source_code, options)>

=item C<($css, $err, $srcmap) = sass_compile(source_code, options)>

This compiles the Sass string that is passed in the first parameter. It
returns both the CSS and the error in list context and just the CSS in
scalar context. One of the returned values will always be C<undef>, but
never both.

=back

=head1 OPTIONS

=over 4

=item C<output_style>

=over 4

=item C<SASS_STYLE_NESTED>

=item C<SASS_STYLE_COMPRESSED>

=back

The default is C<SASS_STYLE_NESTED>. Set to C<SASS_STYLE_COMPRESSED> to
eliminate all whitespace (for your production CSS).

=item C<source_comments>

Set to C<true> to get extra comments in the output, indicating what input
line the code corresponds to.

=item C<source_map_file>

Setting this option enables the source map generating. The file will not
actually be created, but its content will be returned to the caller. It
will also enable sourceMappingUrl comment by default. See C<omit_src_map_url>.

=item C<omit_src_map_url>

Set to C<true> to omit the sourceMappingUrl comment from the output css.

=item C<include_paths>

This is an arrayref that holds the list a of paths to search (in addition to
the current directory) when following Sass C<@import> directives.

=item C<image_path>

This is a string that holds the base URL. This is only used in the
(non-standard) C<image-url()> Sass function. For example, if C<image_path>
is set to C<'file:///tmp/a/b/c'>, then the follwoing Sass code:

  .something { background-image: image-url("my/path"); }

...will compile to this:

  .something { background-image: url("file:///tmp/a/b/c/my/path"); }

=item C<dont_die>

This is only valid when used with the L<Object Oriented Interface|/"OBJECT ORIENTED INTERFACE">. It is
described in detail there.

=item C<sass_functions>

This is a hash of Sass functions implemented in Perl. The key for each
function should be the function's Sass signature and the value should be a
Perl subroutine reference. This subroutine will be called whenever the
function is used in the Sass being compiled. The arguments to the subroutine
are L<CSS::Sass::Type> objects and the return value I<must> also be one of
those types. It may also return C<undef> which is just a shortcut for
CSS::Sass::Type::String->new('').

The function is called with an C<eval> statement so you may use "die" to
throw errors back to libsass.

A simple example:

    sass_functions => {
        'append_hello($str)' => sub {
            my ($str) = @_;
            die '$str should be a string' unless $str->isa("CSS::Sass::Type::String");
            return CSS::Sass::Type::String->new($str->value . " hello");
        }
    }

If this is encountered in the Sass:

    some_rule: append_hello("Well,");

Then the ouput would be:

    some_rule: Well, hello;

=back

=head1 MISCELLANEOUS

=item C<SASS2SCSS_PRETTIFY_0>

Write everything on one line (minimized)

=item C<SASS2SCSS_PRETTIFY_1>

Add lf after opening bracket (lisp style)

=item C<SASS2SCSS_PRETTIFY_2>

Add lf after opening and before closing bracket (1TBS style)

=item C<SASS2SCSS_PRETTIFY_3>

Add lf before/after opening and before closing (allman style)

=item C<SASS2SCSS_KEEP_COMMENT>

Keep multi-line source code comments.
Single-line comments are removed by default.

=item C<SASS2SCSS_STRIP_COMMENT>

Strip all source code (single- and multi-line) comments.

=item C<SASS2SCSS_CONVERT_COMMENT>

Convert single-line comments to mutli-line comments.

=item C<sass2scss>

We expose the C<sass2scss> function, which can be used to convert indented sass
syntax to the newer scss syntax. You may need this, since C<libsass> will not
automatically recognize the format of your string data.

    my $options = SASS2SCSS_PRETTIFY_1;
    $options |= SASS2SCSS_CONVERT_COMMENT;
    my $scss = sass2scss($sass, $options);

=back

=head1 SEE ALSO

L<CSS::Sass::Type>

L<The Sass Home Page|http://sass-lang.com/>

L<The libsass Home Page|https://github.com/sass/libsass>

L<The CSS::Sass Home Page|https://github.com/sass/perl-libsass>

=head1 AUTHOR

David Caldwell E<lt>david@porkrind.orgE<gt>
Marcel Greter E<lt>perl-libsass@ocbnet.chE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by David Caldwell
Copyright (C) 2014 by Marcel Greter

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
