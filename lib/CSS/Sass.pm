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

package CSS::Sass;

use strict;
use warnings;
use Carp;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw(
	quote
	unquote
	auto_quote
	need_quotes
	resolve_file
	sass2scss
	import_sv
	sass_compile
	sass_compile_file
	libsass_version
	sass2scss_version
	sass_operation
	sass_stringify
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
	SASS_STYLE_EXPANDED
	SASS_STYLE_COMPACT
	SASS_STYLE_COMPRESSED
	SASS2SCSS_PRETTIFY_0
	SASS2SCSS_PRETTIFY_1
	SASS2SCSS_PRETTIFY_2
	SASS2SCSS_PRETTIFY_3
	SASS2SCSS_KEEP_COMMENT
	SASS2SCSS_STRIP_COMMENT
	SASS2SCSS_CONVERT_COMMENT
);

our $VERSION = "3.4.8";

require XSLoader;
XSLoader::load('CSS::Sass', $VERSION);
require CSS::Sass::Value;

sub new
{
    my ($class, %options) = @_;
    # Ensure initial sub structures on options
    $options{plugin_paths} = [] unless exists $options{plugin_paths};
    $options{include_paths} = [] unless exists $options{include_paths};
    $options{sass_functions} = {} unless exists $options{sass_functions};
    # Create and return new object with options
    bless { options => \%options }, $class;
};

sub options
{
    shift->{options}
}

sub last_error
{
    my ($self) = @_;
    $self->{last_error}
}

my @path_types = (
  'plugin_paths',
  'include_paths'
);

# directory delimiter according to platform
my $dir_delim = $^O eq 'MSWin32' ? ';' : ':';

# normalize option hash
my $normalize_options = sub
{
    my ($options) = @_;
    # gather all functions
    # they need to be hashes
    my %functions =
    (
      %{$options->{'functions'} || {}},
      %{$options->{'sass_functions'} || {}}
    );
    # create functions array
    # help the c code a little
    my @functions = map { [
      $_, $functions{$_}
    ] } keys %functions;
    # gather all importers
    # they need to be arrays
    my @importers =
    map {
      ref($_) eq "ARRAY" ?
        $_ : [ $_, 0 ];
    }
    grep { defined }
    (
      $options->{'importer'},
      @{$options->{'importers'} || []},
      @{$options->{'sass_importers'} || []}
    );
    # gather all paths strings
    foreach my $type (@path_types)
    {
      $options->{$type} = join $dir_delim,
        map { split $dir_delim, $_ }
        @{$options->{$type} || []};
    }
    # now normalize the original hash
    $options->{'functions'} = \@functions;
    $options->{'importers'} = \@importers;
    # remove importer from options
    # it is now included in importers
    delete $options->{'importer'};
    # return pointer
    return $options;
};

sub sass_compile
{
    my ($sass_code, %options) = @_;
    no warnings 'uninitialized';
    $normalize_options->(\%options);
    my $r = compile_sass($sass_code, \%options);
    # decode the streams (maybe move directly to XS code)
    #utf8::decode($r->{output_string}) if defined $r->{output_string};
    #utf8::decode($r->{output_string}) if defined $r->{output_string};
    #utf8::decode($r->{error_message}) if defined $r->{error_message};
    wantarray ? ($r->{output_string}, $r->{error_message}, $r) : $r->{output_string}
}

sub sass_compile_file
{
    my ($input_path, %options) = @_;
    no warnings 'uninitialized';
    $normalize_options->(\%options);
    my $r = compile_sass_file($input_path, \%options);
    # decode the streams (maybe move directly to XS code)
    #utf8::decode($r->{output_string}) if defined $r->{output_string};
    #utf8::decode($r->{error_message}) if defined $r->{error_message};
    wantarray ? ($r->{output_string}, $r->{error_message}, $r) : $r->{output_string}
}

sub compile
{
    my ($self, $sass_code) = @_;
    my ($compiled, $stats);
    ($compiled, $self->{last_error}, $stats) = sass_compile($sass_code, %{$self->options});
    croak $self->{last_error} if $self->{last_error} && !$self->options->{dont_die};
    wantarray ? ($compiled, $stats) : $compiled
}

sub compile_file
{
    my ($self, $sass_file) = @_;
    my ($compiled, $stats);
    ($compiled, $self->{last_error}, $stats) = sass_compile_file($sass_file, %{$self->options});
    croak $self->{last_error} if $self->{last_error} && !$self->options->{dont_die};
    wantarray ? ($compiled, $stats) : $compiled
}

1;
__END__

=head1 NAME - perl bindings for libsass

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
  sub foobar { CSS::Sass::Value::String->new('blue') }
  $sass->options->{sass_functions}->{'foobar'} = \ &foobar;

  # Compile string and get css output and source-map json
  $sass->options->{source_map_file} = 'output.css.map';
  ($css, $stats) = $sass->compile('A { color: foobar(); }');


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
  my ($css, $stats) = $sass->compile('A { color: foobar(red); }');

  # Result can be undef because 'dont_die' was set
  warn $sass->last_error unless (defined $css);


  # Functional API
  use CSS::Sass qw(:Default sass_compile);

  # Functional API, with error messages and source-map
  my ($css, $err, $stats) = sass_compile('A { color: red; }');
  die $err if defined $err;

  # Functional API, simple, with no error messages
  my $css = sass_compile('A { color: red; }');
  die unless defined $css;

  # Functional API w/ options
  my ($css, $err, $stats) = sass_compile('A { color: red; }',
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

=head1 DESCRIPTION

CSS::Sass provides a perl interface to libsass, a fairly complete Sass
compiler written in C++. It is currently around ruby sass 3.3/3.4 feature parity and
heading towards full 3.4 compatibility. It can compile .scss and .sass files.

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

=item C<($css, $err, $stats) = sass_compile(source_code, options)>

Compiles the sass code given by C<source_code>. It returns CSS, error and a
status object in list context or just the CSS in scalar context. Either CSS
or error will be C<undef>, but never both.

=item C<$css = sass_compile_file(input_path, options)>

=item C<($css, $err, $stats) = sass_compile_file(input_path, options)>

Compiles the sass file given by C<input_path>. It returns CSS, error and a
status object in list context or just the CSS in scalar context. Either CSS
or error will be C<undef>, but never both.

=item $stats status hash:

The status hash holds usefull information after compilation:

=over

=item C<error_status>

=item C<output_string>

=item C<included_files>

=item C<source_map_string>

=item C<error_line>

=item C<error_column>

=item C<error_src>

=item C<error_file>

=item C<error_text>

=item C<error_message>

=item C<error_json>

=back

=back

=head1 OPTIONS

=over 4

=item C<output_style>

=over 4

=item C<SASS_STYLE_NESTED>

=item C<SASS_STYLE_COMPACT>

=item C<SASS_STYLE_EXPANDED>

=item C<SASS_STYLE_COMPRESSED>

=back

The default is C<SASS_STYLE_NESTED>. Set to C<SASS_STYLE_COMPRESSED> to
eliminate all whitespace (for your production CSS).

=item C<precision>

Set the floating point precision for output.

=item C<linefeed>

Set the linefeed string used for css output.

=item C<indent>

Set the indentation string used for css output.

=item C<source_comments>

Set to C<true> to get extra comments in the output, indicating what input
line the code corresponds to.

=item C<source_map_file>

Setting this option enables the source-map generating. The file will not
actually be created, but its content will be returned to the caller. It
will also enable sourceMappingURL comment by default. See C<no_src_map_url>.

=item C<source_map_file_urls>

Render source entries in the source map json as file urls (`file:///`).

=item C<source_map_root>

A path (string) that is directly embedded in the source map as C<sourceRoot>.

=item C<source_map_embed>

Embeds the complete source-map content into the sourceMappingURL, by using
base64 encoded data uri (sourceMappingURL=data:application/json;base64,XXXX)

=item C<source_map_contents>

Embeds the content of each source inside a C<sourcesContent> property in the
source-map json. Setting this option along with C<source_map_embed> allows
for a completely self-contained source-map.

=item C<no_src_map_url>

Set to C<true> to omit the sourceMappingURL comment from the output css.
Setting this options makes C<source_map_embed> useless.

=item C<include_paths>

This is an arrayref that holds the list a of paths to search (in addition to
the current directory) when following Sass C<@import> directives.

=item C<plugin_paths>

This is an arrayref that holds a list of paths to search for third-party
plugins. It will automatically load any <dll> or <so> library within that
directory. This is currently a highly experimental libsass feature!

=item C<dont_die>

This is only valid when used with the L<Object Oriented Interface|/"OBJECT ORIENTED INTERFACE">. It is
described in detail there.

=item C<sass_functions>

This is a hash of Sass functions implemented in Perl. The key for each
function should be the function's Sass signature and the value should be a
Perl subroutine reference. This subroutine will be called whenever the
function is used in the Sass being compiled. The arguments to the subroutine
are L<CSS::Sass::Value> objects, which map to native perl types if possible.
You can return either L<CSS::Sass::Value> objects or supported native perl data
structures. C<undef> is an equivalent of CSS::Sass::Value::Null->new.

The function is called with an C<eval> statement so you may use "die" to
throw errors back to libsass (C<CSS::Sass::Value::Error>).

A simple example:

    sass_functions => {
        'append_hello($str)' => sub {
            my ($str) = @_;
            die '$str should be a string' unless $str->isa("CSS::Sass::Value::String");
            return CSS::Sass::Value::String->new($str->value . " hello");
            # equivalent to return $str->value . " hello";
        }
    }

If this is encountered in the Sass:

    some_rule: append_hello("Well,");

Then the ouput would be:

    some_rule: Well, hello;

=item Custom C<importer>

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

You may also return C<undef> to skip the importer (usefull if an importer only handles
certain url protocols). With the latest libsass version, you can add multiple importers
with a priority order to implement more complex scenarios (highly experimental).

=item Custom C<headers>

Another highly experimental feature to prepend content on every compilation. It can be
used to predefine mixins or other stuff. Internally the content is really just added to
the top of the processed data. Custom headers have the same structure as importers. But
all registered headers are called in the order given by the priority flag.

=item C<Sass_Value> Types

Sass knowns various C<Sass_Value> types. We export the constants for completeness.
Each type is mapped to a package inside the C<CSS::Sass::Value> namespace.

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

    undef; # same as CSS::Sass::Value::Null->new;
    42; # same as CSS::Sass::Value::Number->new(42);
    "foobar"; # same as CSS::Sass::Value::String->new("foobar");
    [ 'foo', 'bar' ]; # same as CSS::Sass::Value::List->new('foo', 'bar');
    { key => 'value' }; # same as CSS::Sass::Value::Map->new(key => 'value');

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

L<CSS::Sass::Value>

L<The Sass Home Page|http://sass-lang.com/>

L<The libsass Home Page|https://github.com/sass/libsass>

L<The CSS::Sass Home Page|https://github.com/sass/perl-libsass>

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
