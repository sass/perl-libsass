# NAME - perl bindings for libsass

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

    # Compile string and get css output and source-map json
    $sass->options->{source_map_file} = 'output.css.map';
    ($css, $srcmap) = $sass->compile('A { color: foobar(); }');


    # Object Oriented API w/ options
    my $sass = CSS::Sass->new(plugin_paths    => ['plugins'],
                              include_paths   => ['some/include/path'],
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

    # Functional API, with error messages and source-map
    my ($css, $err, $srcmap) = sass_compile('A { color: red; }');
    die $err if defined $err;

    # Functional API, simple, with no error messages
    my $css = sass_compile('A { color: red; }');
    die unless defined $css;

    # Functional API w/ options
    my ($css, $err, $srcmap) = sass_compile('A { color: red; }',
                                            include_paths   => ['some/include/path'],
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

# DESCRIPTION

CSS::Sass provides a perl interface to libsass, a fairly complete Sass
compiler written in C++.  It is currently somewhere around ruby sass 3.2/3.3
feature parity and heading towards 3.4. It can compile .scss and .sass files.

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

    Compiles the given Sass source code. It returns CSS, error and source-map in
    list context or just the CSS in scalar context. Either CSS or error will be
    `undef`, but never both.

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

    Setting this option enables the source-map generating. The file will not
    actually be created, but its content will be returned to the caller. It
    will also enable sourceMappingURL comment by default. See `no_src_map_url`.

- `source_map_root`

    A path (string) that is directly embedded in the source map as `sourceRoot`.

- `source_map_embed`

    Embeds the complete source-map content into the sourceMappingURL, by using
    base64 encoded data uri (sourceMappingURL=data:application/json;base64,XXXX)

- `source_map_contents`

    Embeds the content of each source inside a `sourcesContent` property in the
    source-map json. Setting this option along with `source_map_embed` allows
    for a completely self-contained source-map.

- `no_src_map_url`

    Set to `true` to omit the sourceMappingURL comment from the output css.
    Setting this options makes `source_map_embed` useless.

- `include_paths`

    This is an arrayref that holds the list a of paths to search (in addition to
    the current directory) when following Sass `@import` directives.

- `plugin_paths`

    This is an arrayref that holds a list of paths to search for third-party
    plugins. It will automatically load any <dll> or <so> library within that
    directory. This is currently a highly experimental libsass feature!

- `dont_die`

    This is only valid when used with the [Object Oriented Interface](#object-oriented-interface). It is
    described in detail there.

- `sass_functions`

    This is a hash of Sass functions implemented in Perl. The key for each
    function should be the function's Sass signature and the value should be a
    Perl subroutine reference. This subroutine will be called whenever the
    function is used in the Sass being compiled. The arguments to the subroutine
    are [CSS::Sass::Type](https://metacpan.org/pod/CSS::Sass::Type) objects, which map to native perl types if possible.
    You can return either [CSS::Sass::Type](https://metacpan.org/pod/CSS::Sass::Type) objects or supported native perl data
    structures. `undef` is an equivalent of CSS::Sass::Type::Null->new.

    The function is called with an `eval` statement so you may use "die" to
    throw errors back to libsass (`CSS::Sass::Type::Error`).

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

- Custom `importer`

    This is a function implemented in Perl that gets called for every @import statement. This
    feature is in an experimental stage and you have to be careful to return the expected
    structure. You can return multiple imports from one call to make it possible to
    implement globbing importers etc. If you omit $data, libsass will try to load the
    given path itself. It will go through the normal lockup algorithm as it would had
    encountered the "virtual" import statement on its own. $scope holds the current
    import path. Imports in css are meant to be relative to the parent scope, so you
    can use it to create absolute urls or paths within the context your working with.

    A simple example:

        importer => sub {
          my ($import, $scope) = @_;
          return [
            # [ $real_path ] or [ $virtual_path, $data ],
            [ "http://xyz/file", "div { color: red; }" ],
          ];
        }

- `Sass_Value` Types

    Sass knowns various `Sass_Value` types. We export the constants for completeness.
    Each type is mapped to a package inside the `CSS::Sass::Type` namespace.

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

- Autodetection for value types returned by custom function

    Many `Sass_Value` types can be mapped directly to perl data structures.
    `maps` and `lists` map directly to `hashes` and `arrays`. Scalars are
    mapped to `string`, `number` or `null`. You can directly return these
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

- `sass2scss($sass, $options)`

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
