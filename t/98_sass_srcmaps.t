# -*- perl -*-

use strict;
use warnings;

my (@dirs, @tests);

BEGIN
{

	@dirs = ('t/sass-srcmap');
	while (my $dir = shift(@dirs))
	{
		opendir(my $dh, $dir) or
			die "error opening srcmap test dir $dir";
		while (my $ent = readdir($dh))
		{
			next if $ent eq ".";
			next if $ent eq "..";
			next if $ent =~ m/^\./;
			my $path = join("/", $dir, $ent);
			push @dirs, $path if -d $path;
			if ($ent =~ m/^input\./)
			{ push @tests, [$dir, $ent]; }
		}
		closedir($dh);
	}

}

use Test::More tests => 2 + scalar(@tests) * 2;

BEGIN { use_ok('CSS::Sass', qw(SASS_STYLE_NESTED)); }
use_ok('OCBNET::SourceMap');

sub read_file
{
	local $/ = undef;
	open my $fh, "<:raw", $_[0] or
		$_[1] || die "Error $_[0]: $!";
	binmode $fh; return <$fh>;
}

use File::chdir;

foreach my $test (@tests)
{

	local $CWD =$test->[0];

	my $input_file = $test->[1];
	my $config_file = 'config';
	my $expected_file = 'output.css';
	my $srcmap_file = 'output.css.map';

	die "no expected file" unless defined $expected_file;

	my $config = read_file($config_file, 0);
	my $expect = read_file($expected_file, 0);
	my $srcmap = read_file($srcmap_file, 0);

	my %options = (
		source_map_file => 'output.css.map',
		output_style => SASS_STYLE_NESTED
	);

	my $sass = CSS::Sass->new(%options);

	my ($r, $stats) = eval {
		$sass->compile_file($input_file)
	};

	my $smap_exp = new OCBNET::SourceMap::V3;
	$smap_exp->read(\$srcmap);

	my $smap_cur = new OCBNET::SourceMap::V3;
	$smap_cur->read(\$stats->{'source_map_string'});

	my $rows = $smap_exp->{'mappings'};

	my $tsrcmap = sub {
		my $i = 0; my $n = 0;
		foreach my $row (@{$rows}) {
			foreach my $exp (@{$row}) {
				# debug the current mapping
				# if (scalar(@{$exp}) == 5) {
				# 	printf STDERR "search ([%d,%d](\@%d)=>[%d,%d](\#%d))\n",
				# 		$exp->[2], $exp->[3], $exp->[1], $i, $exp->[0], $exp->[4];
				# } elsif (scalar(@{$exp}) == 4) {
				# 	printf STDERR "search ([%d,%d](\@%d)=>[%d,%d])\n",
				# 		$exp->[2], $exp->[3], $exp->[1], $i, $exp->[0];
				# } elsif (scalar(@{$exp}) == 1) {
				# 	printf STDERR "search ([%d,%d])\n", $i, $exp->[0];
				# } else {
				# 	die scalar(@{$exp});
				# }
				# try to find within current mappings
				my $cur = $smap_cur->{'mappings'}->[$i]->[$n]; ++$n;
				while ($cur && (join(":", @{$cur}) ne join(":", @{$exp}))) {
					$cur = $smap_cur->{'mappings'}->[$i]->[$n]; ++$n;
				}
				# check if we have found it
				unless ($cur) { return fail($test->[0] . "/" . $srcmap_file); }
			}
			++ $i;
			$n = 0;
		}
		pass ($test->[0] . "/" . $srcmap_file);
	};
	chomp($r); chomp($expect);

	$tsrcmap->();

	is ($r, $expect, "srcmap output " . $input_file);

}

__DATA__

# uncomment to debug a single test case
# @tests = grep { $_->[0] =~ m/199/ } @tests;


use CSS::Sass;


my $sass;
my ($r, $err);
my ($src, $expect);

# work directly on arg
# lib/sass_spec/test_case.rb
sub clean_output {
	$_[0] =~ s/\s+/ /g;
	$_[0] =~ s/[\s\t]*\{/ {\n/g;
	$_[0] =~ s/([;,])[\s\t]*\{/$1\n/g;
	$_[0] =~ s/[\s\t]*\}[\s\t]*/ }\n/g;
	$_[0] =~ s/[\s\t]+\Z//g;
	$_[0] =~ s/\A[\s\t]+//g;
	chomp($_[0]);
}

my @false_negatives;

foreach my $test (@tests)
{
	my $input_file = join("/", @{$test});
	my $expected_file = join("/", $test->[0], 'expected_output.css');

	die "no expected file" unless defined $expected_file;

	if ($redo_sass)
	{
		system "sass -C $input_file > $expected_file";
	}

	if ($input_file =~ m/todo/)
	{
		$sass = CSS::Sass->new(include_paths => ['t/inc'], output_style => SASS_STYLE_NESTED);
		$r = eval { $sass->compile_file($input_file) };
		$err = $@;
		clean_output($expect = read_file($expected_file));
		clean_output($r) if (defined $r);
		my $is_expected = defined $r && $r eq $expect && !$err ? 1 : 0;
		is    ($is_expected, 0,   "sass todo test unexpectedly passed: " . $input_file);
		push @false_negatives, $input_file if $is_expected;

	}
	else
	{
		my $last_error; my $on_error;
		$sass = CSS::Sass->new(include_paths => ['t/inc'], output_style => SASS_STYLE_NESTED, sass_functions => {
				'reset-error()' => sub { $last_error = undef; },
				'last-error()' => sub { return ${$last_error || \ undef}; },
				'mock-errors($on)' => sub { $on_error = $_[0]; return undef; },
				'@error' => sub {
				$last_error = $_[0]; return "thrown"; },
			}
		);
		$r = eval { $sass->compile_file($input_file) };
		$err = $@; warn $@ if $@;
		clean_output($expect = read_file($expected_file));
		clean_output($r) if (defined $r);
		is    ($r, $expect,       "sass-spec " . $input_file);

	}

}

__DATA__

require File::Basename;
require File::Spec::Functions;

# print git mv commands
warn join "\n", (map {
	$_ =~ s/\/+/\\/g;
	$_ =~ s /\\input\.[a-z]+$//;
	my $org = $_;
	my $root = File::Basename::dirname($org);
	$_ =~ s /\\libsass\-todo\-(?:tests|issues)//;
	sprintf("pushd \"%s\"\n", $root).
	sprintf("git mv %s %s\n",
		File::Spec->rel2abs($org, $root),
		File::Spec->abs2rel($_, $root)
	).
	sprintf("popd\n");
} @false_negatives), "\n";