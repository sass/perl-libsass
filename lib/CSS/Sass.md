# NAME

CSS::Sass - Compile .scss files using libsass

# SYNOPSIS

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

# DESCRIPTION

CSS::Sass provides a perl interface to libsass, a fairly complete Sass
compiler written in C++. It is currently somewhere around ruby sass 3.2
feature parity. It can compile .scss and .sass files.

# OBJECT ORIENTED INTERFACE

- `new`

        $sass = CSS::Sass->new(options)

    Creates a Sass object with the specified options. Example:

        $sass = CSS::Sass->new; # no options
        $sass = CSS::Sass->new(output_style => SASS_STYLE_NESTED);

- `compile(source_code)`

        $css = $sass->compile("A { color: blue; }");

    This compiles the Sass string that is passed in as the first parameter. It
    will `croak()` if there is an error, unless the `dont_die` option is set.
    It will return `undef` in that case.

- `last_error`

        $sass->last_error

    Returns the error encountered by the most recent invocation of
    `compile`. This is only useful if the `dont_die` option is set.

    `libsass` error messages are in the form ":$line:$column $error\_message" so
    you can append them to the filename for a standard looking error message.

- `options`

        $sass->options->{dont_die} = 1;

    Allows you to inspect or change the options after a call to `new`.

# FUNCTIONAL INTERFACE

- `$css = sass_compile(source_code, options)`
- `($css, $err, $srcmap) = sass_compile(source_code, options)`

    This compiles the Sass string that is passed in the first parameter. It
    returns both the CSS and the error in list context and just the CSS in
    scalar context. One of the returned values will always be `undef`, but
    never both.

# OPTIONS

- `output_style`

    - `SASS_STYLE_NESTED`
    - `SASS_STYLE_COMPRESSED`

    The default is `SASS_STYLE_NESTED`. Set to `SASS_STYLE_COMPRESSED` to
    eliminate all whitespace (for your production CSS).

- `source_comments`

    Set to `true` to get extra comments in the output, indicating what input
    line the code corresponds to.

- `source_map_file`

    Setting this option enables the source map generating. The file will not
    actually be created, but its content will be returned to the caller. It
    will also enable sourceMappingUrl comment by default. See `omit_src_map_url`.

- `omit_src_map_url`

    Set to `true` to omit the sourceMappingUrl comment from the output css.

- `include_paths`

    This is an arrayref that holds the list a of paths to search (in addition to
    the current directory) when following Sass `@import` directives.

- `image_path`

    This is a string that holds the base URL. This is only used in the
    (non-standard) `image-url()` Sass function. For example, if `image_path`
    is set to `'file:///tmp/a/b/c'`, then the follwoing Sass code:

        .something { background-image: image-url("my/path"); }

    ...will compile to this:

        .something { background-image: url("file:///tmp/a/b/c/my/path"); }

- `dont_die`

    This is only valid when used with the [Object Oriented Interface](#object-oriented-interface). It is
    described in detail there.

- `sass_functions`

    This is a hash of Sass functions implemented in Perl. The key for each
    function should be the function's Sass signature and the value should be a
    Perl subroutine reference. This subroutine will be called whenever the
    function is used in the Sass being compiled. The arguments to the subroutine
    are [CSS::Sass::Type](https://metacpan.org/pod/CSS::Sass::Type) objects and the return value _must_ also be one of
    those types. It may also return `undef` which is just a shortcut for
    CSS::Sass::Type::String->new('').

    The function is called with an `eval` statement so you may use "die" to
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

# MISCELLANEOUS

- `SASS2SCSS_PRETTIFY_0`

	Write everything on one line (minimized)

- `SASS2SCSS_PRETTIFY_1`

	Add lf after opening bracket (lisp style)

- `SASS2SCSS_PRETTIFY_2`

	Add lf after opening and before closing bracket (1TBS style)

- `SASS2SCSS_PRETTIFY_3`

	Add lf before/after opening and before closing (allman style)

- `SASS2SCSS_KEEP_COMMENT`

	Keep multi-line source code comments.
	Single-line comments are removed by default.

- `SASS2SCSS_STRIP_COMMENT`

	Strip all source code (single- and multi-line) comments.

- `SASS2SCSS_CONVERT_COMMENT`

	Convert single-line comments to mutli-line comments.

- `sass2scss`

    We expose the `sass2scss` function, which can be used to convert indented sass
    syntax to the newer scss syntax. You may need this, since `libsass` will not
    automatically recognize the format of your string data.

        my $options = SASS2SCSS_PRETTIFY_1;
        $options |= SASS2SCSS_CONVERT_COMMENT;
        my $scss = sass2scss($sass, $options);

# SEE ALSO

[CSS::Sass::Type](https://metacpan.org/pod/CSS::Sass::Type)

[The Sass Home Page](http://sass-lang.com/)

[The libsass Home Page](https://github.com/sass/libsass)

[The CSS::Sass Home Page](https://github.com/sass/perl-libsass)

# AUTHOR

David Caldwell <david@porkrind.org>  
Marcel Greter <perl-libsass@ocbnet.ch>

# COPYRIGHT AND LICENSE

Copyright (C) 2013 by David Caldwell  
Copyright (C) 2014 by Marcel Greter

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.

# POD ERRORS

Hey! **The above document had some coding errors, which are explained below:**

- Around line 217:

    '=item' outside of any '=over'
