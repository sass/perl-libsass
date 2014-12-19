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
use CSS::Sass qw(SASS_STYLE_COMPRESSED);

####################################################################################################
# config variables
####################################################################################################

# init options
my $precision;
my $output_file;
my $output_style;
my $source_comments;
my $source_map_file;
my $source_map_embed;
my $source_map_contents;
my $omit_source_map_url;

# define a sub to print out the version (mimic behaviour of node.js blessc)
# this script has it's own version numbering as it's not dependent on any libs
sub version {
	printf "psass %s (perl sass/scss compiler)\n", "0.3.0";
	printf "  libsass: %s\n", CSS::Sass::libsass_version();
	printf "  sass2scss: %s\n", CSS::Sass::sass2scss_version();
exit 0 };

# include paths
my @include_paths;

# get options
GetOptions (
	'help|h' => sub { pod2usage(1); },
	'version|v' => \ &version,
	'precision|p=s' => \ $precision,
	'output-file|o=s' => \ $output_file,
	'output-style|t=s' => \ $output_style,
	'source-comments|c!' => \ $source_comments,
	'source-map-file|m=s' => \ $source_map_file,
	'source-map-embed|e!' => \ $source_map_embed,
	'source-map-contents|s!' => \ $source_map_contents,
	'no-source-map-url!' => \ $omit_source_map_url,
	'include-path|I=s' => sub { push @include_paths, $_[1] }
);

# set default if not configured
unless (defined $output_style)
{ $output_style = SASS_STYLE_NESTED }

# parse string to constant
elsif ($output_style =~ m/^n/i)
{ $output_style = SASS_STYLE_NESTED }
elsif ($output_style =~ m/^c/i)
{ $output_style = SASS_STYLE_COMPRESSED }
# die with message if style is unknown
else { die "unknown output style: $output_style" }


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
		output_path => $output_file,
		output_style  => $output_style,
		include_paths => \ @include_paths,
		source_comments => $source_comments,
		source_map_file => $source_map_file,
		source_map_embed => $source_map_embed,
		source_map_contents => $source_map_contents,
		omit_source_map_url => $omit_source_map_url
	);
}
# or use standard input
else
{
	($css, $err, $smap) = sass_compile(
		join('', <STDIN>),
		precision => $precision,
		output_path => $output_file,
		output_style  => $output_style,
		include_paths => \ @include_paths,
		source_comments => $source_comments,
		source_map_file => $source_map_file,
		source_map_embed => $source_map_embed,
		source_map_contents => $source_map_contents,
		omit_source_map_url => $omit_source_map_url
	);
}

# process return status values
if (defined $css)
{
	# by default we just print to standard out
	unless (defined $output_file) { print $css; }
	# or if output_file is defined via options we write it there
	else { write_file($output_file, { binmode => ':utf8' }, $css ); }
}
elsif (defined $err) { die $err; }
else { die "fatal error - aborting"; }

# output source-map
if ($source_map_file)
{
	unless ($smap) { warn "source-map not generated <$source_map_file>" }
	else { write_file($source_map_file, { binmode => ':utf8' }, $smap ); }
}

####################################################################################################
####################################################################################################

__END__

=head1 NAME

psass - perl sass (scss) compiler

=head1 SYNOPSIS

psass [options] [ source | - ]

 Options:
   -v, --version                 print version
   -h, --help                    print this help
   -p, --precision               precision for float output
   -o, --output-file=file        output file to write result to
   -t, --output-style=style      output style [nested|compressed]
   -I, --include-path=path       sass include path (repeatable)
   -c, --source-comments         enable source debug comments
   -e, --source-map-embed        embed source-map in mapping url
   -s, --source-map-contents     include original contents
   -m, --source-map-file=file    create and write source-map to file
       --no-source-map-url       omit sourceMappingUrl from output

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message with options and exits.

=back

=head1 DESCRIPTION

B<This program> is a sass (scss) compiler

=cut
