# -*- perl -*-

use strict;
use warnings;

my (@dirs, @tests, @todos);

my $redo_sass = 0;

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
			next if $ent =~ m/^\./;
			next if $ent =~ m/input\.disabled\.scss$/;
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

# uncomment to debug a single test case
# @tests = grep { $_->[0] =~ m/199/ } @tests;

use Test::More tests => scalar @tests;
use Test::Differences;

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
		fail ("sass todo test unexpectedly passed: " . $input_file);
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
		eq_or_diff ($r, $expect,       "sass-spec " . $input_file);

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