#!/usr/bin/perl
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
		wtodo => $opt->{wtodo},
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
use Cwd qw(getcwd);
use Carp qw(croak);
use File::Spec::Functions;

my $cwd = getcwd;
my $cwd_win = $cwd;
my $cwd_nix = $cwd;
$cwd_win =~ s/[\/\\]/\\/g;
$cwd_nix =~ s/[\/\\]/\//g;

# everything is normalized
my $norm_output = sub ($) {
	$_[0] =~ s/(?:\r?\n)+/\n/g;
	$_[0] =~ s/;(?:\s*;)+/;/g;
	$_[0] =~ s/;\s*}/}/g;
	# normalize debug entries
	$_[0] =~ s/[^\n]+(\d+) DEBUG: /$1: DEBUG: /g;
	# normalize directory entries
	$_[0] =~ s/\/libsass-todo-issues\//\/libsass-issues\//g;
	$_[0] =~ s/\/libsass-closed-issues\//\/libsass-issues\//g;
	$_[0] =~ s/\Q$cwd_win\E[\/\\]t[\/\\]sass-spec[\/\\]/\/sass\//g;
	$_[0] =~ s/\Q$cwd_nix\E[\/\\]t[\/\\]sass-spec[\/\\]/\/sass\//g;
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
	my $test = $_[3];
	return bless {
		root => $root,
		file => $file,
		test => $test,
	}, $pkg;
}

sub errors
{
	my ($spec) = @_;

	local $/ = undef;
	return -f catfile($spec->{root}->{root}, "status");
}

sub stderr
{
	my ($spec) = @_;

	local $/ = undef;
	my $path = catfile($spec->{root}->{root}, "error");
	return "" unless -f $path;
	open my $fh, "<:raw:utf8", $path or
		croak "Error opening <", $path, ">: $!";
	binmode $fh; my $stderr = join "\n", <$fh>;
	# fully remove debug messaged from error
	$stderr =~ s/[^\n]+(\d+) DEBUG: [^\n]*//g;
	$norm_output->($stderr);
	# clean todo warnings (remove all warning blocks)
	$stderr =~ s/^(?:DEPRECATION )?WARNING(?:[^\n]+\n)*\n*//gm;
	$stderr =~ s/\n.*\Z//s;
	return $stderr;
}

sub stdmsg
{
	my ($spec) = @_;

	local $/ = undef;
	my $path = catfile($spec->{root}->{root}, "error");
	return '' unless -f $path;
	open my $fh, "<:raw:utf8", $path or
		croak "Error opening <", $path, ">: $!";
	binmode $fh; my $stderr = join "\n", <$fh>;
	$norm_output->($stderr);
	if ($spec->{test}->{wtodo}) {
		# clean todo warnings (remove all warning blocks)
		$stderr =~ s/^(?:DEPRECATION )?WARNING(?:[^\n]+\n)*\n*//gm;
	}
	# clean error messages
	$stderr =~ s/^Error(?:[^\n]+\n)*\n*//gm;
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
	return "" unless defined $err;
	$norm_output->($err);
	$err =~ s/\n.*\Z//s;
	return $err;
}

sub msg
{
	$_[0]->execute;
	my $msg = $_[0]->{msg};
	return "" unless defined $msg;
	$norm_output->($msg);
	$msg =~ s/\n.*\Z//s;
	return $msg;
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
	open(STDERR, "+>:raw:utf8", "specs.stderr.log"); select(STDERR); $| = 1;
	my $css = eval { $comp->compile_file($spec->{file}) }; my $err = $@;
	sysseek(STDERR, 0, 0); sysread(STDERR, my $msg, 65536); close(STDERR);

	# reset stderr
	open STDERR, '>&OLDFH';

	# store the results
	$spec->{css} = $css;
	$spec->{err} = $err;
	$spec->{msg} = $msg;

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
	my @specs; my $ignore = qr/huge|unicode\/report/;
	my $filter = qr/\Q$ARGV[0]\E/ if defined $ARGV[0];
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
				@{$yaml->{':ignore_for'} || []};
			$test->{wtodo} = grep /^libsass$/i,
				@{$yaml->{':warning_todo'} || []};
			$test->{todo} = grep /^libsass$/i,
				@{$yaml->{':todo'} || []};
		}

		$test->{clean} = $parent->{clean} unless $test->{clean};
		$test->{prec} = $parent->{prec} unless $test->{prec};
		$test->{style} = $parent->{style} unless $test->{style};
		$test->{start} = $parent->{start} unless $test->{start};
		$test->{end} = $parent->{end} unless $test->{end};
		$test->{ignore} = $parent->{ignore} unless $test->{ignore};
		$test->{wtodo} = $parent->{wtodo} unless $test->{wtodo};
		$test->{todo} = $parent->{todo} unless $test->{todo};

		my $sass = catfile($dir, "input.sass");
		my $scss = catfile($dir, "input.scss");
		# have spec test
		if (-e $scss) {
			if (!$ignore || !($scss =~ m/$ignore/)) {
				if (!$filter || ($scss =~ m/$filter/)) {
					push @specs, new SPEC($test, $scss, $test);
				}
			}
		}
		elsif (-e $sass) {
			if (!$ignore || !($sass =~ m/$ignore/)) {
				if (!$filter || ($sass =~ m/$filter/)) {
					push @specs, new SPEC($test, $sass, $test);
				}
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

use vars qw(@tests @specs);
# specs must be loaded first
# before registering tests
BEGIN {
	@tests = load_tests;
	@specs = grep {
		! $_->query('todo') &&
		! $_->query('ignore') &&
		$_->query('start') <= 3.4
	} @tests;
}

# report todo tests
# die join("\n", map {
# 	$_->{root}->{root}
# } grep {
# 	$_->query('todo') &&
# 	! $_->query('ignore') &&
# 	$_->query('start') <= 3.4
# } @tests);

use Test::More tests => 3 * scalar @specs;
use Test::Differences;

# run tests after filtering
foreach my $spec (@specs)
{
	# compare the result with expected data
	eq_or_diff ($spec->css, $spec->expect, "CSS: " . $spec->file);
	eq_or_diff ($spec->err, $spec->stderr, "Errors: " . $spec->file);
	eq_or_diff ($spec->msg, $spec->stdmsg, "Warnings: " . $spec->file);
}
