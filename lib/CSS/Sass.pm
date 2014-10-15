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
	quote
	unquote
	sass2scss
	import_sv
	sass_compile
	sass_compile_file
	SASS_COMMA
	SASS_SPACE
	SASS_ERROR
	SASS_NULL
	SASS_BOOLEAN
	SASS_NUMBER
	SASS_STRING
	SASS_COLOR
	SASS_LIST
	SASS_MAP
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
    my $ret = eval { $cb->(@_) };
    use Data::Dumper;


    unless (UNIVERSAL::isa($ret, "CSS::Sass::Type")) {
        if (UNIVERSAL::isa($ret, "HASH")) {
            bless $ret, "CSS::Sass::Type::Map"
        } elsif (UNIVERSAL::isa($ret, "ARRAY")) {
            bless $ret, "CSS::Sass::Type::List"
        } elsif (UNIVERSAL::isa($ret, "REF")) {
        	die "got refg";
        }
    } else {
    	# we are a sass type, sweet
    	# warn "pass only by $ret";
    }

    # warn Dumper $ret;

    return CSS::Sass::Type::Error->new("$@") if $@;

#    return CSS::Sass::Type::Error->new("Perl Sass function returned something that wasn't a CSS::Sass::Type")
#        unless ref $ret && $ret->isa("CSS::Sass::Type");

    $ret;
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

  # Import quoting functions
  use CSS::Sass qw(quote unquote);

  # Exchange quoted strings
  my $string = unquote($from_sass);
  my $to_sass = quote($string, '"');

=head1 DESCRIPTION

CSS::Sass provides a perl interface to libsass, a fairly complete Sass
compiler written in C++.  It is currently somewhere around ruby sass 3.2/3.3
feature parity and heading towards 3.4. It can compile .scss and .sass files.

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

Compiles the given Sass source code. It returns CSS, error and source map in
list context or just the CSS in scalar context. Either CSS or error will be
C<undef>, but never both.

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
are L<CSS::Sass::Type> objects, which map to native perl types if possible.
You can return either L<CSS::Sass::Type> objects or supported native perl data
structures. C<undef> is an equivalent of CSS::Sass::Type::Null->new.

The function is called with an C<eval> statement so you may use "die" to
throw errors back to libsass (C<CSS::Sass::Type::Error>).

A simple example:

    sass_functions => {
        'append_hello($str)' => sub {
            my ($str) = @_;
            die '$str should be a string' unless $str->isa("CSS::Sass::Type::String");
            return CSS::Sass::Type::String->new($str->value . " hello");
            # equivalent to return $str->value . " hello";
        }
    }

If this is encountered in the Sass:

    some_rule: append_hello("Well,");

Then the ouput would be:

    some_rule: Well, hello;

=item C<Sass_Value> Types

Sass knowns various C<Sass_Value> types. We export the constants for completeness.
Each type is mapped to a package inside the C<CSS::Sass::Type> namespace.

    # Value types
    SASS_ERROR
    SASS_NULL
    SASS_BOOLEAN
    SASS_NUMBER
    SASS_STRING
    SASS_COLOR
    SASS_LIST
    SASS_MAP
    # List styles
    SASS_COMMA
    SASS_SPACE

=item Autodetection for value types returned by custom function

Many C<Sass_Value> types can be mapped directly to perl data structures.
C<maps> and C<lists> map directly to C<hashes> and C<arrays>. Scalars are
mapped to C<string>, C<number> or C<null>. You can directly return these
native data types from your custom functions or use the datastructures
to access maps and lists.

    undef; # same as CSS::Sass::Type::Null->new;
    42; # same as CSS::Sass::Type::Number->new(42);
    "foobar"; # same as CSS::Sass::Type::String->new("foobar");
    [ 'foo', 'bar' ]; # same as CSS::Sass::Type::List->new('foo', 'bar');
    { key => 'value' }; # same as CSS::Sass::Type::Map->new(key => 'value');

We bless native return values from custom functions into the correct package.

    # sub get-map { return { key: "value" } };
    .class { content: map-get(get-map(), key); }

    # sub get-list { return [ 'foo', 42, 'bar' ] };
    .class { content: nth(get-list(), 2); }



=back

=head1 MISCELLANEOUS

=over 4

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

=item C<sass2scss($sass, $options)>

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
