# -*- perl -*-

use strict;
use warnings;
use File::Basename;
use File::Spec::Functions;

my (@dirs, @tests, @todos);

my $die_first;
my $redo_sass;
my @surprises;

my $do_nested;
my $do_compact;
my $do_expanded;
my $do_compressed;
my $variants;

BEGIN {
	$redo_sass = 0;
	$do_nested = 1;
	$do_compact = 1;
	$do_expanded = 1;
	$do_compressed = 1;
	$variants = $do_nested
	          + $do_compact
	          + $do_expanded
	          + $do_compressed;
}

BEGIN
{

	our $todo = 0;
	$die_first = 0;
	my $skip_huge = 0;
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
			$todo = $todo || $ent =~ m/(?:todo_|_todo)/ ||
				$ent eq "libsass-todo-tests" ||
				$ent eq "libsass-todo-issues";
			my $path = join("/", $dir, $ent);
			next if $ent eq "huge" && $skip_huge;
			next if($todo && $skip_todo);
			push @dirs, $path if -d $path;
			if ($ent =~ m/^input\./)
			{
				next unless $redo_sass || -f catfile($dir, dirname($ent), "expected_output.css");
				push @tests, [$dir, $ent];
			}
		}
		closedir($dh);
	}

	# warn "found ", scalar(@tests), " spec tests\n";
	# warn join(", ", map { $_->[0] } @tests), "\n";

}

#foreach my $test (@tests) {
#  my $tst = $test->[0];
#  $tst =~ s/t\/+sass-spec\/+//;
#  warn "git mv",
#       " ", $tst, "/expected_output.css ",
#       " ", $tst, "/expected.nested.css ",
#  "\n";
#}
#exit(1);

# uncomment to debug a single test case
# @tests = grep { $_->[0] =~ m/199/ } @tests;

use Test::More tests => $variants * ($redo_sass ? 2 : 1) * scalar(@tests);
use Test::Differences;

use CSS::Sass;

sub read_file
{
  use Carp;
  local $/ = undef;
  open my $fh, "<:raw:utf8", $_[0] or croak "Couldn't open file: <", $_[0], ">: $!";
  binmode $fh; return join "", <$fh>;
}

sub write_file
{
  use Carp;
  local $/ = undef;
  open my $fh, ">:raw:utf8", $_[0] or croak "Couldn't open file: <", $_[0], ">: $!";
  binmode $fh; return print $fh $_[1];
}

my $sass;
my ($r, $err);
my ($src, $expect);

# work directly on arg
# lib/sass_spec/test_case.rb
sub clean_output ($) {
	$_[0] =~ s/[\r\n\s	 ]+/ /g;
	$_[0] =~ s/[\r\n\s	 ]+,/,/g;
	$_[0] =~ s/,[\r\n\s	 ]+/,/g;
}
sub comp_output ($) {
	# $_[0] =~ s/(?<!\d)0(\.\d)/$1/g;
}
sub norm_output ($) {
	# $_[0] =~ s/\r//g;
	# $_[0] =~ s/\s+([{,])/$1/g;
	# $_[0] =~ s/#ff0/yellow/g;
	$_[0] =~ s/(?:\n)+/\n/g;
	$_[0] =~ s/(?:\r\n)+/\r\n/g;
	$_[0] =~ s/;(?:\s*;)+/;/g;
	$_[0] =~ s/;\s*}/}/g;
}

my $cwd = File::Spec->rel2abs("t");
my $cwd_url = $cwd; $cwd_url =~ tr/\\/\//;
my $cwd_path = $cwd; $cwd_path =~ tr/\//\\/;

sub clean_err {
	my $str = $_[0];
	return unless defined $_[0];
	$str =~ s/(?:\/todo_|_todo\/)/\//g;
	$str =~ s/\/libsass\-[a-z]+\-tests\//\//g;
	$str =~ s/\/libsass\-[a-z]+\-issues\//\/libsass\-issues\//g;
	$str =~ s/[\w\/\-\\:]+?[\/\\]spec[\/\\]+/\/sass\/spec\//g;
	$str =~ s/(?:\r?\n)*\z/\n/;
	$str =~ s/\A(?:\r?\n)+\z//;
	# sometimes we want to skip these
	my (@blocks);
	my $head = my $block = [];
	$str =~ s/\A(?:\r?\n)+//;
	my @lines = split /\r?\n/, $str;
	foreach my $line (@lines) {
		# next if ($line eq "");
		if ($line =~ m/^DEPRECATION WARNING/) {
			$block = [ $line ];
			unless ($line =~ m/interpolation near operators will be simplified/) {
				push @blocks, $block;
			}
		} elsif ($line =~ m/^Error:/) {
			$block = [ $line ];
			push @blocks, $block;
		} else {
			push @{$block}, $line;
		}
	}
	return join("\n", map { @{$_} } ($head, @blocks, [""]));
}

my @false_negatives;

sub res_expected_file {
	my $name = $_[0];
	$name =~ s/\.css$/libsass.css/;
	return -f $name ? $name : $_[0];
}

my $sass_cmd = "C:\\Ruby\\193\\bin\\sass.bat";
warn "\nRegenerate specs using ", `$sass_cmd -v`, "\n" if ($redo_sass);

my %options;
my @cmds;
foreach my $test (@tests)
{

	my $input_file = join("/", $test->[0], $test->[1]);
	my $options_file = join("/", $test->[0], 'options');
	my $output_error = join("/", $test->[0], 'error');
	my $output_status = join("/", $test->[0], 'status');
	my $output_nested = join("/", $test->[0], 'expected_output.css');
	my $output_compact = join("/", $test->[0], 'expected.compact.css');
	my $output_expanded = join("/", $test->[0], 'expected.expanded.css');
	my $output_compressed = join("/", $test->[0], 'expected.compressed.css');

	my %custom;
	if (-f $options_file) {
		my $options = read_file($options_file); $options =~ s/(?:\r\n|\n)+$//;
		%custom = map { split /\s*:\s*/ } split(/(?:\r\n|\n)+/, $options);
	}

	$output_nested = res_expected_file($output_nested);
	$output_compact = res_expected_file($output_compact);
	$output_expanded = res_expected_file($output_expanded);
	$output_compressed = res_expected_file($output_compressed);

	eval('use Win32::Process;');
	eval('use Win32;');

	if ($redo_sass)
	{
		my $cmd_opt = join "", map { sprintf " --%s=%s", $_, $custom{$_} } keys %custom;
		unless (-f join("/", $test->[0], 'redo.skip') || -f join("/", $test->[0], 'error.todo')) {
			unlink $output_error if -f $output_error;
			unlink $output_status if -f $output_status;
			unlink $output_nested if -f $output_nested;
			unlink $output_compact if -f $output_compact;
			unlink $output_expanded if -f $output_expanded;
			unlink $output_compressed if -f $output_compressed;
			unlink "$output_nested.stderr" if -f "$output_nested.stderr";
			unlink "$output_compact.stderr" if -f "$output_compact.stderr";
			unlink "$output_expanded.stderr" if -f "$output_expanded.stderr";
			unlink "$output_compressed.stderr" if -f "$output_compressed.stderr";
			push @cmds, ["$sass_cmd -E utf-8 --unix-newlines --sourcemap=none -t nested $cmd_opt -C \"$input_file\" \"$output_nested\" 2>\"$output_nested.stderr\"", $input_file, $output_nested, $test] if ($do_nested);
			push @cmds, ["$sass_cmd -E utf-8 --unix-newlines --sourcemap=none -t compact $cmd_opt -C \"$input_file\" \"$output_compact\" 2>\"$output_compact.stderr\"", $input_file, $output_compact, $test] if ($do_compact);
			push @cmds, ["$sass_cmd -E utf-8 --unix-newlines --sourcemap=none -t expanded $cmd_opt -C \"$input_file\" \"$output_expanded\" 2>\"$output_expanded.stderr\"", $input_file, $output_expanded, $test] if ($do_expanded);
			push @cmds, ["$sass_cmd -E utf-8 --unix-newlines --sourcemap=none -t compressed $cmd_opt -C \"$input_file\" \"$output_compressed\" 2>\"$output_compressed.stderr\"", $input_file, $output_compressed, $test] if ($do_compressed);
		} else {
			SKIP: { skip("redo of $output_nested", 1) if ($do_nested); }
			SKIP: { skip("redo of $output_compact", 1) if ($do_compact); }
			SKIP: { skip("redo of $output_expanded", 1) if ($do_expanded); }
			SKIP: { skip("redo of $output_compressed", 1) if ($do_compressed); }
		}
	}
}

sub postproc
{
	my ($proc, $cmd) = @_;
	$proc->GetExitCode($cmd->[4]);
	write_file($cmd->[2] . ".status", $cmd->[4]);
	pass("regenerated: " . $cmd->[2]);

}


my @running; my $i = 0;
foreach my $cmd (@cmds) {

	my $ProcessObj;
	Win32::Process::Create($ProcessObj,
	                       $sass_cmd,
	                       $cmd->[0],
	                       0,
	                       Win32::Process::NORMAL_PRIORITY_CLASS(),
	                       ".")
	|| die "error $!";

	push @running, [ $ProcessObj, $cmd ];

	while (scalar(@running) >= 12) {
		@running = grep {
			my $rv = $_->[0]->Wait(0);
			postproc($_->[0], $_->[1]) if $rv;
			! $rv;
		} @running;
		select undef, undef, undef, 0.0125;
	}

	select undef, undef, undef, 0.0125;

}

while (scalar(@running)) {
	@running = grep {
		my $rv = $_->[0]->Wait(0);
		postproc($_->[0], $_->[1]) if $rv;
		! $rv;
	} @running;
}

if ($redo_sass) {
	foreach my $test (@tests)
	{

		unless (-f join("/", $test->[0], 'redo.skip') || -f join("/", $test->[0], 'error.todo')) {
			my $output_error = join("/", $test->[0], 'error');
			my $output_nested = join("/", $test->[0], 'expected_output.css');
			my $output_compact = join("/", $test->[0], 'expected.compact.css');
			my $output_expanded = join("/", $test->[0], 'expected.expanded.css');
			my $output_compressed = join("/", $test->[0], 'expected.compressed.css');
			$output_nested = res_expected_file($output_nested);
			$output_compact = res_expected_file($output_compact);
			$output_expanded = res_expected_file($output_expanded);
			$output_compressed = res_expected_file($output_compressed);
			die "not found: ", $output_nested . ".stderr" unless -f $output_nested . ".stderr";
			die "not found: ", $output_compact . ".stderr" unless -f $output_compact . ".stderr";
			die "not found: ", $output_expanded . ".stderr" unless -f $output_expanded . ".stderr";
			die "not found: ", $output_compressed . ".stderr" unless -f $output_compressed . ".stderr";
			my $stderr_nested = clean_err(read_file($output_nested . ".stderr"));
			my $stderr_compact = clean_err(read_file($output_compact . ".stderr"));
			my $stderr_expanded = clean_err(read_file($output_expanded . ".stderr"));
			my $stderr_compressed = clean_err(read_file($output_compressed . ".stderr"));
			die "not found: ", $output_nested . ".status" unless -f $output_nested . ".status";
			die "not found: ", $output_compact . ".status" unless -f $output_compact . ".status";
			die "not found: ", $output_expanded . ".status" unless -f $output_expanded . ".status";
			die "not found: ", $output_compressed . ".status" unless -f $output_compressed . ".status";
			my $exitcode_nested = read_file($output_nested . ".status");
			my $exitcode_compact = read_file($output_compact . ".status");
			my $exitcode_expanded = read_file($output_expanded . ".status");
			my $exitcode_compressed = read_file($output_compressed . ".status");


			# only write the error file once if all results are the same
			if ($exitcode_nested eq $exitcode_compact && $exitcode_nested eq $exitcode_expanded && $exitcode_nested eq $exitcode_compressed)
			{
				write_file(catfile(dirname($output_nested), "status"), $exitcode_nested) if $exitcode_nested != 0;
				# clean up individual files
				# unlink $output_nested . ".stderr";
				unlink $output_nested . ".status";
				# unlink $output_compact . ".stderr";
				unlink $output_compact . ".status";
				# unlink $output_expanded . ".stderr";
				unlink $output_expanded . ".status";
				# unlink $output_compressed . ".stderr";
				unlink $output_compressed . ".status";
			}
			# error in case of mismatch
			else {
				warn "nested:     [[" . $exitcode_nested . "]]\n";
				warn "compact:    [[" . $exitcode_compact . "]]\n";
				warn "expanded:   [[" . $exitcode_expanded . "]]\n";
				warn "compressed: [[" . $exitcode_compressed . "]]\n";
				die "detected exit code mismatch for different output styles"
			}

			unless ($stderr_nested eq $stderr_compact && $stderr_nested eq $stderr_expanded && $stderr_nested eq $stderr_compressed)
			{
				warn "nested:     [[" . $stderr_nested . "]]\n";
				warn "compact:    [[" . $stderr_compact . "]]\n";
				warn "expanded:   [[" . $stderr_expanded . "]]\n";
				warn "compressed: [[" . $stderr_compressed . "]]\n";
				warn "detected error spec mismatch for different output styles"
			}

			write_file(catfile(dirname($output_nested), "error"), $stderr_nested) if $stderr_nested ne "";
			# clean up individual files
			if ($exitcode_nested != 0) {
				unlink $output_compact;
				unlink $output_expanded;
				unlink $output_compressed;
				write_file($output_nested, "");
			} else {
				# unlink $output_error;
			}
			# clean up individual files
			unlink $output_nested . ".stderr";
			unlink $output_compact . ".stderr";
			unlink $output_expanded . ".stderr";
			unlink $output_compressed . ".stderr";

		}


	}
}

# check if the benchmark module is available
my $benchmark = eval "use Benchmark; 1" ;

# get benchmark stamp before compiling
my $t0 = $benchmark ? Benchmark->new : 0;

foreach my $test (@tests)
{

	my $input_file = join("/", $test->[0], $test->[1]);
	my $options_file = join("/", $test->[0], 'options');
	my $output_nested = join("/", $test->[0], 'expected_output.css');
	my $output_compact = join("/", $test->[0], 'expected.compact.css');
	my $output_expanded = join("/", $test->[0], 'expected.expanded.css');
	my $output_compressed = join("/", $test->[0], 'expected.compressed.css');

	my %custom;
	if (-f $options_file) {
		my $options = read_file($options_file); $options =~ s/(?:\r\n|\n)+$//;
		%custom = map { split /\s*:\s*/ } split(/(?:\r\n|\n)+/, $options);
	}
	# warn $input_file;

	#my $last_error; my $on_error;
	#$options{"sass_functions"} = {
	#	'reset-error()' => sub { $last_error = undef; },
	#	'last-error()' => sub { return ${$last_error || \ undef}; },
	#	'mock-errors($on)' => sub { $on_error = $_[0]; return undef; },
	#	'@error' => sub { $last_error = $_[0]; warn $_[0]; return "thrown"; }
	#};

	my $comp_nested = CSS::Sass->new(%options, %custom, output_style => SASS_STYLE_NESTED);
	my $comp_compact = CSS::Sass->new(%options, %custom, output_style => SASS_STYLE_COMPACT);
	my $comp_expanded = CSS::Sass->new(%options, %custom, output_style => SASS_STYLE_EXPANDED);
	my $comp_compressed = CSS::Sass->new(%options, %custom, output_style => SASS_STYLE_COMPRESSED);

	no warnings 'once';
	open OLDFH, '>&STDERR';

	open(STDERR, "+>", "specs.stderr.nested.log"); select(STDERR); $| = 1;
	my $css_nested = eval { $do_nested && $comp_nested->compile_file($input_file) }; my $error_nested = $@;
	print STDERR "\n"; sysseek(STDERR, 0, 0); close(STDERR);
	open(STDERR, "+>", "specs.stderr.compact.log"); select(STDERR); $| = 1;
	my $css_compact = eval { $do_compact && $comp_compact->compile_file($input_file) }; my $error_compact = $@;
	print STDERR "\n"; sysseek(STDERR, 0, 0); close(STDERR);
	open(STDERR, "+>", "specs.stderr.expanded.log"); select(STDERR); $| = 1;
	my $css_expanded = eval { $do_expanded && $comp_expanded->compile_file($input_file) }; my $error_expanded = $@;
	print STDERR "\n"; sysseek(STDERR, 0, 0); close(STDERR);
	open(STDERR, "+>", "specs.stderr.compressed.log"); select(STDERR); $| = 1;
	my $css_compressed = eval { $do_compressed && $comp_compressed->compile_file($input_file) }; my $error_compressed = $@;
	print STDERR "\n"; sysseek(STDERR, 0, 0); close(STDERR);

	open STDERR, '>&OLDFH';

	# special case for error tests
	if (-e join("/", $test->[0], "error")) {
		my $err_expected = clean_err(read_file(join("/", $test->[0], "error")));
		my $stderr_nested = clean_err(read_file("specs.stderr.nested.log") . "\n" . $error_nested);
		my $stderr_compact = clean_err(read_file("specs.stderr.compact.log") . "\n" . $error_compact);
		my $stderr_expanded = clean_err(read_file("specs.stderr.expanded.log") . "\n" . $error_expanded);
		my $stderr_compressed = clean_err(read_file("specs.stderr.compressed.log") . "\n" . $error_compressed);
		# only compare first line ...
		$err_expected =~ s/(?:\n|\r)(?:\n|\r|.)*$//;
		$stderr_nested =~ s/(?:\n|\r)(?:\n|\r|.)*$//;
		$stderr_compact =~ s/(?:\n|\r)(?:\n|\r|.)*$//;
		$stderr_expanded =~ s/(?:\n|\r)(?:\n|\r|.)*$//;
		$stderr_compressed =~ s/(?:\n|\r)(?:\n|\r|.)*$//;
		unless ($input_file =~ m/todo/)
		{
			eq_or_diff ($stderr_nested, $err_expected, $test->[0] . "/stderr.nested.log matches");
			eq_or_diff ($stderr_compact, $err_expected, $test->[0] . "/stderr.compact.log matches");
			eq_or_diff ($stderr_expanded, $err_expected, $test->[0] . "/stderr.expanded.log matches");
			eq_or_diff ($stderr_compressed, $err_expected, $test->[0] . "/stderr.compressed.log matches");
		}
		else {
			my $surprise = sub { fail("suprprise in: " . $_[0]); push @surprises, [ @_ ]; };
			if ($stderr_nested eq $err_expected)
			{ $surprise->(join("/", $test->[0], 'expected.stderr.nested')); }
			else { pass(join("/", $test->[0], 'expected.stderr.nested') . " is still failing"); }
			if ($stderr_compact eq $err_expected)
			{ $surprise->(join("/", $test->[0], 'expected.stderr.compact')); }
			else { pass(join("/", $test->[0], 'expected.stderr.compact') . " is still failing"); }
			if ($stderr_expanded eq $err_expected)
			{ $surprise->(join("/", $test->[0], 'expected.stderr.expanded')); }
			else { pass(join("/", $test->[0], 'expected.stderr.expanded') . " is still failing"); }
			if ($stderr_compressed eq $err_expected)
			{ $surprise->(join("/", $test->[0], 'expected.stderr.compressed')); }
			else { pass(join("/", $test->[0], 'expected.stderr.compressed') . " is still failing"); }
		}
	next }

	use warnings 'once';

	# warn $output_nested unless defined $css_nested;
	$css_nested = "[$error_nested]" unless defined $css_nested;
	# warn $output_compact unless defined $css_compact;
	$css_compact = "[$error_compact]" unless defined $css_compact;
	# warn $output_expanded unless defined $css_expanded;
	$css_expanded = "[$error_expanded]" unless defined $css_expanded;
	# warn $output_compressed unless defined $css_compressed;
	$css_compressed = "[$error_compressed]" unless defined $css_compressed;

	my $sass_nested = $do_nested && -f $output_nested  ? read_file($output_nested) : '';
	my $sass_compact = $do_compact && -f $output_compact ? read_file($output_compact) : '';
	my $sass_expanded = $do_expanded && -f $output_expanded  ? read_file($output_expanded) : '';
	my $sass_compressed = $do_compressed && -f $output_compressed  ? read_file($output_compressed) : '';

	die "read $output_nested" unless defined $sass_nested;
	die "read $output_compact" unless defined $sass_compact;
	die "read $output_expanded" unless defined $sass_expanded;
	die "read $output_compressed" unless defined $sass_compressed;

	utf8::decode($css_nested) if ($css_nested) ;
	utf8::decode($css_compact) if ($css_compact) ;
	utf8::decode($css_expanded) if ($css_expanded) ;
	utf8::decode($css_compressed) if ($css_compressed);

	utf8::decode($sass_nested) if ($sass_nested) ;
	utf8::decode($sass_compact) if ($sass_compact) ;
	utf8::decode($sass_expanded) if ($sass_expanded) ;
	utf8::decode($sass_compressed) if ($sass_compressed);

	if (-e substr($output_nested, 0, -4) . ".clean")
	{ clean_output $css_nested; clean_output $sass_nested; }
	if (-e substr($output_compact, 0, -4) . ".clean")
	{ clean_output $css_compact; clean_output $sass_compact; }
	if (-e substr($output_expanded, 0, -4) . ".clean")
	{ clean_output $css_expanded; clean_output $sass_expanded; }
	if (-e substr($output_compressed, 0, -4) . ".clean")
	{ clean_output $css_compressed; clean_output $sass_compressed; }

	norm_output $css_nested; norm_output $sass_nested;
	norm_output $css_compact; norm_output $sass_compact;
	norm_output $css_expanded; norm_output $sass_expanded;
	norm_output $css_compressed; norm_output $sass_compressed;
	comp_output $css_compressed; comp_output $sass_compressed;

	unless ($input_file =~ m/todo/)
	{

		# oldstyle_diff;
		unless ($do_nested) { }
		elsif (-f join("/", $test->[0], 'expected_output.skip')) { SKIP: { skip("nested", 1) } }
		else { eq_or_diff ($css_nested, $sass_nested, "nested $output_nested") }
		die if ($do_nested && $die_first && $css_nested ne $sass_nested);

		unless ($do_compact) { }
		elsif (-f join("/", $test->[0], 'expected.compact.skip')) { SKIP: { skip("compact", 1) } }
		elsif (!-f join("/", $test->[0], 'expected.compact.css')) { SKIP: { skip("compact", 1) } }
		else { eq_or_diff ($css_compact, $sass_compact, "compact $output_compact") }
		die if ($do_compact && $die_first && $css_compact ne $sass_compact);

		unless ($do_expanded) { }
		elsif (-f join("/", $test->[0], 'expected.expanded.skip')) { SKIP: { skip("expanded", 1) } }
		elsif (!-f join("/", $test->[0], 'expected.expanded.css')) { SKIP: { skip("expanded", 1) } }
		else { eq_or_diff ($css_expanded, $sass_expanded, "expanded $output_expanded") }
		die if ($do_expanded && $die_first && $css_expanded ne $sass_expanded);

		unless ($do_compressed) { }
		elsif (-f join("/", $test->[0], 'expected.compressed.skip')) { SKIP: { skip("compressed", 1) } }
		elsif (!-f join("/", $test->[0], 'expected.compressed.css')) { SKIP: { skip("compressed", 1) } }
		else { eq_or_diff ($css_compressed, $sass_compressed, "compressed $output_compressed") }
		die if ($do_compressed && $die_first && $css_compressed ne $sass_compressed);

	}
	else
	{

		# warn "doing test spec " << $test->[0], "\n";

		my $surprise = sub { fail("suprprise in: " . $_[0]); push @surprises, [ @_ ]; };

		if ($css_nested eq $sass_nested)
		{ $surprise->(join("/", $test->[0], 'expected.nested')); }
		else { pass(join("/", $test->[0], 'expected.nested') . " is still failing"); }

		if ($css_compact eq $sass_compact)
		{ $surprise->(join("/", $test->[0], 'expected.compact')); }
		else { pass(join("/", $test->[0], 'expected.compact') . " is still failing"); }

		if ($css_expanded eq $sass_expanded)
		{ $surprise->(join("/", $test->[0], 'expected.expanded')); }
		else { pass(join("/", $test->[0], 'expected.expanded') . " is still failing"); }

		if ($css_compressed eq $sass_compressed)
		{ $surprise->(join("/", $test->[0], 'expected.compressed')) }
		else { pass(join("/", $test->[0], 'expected.compressed') . " is still failing"); }

	}

}

# get benchmark stamp after compiling
my $t1 = $benchmark ? Benchmark->new : 0;

END {

	# only print benchmark result when module is available
	if ($benchmark) { warn "\nin ", timestr(timediff($t1, $t0)), "\n"; }
	# report all surprises before exiting
	foreach my $surprise (@surprises)
	{
		my $file = $surprise->[0];
		$file =~ s/\//\\/g if $^O eq 'MSWin32';
		warn sprintf "at %s\n", $file;
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