# -*- perl -*-

use strict;
use warnings;
use File::Basename;
use File::Spec::Functions;
use YAML::XS;

################################################################################
package DIR;
################################################################################

sub new
{
	my $pkg = $_[0];
	my $root = $_[1];
	my $parent = $_[2];
	my $opt = $_[3] || {};
	return bless {
		root => $root,
		parent => $parent,
		todo => $opt->{todo},
		clean => $opt->{clean},
		style => $opt->{style},
		prec => $opt->{prec},
		start => $opt->{start},
		end => $opt->{end},
	}, $pkg;
}

sub query
{
	# check if we found the option
	if (defined $_[0]->{$_[1]}) {
		return $_[0]->{$_[1]};
	}
	# otherwise dispatch to parent
	if (defined $_[0]->{parent}) {
		return $_[0]->{parent}->query($_[1]);
	}
	# or not found
	return undef;
}

################################################################################
package SPEC;
################################################################################

use CSS::Sass;
use Carp qw(croak);
use File::Spec::Functions;

# everything is normalized
my $norm_output = sub ($) {
	$_[0] =~ s/(?:\r?\n)+/\n/g;
	$_[0] =~ s/;(?:\s*;)+/;/g;
	$_[0] =~ s/;\s*}/}/g;
};

# only flagged stuff is cleaned
my $clean_output = sub ($) {
	$_[0] =~ s/[\r\n\s	 ]+/ /g;
	$_[0] =~ s/[\r\n\s	 ]+,/,/g;
	$_[0] =~ s/,[\r\n\s	 ]+/,/g;
};

sub new
{
	my $pkg = $_[0];
	my $root = $_[1];
	my $file = $_[2];
	return bless {
		root => $root,
		file => $file,
	}, $pkg;
}

sub stderr
{
	my ($spec) = @_;

	local $/ = undef;
	my $path = catfile($_[0]->{root}->{root}, "error");
	return undef unless -f $path;
	open my $fh, "<:raw:utf8", $path or
		croak "Error opening <", $path, ">: $!";
	binmode $fh; my $stderr = join "\n", <$fh>;
	$norm_output->($stderr);
	$stderr =~ s/\n.*\Z//s;
	return $stderr;

}
sub expected
{
	my ($spec) = @_;

	local $/ = undef;
	my $path = catfile($_[0]->{root}->{root}, "expected_output.css");
	open my $fh, "<:raw:utf8", $path or
		croak "Error opening <", $path, ">: $!";
	binmode $fh; return join "", <$fh>;

}

sub expect
{
	my $css = $_[0]->expected;
	return "" unless defined $css;
	utf8::decode($css);
	$norm_output->($css);
	if ($_[0]->query('clean')) {
		$clean_output->($css);
	}
	return $css;
}

sub result
{
	$_[0]->css || $_[0]->err;
}

sub css
{
	$_[0]->execute;
	my $css = $_[0]->{css};
	return "" unless defined $css;
	$norm_output->($css);
	if ($_[0]->query('clean')) {
		$clean_output->($css);
	}
	return $css;
}

sub err
{
	$_[0]->execute;
	my $err = $_[0]->{err};
	return $err unless defined $err;
	$norm_output->($err);
	$err =~ s/\n.*\Z//s;
	return $err;
}

sub execute
{

	my ($spec) = @_;

	# only execute each test once
	return if defined $spec->{css};
	return if defined $spec->{err};

	# warn $spec->{file};

	# CSS::Sass options
	my %options = (
		'precision',
		$spec->query('prec'),
		'output_style',
		$spec->style,
	);

	my $comp = CSS::Sass->new(%options);

	# save stderr
	no warnings 'once';
	open OLDFH, '>&STDERR';

	# redirect stderr to file
	open(STDERR, "+>", "specs.stderr.log"); select(STDERR); $| = 1;
	my $css = eval { $comp->compile_file($spec->{file}) }; my $err = $@;
	print STDERR "\n"; sysseek(STDERR, 0, 0); close(STDERR);

	# reset stderr
	open STDERR, '>&OLDFH';

	# store the results
	$spec->{css} = $css;
	$spec->{err} = $err;
	# return the results
	return $css, $err;

}

sub style
{
	my $style = $_[0]->query('style');
	return SASS_STYLE_EXPANDED unless defined $style;
	if ($style =~ m/compact/i) { return SASS_STYLE_COMPACT; }
	elsif ($style =~ m/nested/i) { return SASS_STYLE_NESTED; }
	elsif ($style =~ m/compres/i) { return SASS_STYLE_COMPRESSED; }
	# elsif ($style =~ m/expanded/i) { return SASS_STYLE_EXPANDED; }
	return SASS_STYLE_EXPANDED;
}

sub file { shift->{file}; }
sub query { shift->{root}->query(@_); }

################################################################################
package main;
################################################################################

use Carp qw(croak);

# ********************************************************************
sub read_file($)
{
	local $/ = undef;
	open my $fh, "<:raw:utf8", $_[0] or
		croak "Error opening <", $_[0], ">: $!";
	binmode $fh; return join "", <$fh>;
}

# ********************************************************************
sub load_tests()
{

	# result
	my @specs; my $filter = qr/huge|unicode\/report/;
	# initial spec test directory entry
	my $root = new DIR;
	$root->{start} = 0;
	$root->{end} = 999;
	$root->{prec} = 5;
	my @dirs = (['t/sass-spec/spec', $root]);
	# walk through all directories
	# no recursion for performance
	while (my $entry = shift(@dirs))
	{
		my ($dir, $parent) = @{$entry};
		my $test = new DIR($dir, $parent);
		if (-f catfile($dir, "options.yml")) {
			my $file = catfile($dir, "options.yml");
			my $yaml = YAML::XS::Load(read_file($file));
			$test->{clean} = $yaml->{':clean'};
			$test->{prec} = $yaml->{':precision'};
			$test->{style} = $yaml->{':output_style'};
			$test->{start} = $yaml->{':start_version'};
			$test->{end} = $yaml->{':end_version'};
			$test->{ignore} = grep /^libsass$/i,
				@{$yaml->{':ignore_for'} ||  []};
			$test->{todo} = grep /^libsass$/i,
				@{$yaml->{':todo'} ||  []};
		}

		$test->{clean} = $parent->{clean} unless $test->{clean};
		$test->{prec} = $parent->{prec} unless $test->{prec};
		$test->{style} = $parent->{style} unless $test->{style};
		$test->{start} = $parent->{start} unless $test->{start};
		$test->{end} = $parent->{end} unless $test->{end};
		$test->{ignore} = $parent->{ignore} unless $test->{ignore};
		$test->{todo} = $parent->{todo} unless $test->{todo};

		my $sass = catfile($dir, "input.sass");
		my $scss = catfile($dir, "input.scss");
		# have spec test
		if (-e $scss) {
			if (!$filter || !($scss =~ m/$filter/)) {
				push @specs, new SPEC($test, $scss);
			}
		}
		elsif (-e $sass) {
			if (!$filter || !($sass =~ m/$filter/)) {
				push @specs, new SPEC($test, $sass);
			}
		}

		opendir(my $dh, $dir) or die $!;
		while (my $ent = readdir($dh))
		{
			next if $ent eq ".";
			next if $ent eq "..";
			next if $ent =~ m/^\./;
			# create combined path
			my $path = catfile($dir, $ent);
			# go into subfolders
			if (-d $path) {
				push @dirs, [$path, $test];
			}
		}
		# close anyway
		closedir($dh);
	}
	# unfiltered
	return @specs;
}

use vars qw(@specs);
# specs must be loaded first
# before registering tests
BEGIN { @specs = grep {
	! $_->query('todo') &&
	! $_->query('ignore') &&
	$_->query('start') <= 3.4
} load_tests }

use Test::More tests => scalar @specs;
use Test::Differences;

# run tests after filtering
foreach my $spec (@specs)
{
	# compare the result with expected data
	if ($spec->err) {
	  eq_or_diff ($spec->err, $spec->stderr, $spec->file)
	} elsif ($spec->expect) {
	  eq_or_diff ($spec->result, $spec->expect, $spec->file)
	} else {
	  eq_or_diff ($spec->result, $spec->result, $spec->file)
	}
}
