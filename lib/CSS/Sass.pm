# Copyright © 2013 David Caldwell.
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
our @EXPORT_OK = qw( sass_compile );
our @EXPORT = qw(
	SASS_STYLE_NESTED
	SASS_STYLE_COMPRESSED
);

our $VERSION = '0.4.0'; # Always keep the rightmost digit, even if it's zero (stupid perl).

require XSLoader;
XSLoader::load('CSS::Sass', $VERSION);

sub new {
    my ($class, %options) = @_;
    bless { options=>\%options }, $class;
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
    my $r = compile_sass($sass_code, { %options,
                                       # Override include_paths with a ':' separated list
                                       !$options{include_paths} ? ()
                                                                : (include_paths => join(':', @{$options{include_paths}})),
                                     });
    wantarray ? ($r->{output_string}, $r->{error_message}) : $r->{output_string}
}

sub compile {
    my ($self, $sass_code) = @_;
    my $compiled;
    ($compiled, $self->{last_error}) = sass_compile($sass_code, %{$self->options});
    croak $self->{last_error} if $self->{last_error} && !$self->options->{dont_die};
    $compiled
}

1;
__END__

=head1 NAME

CSS::Sass - Compile .scss files using libsass

=head1 SYNOPSIS

  # Object Oriented API
  use CSS::Sass;

  my $sass = CSS::Sass->new;
  my $css = $sass->compile(".something { color: red; }");


  # Object Oriented API w/ options
  my $sass = CSS::Sass->new(include_paths   => ['some/include/path'],
                            image_path      => 'base_url',
                            output_style    => SASS_STYLE_COMPRESSED,
                            source_comments => 1,
                            dont_die        => 1);
  my $css = $sass->compile(".something { color: red; }");
  if (!defined $css) { # $css can be undef because 'dont_die' was set
    warn $sass->last_error;
  }



  # Functional API
  use CSS::Sass qw(:Default sass_compile);

  my ($css, $err) = sass_compile(".something { color: red; }");
  die $err if defined $err;


  # Functional API, simple, with no error messages
  my $css = sass_compile(".something { color: red; }");
  die unless defined $css;


  # Functional API w/ options
  my ($css, $err) = sass_compile(".something { color: red; }",
                                 include_paths => ['some/include/path'],
                                 image_path    => 'base_url',
                                 output_style  => SASS_STYLE_NESTED,
                                 source_comments => 1);


=head1 DESCRIPTION

CSS::Sass provides a perl interface to libsass, a fairly complete Sass
compiler written in C. Despite its name, CSS::Sass can only compile the
newer ".scss" files.

=head1 OBJECT ORIENTED INTERFACE

=over 4

=item C<new>

  $sass = CSS::Sass->new(options)

Creates a Sass object with the specified options. Example:

  $sass = CSS::Sass->new; # no options
  $sass = CSS::Sass->new(output_style => SASS_STYLE_NESTED);

=item C<compile(source_code)>

  $css = $sass->compile("source code");

This compiles the Sass string that is passed in the first parameter. If
there is an error it will C<croak()>, unless the C<dont_die> option has been
set. In that case, it will return C<undef>.

=item C<last_error>

  $sass->last_error

Returns the error encountered by the most recent invocation of
C<compile>. This is really only useful if the C<dont_die> option is set.

C<libsass> error messages are in the form ":$line:$column $error_message" so
you can append them to the filename for a standard looking error message.

=item C<options>

  $sass->options->{dont_die} = 1;

Allows you to inspect or change the options after a call to C<new>.

=back

=head1 FUNCTIONAL INTERFACE

=over 4

=item C<($css, $err) = sass_compile(source_code, options)>

=item C<$css = sass_compile(source_code, options)>

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

Set to C<0> (the default) and no extra comments are output. Set to C<1> and
comments are output indicating what input line the code corresponds to.

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

=back

=head1 SEE ALSO

L<The Sass Home Page|http://sass-lang.com/>

L<The libsass Home Page|https://github.com/hcatlin/libsass>

L<The CSS::Sass Home Page|https://github.com/caldwell/CSS-Sass>

=head1 AUTHOR

David Caldwell E<lt>david@porkrind.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by David Caldwell

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
