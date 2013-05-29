package Text::Sass::XS;

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

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Text::Sass::XS', $VERSION);

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
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Text::Sass::XS - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Text::Sass::XS;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Text::Sass::XS, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

David Caldwell, E<lt>david@apple.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by David Caldwell

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
