#!/usr/bin/perl
####################################################################################################
# sass (scss) compiler
####################################################################################################

use strict;
use warnings;

####################################################################################################
# dependencies
####################################################################################################

# parse options
use Pod::Usage;
use Getopt::Long;

####################################################################################################
# config variables
####################################################################################################

# init options
my $comments = 0;
my $precision = 0;

# define a sub to print out the version (mimic behaviour of node.js blessc)
# this script has it's own version numbering as it's not dependent on any libs
sub version { print "psass 0.1.0 (perl sass (scss) compiler)"; exit 0; };

# get options
GetOptions (
	'help|h' => sub { pod2usage(1); },
	'version|v' => \ &version,
	'comments|c!' => \ $comments,
	'precision|p=s' => \ $precision,
);

####################################################################################################
use CSS::Sass qw(SASS_STYLE_NESTED sass_compile_file sass_compile);
####################################################################################################

# variables
my ($css, $err);

# open filehandle if path is given
if (defined $ARGV[0] && $ARGV[0] ne '-')
{
	($css, $err) = sass_compile_file(
		$ARGV[0],
		precision => $precision,
		source_comments => $comments
	);
}
# or use standard input
else
{
	($css, $err) = sass_compile(
		join('', <STDIN>),
		precision => $precision,
		source_comments => $comments
	);
}

# process return status values
if (defined $css) { print $css; }
elsif (defined $err) { die $err; }
else { die "fatal error - aborting"; }

####################################################################################################
####################################################################################################

__END__

=head1 NAME

psass - perl sass (scss) compiler

=head1 SYNOPSIS

sass [options] [ source | - ]

 Options:
   -v, --version      print version
   -h, --help         print this help
   -p, --precision    set float precision
   -c, --comments     enable source comments

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message with options and exits.

=back

=head1 DESCRIPTION

B<This program> is a sass (scss) compiler

=cut
