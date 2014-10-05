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

# convenient file handling
use File::Slurp qw(write_file);

# load constants from libsass
use CSS::Sass qw(SASS_STYLE_NESTED);

####################################################################################################
# config variables
####################################################################################################

# init options
my $comments = 0;
my $precision = 0;
my $source_map_file;
my $omit_src_map_url = 0;

# make this configurable
my $style = SASS_STYLE_NESTED;

# define a sub to print out the version (mimic behaviour of node.js blessc)
# this script has it's own version numbering as it's not dependent on any libs
sub version { print "psass 0.1.0 (perl sass (scss) compiler)"; exit 0; };

# get options
GetOptions (
	'help|h' => sub { pod2usage(1); },
	'version|v' => \ &version,
	'comments|c!' => \ $comments,
	'precision|p=s' => \ $precision,
	'source_map|s=s' => \ $source_map_file,
	'omit_source_map!' => \ $omit_src_map_url,
);

####################################################################################################
use CSS::Sass qw(sass_compile_file sass_compile);
####################################################################################################

# variables
my ($css, $err, $smap);

# open filehandle if path is given
if (defined $ARGV[0] && $ARGV[0] ne '-')
{
	($css, $err, $smap) = sass_compile_file(
		$ARGV[0],
		precision => $precision,
		output_style  => $style,
		source_comments => $comments,
		source_map_file => $source_map_file,
		omit_source_map_url => $omit_src_map_url
	);
}
# or use standard input
else
{
	($css, $err, $smap) = sass_compile(
		join('', <STDIN>),
		precision => $precision,
		output_style  => $style,
		source_comments => $comments,
		source_map_file => $source_map_file,
		omit_source_map_url => $omit_src_map_url
	);
}

# process return status values
if (defined $css) { print $css; }
elsif (defined $err) { die $err; }
else { die "fatal error - aborting"; }

# output source map
if ($source_map_file)
{
	unless ($smap) { warn "source map not generated <$source_map_file>" }
	else { write_file($source_map_file, {binmode => ':utf8'}, $smap ); }
}

####################################################################################################
####################################################################################################

__END__

=head1 NAME

psass - perl sass (scss) compiler

=head1 SYNOPSIS

sass [options] [ source | - ]

 Options:
   -v, --version                 print version
   -h, --help                    print this help
   -p, --precision               precision for float output
   -c, --comments                enable source debug comments
   -s, --source_map=file         create and write source map to file
       --omit_source_map_url     disable adding source map url comment

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message with options and exits.

=back

=head1 DESCRIPTION

B<This program> is a sass (scss) compiler

=cut
