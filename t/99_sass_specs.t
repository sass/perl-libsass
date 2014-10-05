# -*- perl -*-

use strict;
use warnings;

my (@dirs, @tests, @todos);

BEGIN
{

	our $todo = 0;
	my $skip_todo = 1;

	@dirs = ('t/sass-spec/spec');

	while (my $dir = shift(@dirs))
	{
		opendir(my $dh, $dir) or die "error opening specs dir $dir";
		while (my $ent = readdir($dh))
		{
			local $todo = $todo;
			next if $ent eq ".";
			next if $ent eq "..";
			$todo = $todo || $ent eq "todo" ||
				$ent eq "libsass-todo-tests" ||
				$ent eq "libsass-todo-issues";
			my $path = join("/", $dir, $ent);
			next if($skip_todo && $todo);
			push @dirs, $path if -d $path;
			if ($ent =~ m/^input\./)
			{
				push @tests, [$dir, $ent];
			}
		}
		closedir($dh);
	}

	# warn join(", ", map { $_->[0] } @tests), "\n";

}

use Test::More tests => scalar @tests;

use CSS::Sass;

sub read_file
{
  local $/ = undef;
  open my $fh, "<:raw", $_[0] or die "Couldn't open file: $!";
  binmode $fh; return <$fh>;
}

my $sass;
my ($r, $err);
my ($src, $expect);
my $ignore_whitespace = 1;

my @false_negatives;

foreach my $test (@tests)
{
	my $input_file = join("/", @{$test});
	my $expected_file = join("/", $test->[0], 'expected_output.css');

	die "no expected file" unless defined $expected_file;

	if ($input_file =~ m/todo/)
	{
		$sass = CSS::Sass->new(include_paths => ['t/inc'], output_style => SASS_STYLE_NESTED);
		$r = eval { $sass->compile_file($input_file) };
		$err = $@;
		$expect = read_file($expected_file);
		$expect =~ s/[\r\n]+/\n/g if $ignore_whitespace;
		$expect =~ s/[\s]+//g if $ignore_whitespace;
		chomp($expect) if $ignore_whitespace;
		if (defined $r)
		{
			$r =~ s/[\r\n]+/\n/g if $ignore_whitespace;
			$r =~ s/[\s]+//g if $ignore_whitespace;
			chomp($r) if $ignore_whitespace;
		}

		my $is_expected = defined $r && $r eq $expect && !$err ? 1 : 0;
		is    ($is_expected, 0,   "sass todo text unexpectedly passed: " . $input_file);
		push @false_negatives, $input_file if $is_expected;

	}
	else
	{
		$sass = CSS::Sass->new(include_paths => ['t/inc'], output_style => SASS_STYLE_NESTED);
		$r = eval { $sass->compile_file($input_file) };
		$err = $@; warn $@ if $@;
		$expect = read_file($expected_file);
		$expect =~ s/[\r\n]+/\n/g if $ignore_whitespace;
		$expect =~ s/[\s]+//g if $ignore_whitespace;
		chomp($expect) if $ignore_whitespace;
		if (defined $r)
		{
			$r =~ s/[\r\n]+/\n/g if $ignore_whitespace;
			$r =~ s/[\s]+//g if $ignore_whitespace;
			chomp($r) if $ignore_whitespace;
		}

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