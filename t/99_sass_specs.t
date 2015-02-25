# -*- perl -*-

use strict;
use warnings;

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
			$todo = $todo || $ent eq "todo" ||
				$ent eq "libsass-todo-tests" ||
				$ent eq "libsass-todo-issues";
			my $path = join("/", $dir, $ent);
			next if $ent eq "huge" && $skip_huge;
			next if($todo && $skip_todo);
			push @dirs, $path if -d $path;
			if ($ent =~ m/^input\./)
			{
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
  binmode $fh; return <$fh>;
}

my $sass;
my ($r, $err);
my ($src, $expect);

# work directly on arg
# lib/sass_spec/test_case.rb
sub clean_output ($) {
		$_[0] =~ s/(?:\r?\n)+/\n/g;
		$_[0] =~ s/(?:\r?\n)+$/\n/g;
}

my @false_negatives;

my %options;
my @cmds;
foreach my $test (@tests)
{

	my $input_file = join("/", $test->[0], $test->[1]);
	my $output_nested = join("/", $test->[0], 'expected_output.css');
	my $output_compact = join("/", $test->[0], 'expected.compact.css');
	my $output_expanded = join("/", $test->[0], 'expected.expanded.css');
	my $output_compressed = join("/", $test->[0], 'expected.compressed.css');

	use Win32::Process;
	use Win32;

	if ($redo_sass)
	{
		unless (-f join("/", $test->[0], 'redo.skip')) {
			push @cmds, ["C:\\Ruby\\193\\bin\\sass --unix-newlines --sourcemap=none -t nested -C \"$input_file\" \"$output_nested\"", $input_file] if ($do_nested);
			push @cmds, ["C:\\Ruby\\193\\bin\\sass --unix-newlines --sourcemap=none -t compact -C \"$input_file\" \"$output_compact\"", $input_file] if ($do_compact);
			push @cmds, ["C:\\Ruby\\193\\bin\\sass --unix-newlines --sourcemap=none -t expanded -C \"$input_file\" \"$output_expanded\"", $input_file] if ($do_expanded);
			push @cmds, ["C:\\Ruby\\193\\bin\\sass --unix-newlines --sourcemap=none -t compressed -C \"$input_file\" \"$output_compressed\"", $input_file] if ($do_compressed);
		} else {
			SKIP: { skip("dont redo expected_output.css", 1) if ($do_nested); }
			SKIP: { skip("dont redo expected.compact.css", 1) if ($do_compact); }
			SKIP: { skip("dont redo expected.expanded.css", 1) if ($do_expanded); }
			SKIP: { skip("dont redo expected.compressed.css", 1) if ($do_compressed); }
		}
	}
}


my @running; my $i = 0;
foreach my $cmd (@cmds) {
# warn "generating $cmd->[1]\n";

    my $ProcessObj;
    Win32::Process::Create($ProcessObj,
                                "C:\\Ruby\\193\\bin\\sass.bat",
                                $cmd->[0],
                                0,
                                NORMAL_PRIORITY_CLASS,
                                ".")|| die "error $!";

    push @running, $ProcessObj;

    while (scalar(@running) >= 12) {
    	@running = grep {
    		! $_->Wait(0);
    	} @running;

  select undef, undef, undef, 0.0125;

    }

  pass("regenerated " . $cmd->[1]);

  select undef, undef, undef, 0.0125;

}

while (scalar(@running)) {
	@running = grep {
		! $_->Wait(0);
	} @running;
}

foreach my $test (@tests)
{

	my $input_file = join("/", $test->[0], $test->[1]);
	my $output_nested = join("/", $test->[0], 'expected_output.css');
	my $output_compact = join("/", $test->[0], 'expected.compact.css');
	my $output_expanded = join("/", $test->[0], 'expected.expanded.css');
	my $output_compressed = join("/", $test->[0], 'expected.compressed.css');

	# warn $input_file;

	my $comp_nested = CSS::Sass->new(output_style => SASS_STYLE_NESTED);
	my $comp_compact = CSS::Sass->new(%options, output_style => SASS_STYLE_COMPACT);
	my $comp_expanded = CSS::Sass->new(%options, output_style => SASS_STYLE_EXPANDED);
	my $comp_compressed = CSS::Sass->new(%options, output_style => SASS_STYLE_COMPRESSED);

	my $css_nested = eval { $do_nested && $comp_nested->compile_file($input_file) }; my $error_nested = $@;
	my $css_compact = eval { $do_compact && $comp_compact->compile_file($input_file) }; my $error_compact = $@;
	my $css_expanded = eval { $do_expanded && $comp_expanded->compile_file($input_file) }; my $error_expanded = $@;
	my $css_compressed = eval { $do_compressed && $comp_compressed->compile_file($input_file) }; my $error_compressed = $@;

	# warn $output_nested unless defined $css_nested;
	$css_nested = "[$error_nested]" unless defined $css_nested;
	# warn $output_compact unless defined $css_compact;
	$css_compact = "[$error_compact]" unless defined $css_compact;
	# warn $output_expanded unless defined $css_expanded;
	$css_expanded = "[$error_expanded]" unless defined $css_expanded;
	# warn $output_compressed unless defined $css_compressed;
	$css_compressed = "[$error_compressed]" unless defined $css_compressed;

	my $sass_nested = $do_nested ? read_file($output_nested) : '';
	my $sass_compact = $do_compact ? read_file($output_compact) : '';
	my $sass_expanded = $do_expanded ? read_file($output_expanded) : '';
	my $sass_compressed = $do_compressed ? read_file($output_compressed) : '';

	die "read $output_nested" unless defined $sass_nested;
	die "read $output_compact" unless defined $sass_compact;
	die "read $output_expanded" unless defined $sass_expanded;
	die "read $output_compressed" unless defined $sass_compressed;

	utf8::decode($css_nested) if ($css_nested) ;
	utf8::decode($css_compact) if ($css_compact) ;
	utf8::decode($css_expanded) if ($css_expanded) ;
	utf8::decode($css_compressed) if ($css_compressed);

	clean_output $css_nested;
	clean_output $sass_nested;
	clean_output $css_compact;
	clean_output $sass_compact;
	clean_output $css_expanded;
	clean_output $sass_expanded;

	#sub clean_comments {
	#	my $str = $_[0];
	#	$str =~ s/\n+/ /g;
	#	$str =~ s/\s+/ /g;
	#	return '/* ' . $str . ' */';
	#}

	# $css_nested =~ s/^\s*\/\*(.*?)\*\//clean_comments($1)/egms;
	# $sass_nested =~ s/^\s*\/\*(.*?)\*\//clean_comments($1)/egms;
	# $css_compact =~ s/^\s*\/\*(.*?)\*\//clean_comments($1)/egms;
	# $sass_compact =~ s/^\s*\/\*(.*?)\*\//clean_comments($1)/egms;
	# $css_expanded =~ s/^\s*\/\*(.*?)\*\//clean_comments($1)/egms;
	# $sass_expanded =~ s/^\s*\/\*(.*?)\*\//clean_comments($1)/egms;

	# $css_nested =~ s/(?<=[^\n\r])  / /g;
	# $sass_nested =~ s/(?<=[^\n\r])  / /g;
	# $css_compact =~ s/(?<=[^\n\r])  / /g;
	# $sass_compact =~ s/(?<=[^\n\r])  / /g;
	# $css_expanded =~ s/(?<=[^\n\r])  / /g;
	# $sass_expanded =~ s/(?<=[^\n\r])  / /g;

	# $css_expanded =~ s/\\\\x\{/\\x{/g;
	# $sass_expanded =~ s/\\\\x\{/\\x{/g;

	unless ($input_file =~ m/todo/)
	{

		# oldstyle_diff;
		unless ($do_nested) { }
		elsif (-f join("/", $test->[0], 'expected_output.skip')) { SKIP: { skip("nested", 1) } }
		else { eq_or_diff ($css_nested, $sass_nested, "nested $output_nested") }
		die if ($do_nested && $die_first && $css_nested ne $sass_nested);

		unless ($do_compact) { }
		elsif (-f join("/", $test->[0], 'expected.compact.skip')) { SKIP: { skip("compact", 1) } }
		else { eq_or_diff ($css_compact, $sass_compact, "compact $output_compact") }
		die if ($do_compact && $die_first && $css_compact ne $sass_compact);

		unless ($do_expanded) { }
		elsif (-f join("/", $test->[0], 'expected.expanded.skip')) { SKIP: { skip("expanded", 1) } }
		else { eq_or_diff ($css_expanded, $sass_expanded, "expanded $output_expanded") }
		die if ($do_expanded && $die_first && $css_expanded ne $sass_expanded);

		unless ($do_compressed) { }
		elsif (-f join("/", $test->[0], 'expected.compressed.skip')) { SKIP: { skip("compressed", 1) } }
		else { eq_or_diff ($css_compressed, $sass_compressed, "compressed $output_compressed") }
		die if ($do_compressed && $die_first && $css_compressed ne $sass_compressed);

	}
	else
	{

		my $surprise = sub { fail("suprprise in: " . $_[0]); push @surprises, [ @_ ]; };

		if ($css_nested eq $sass_nested)
		{ $surprise->(join("/", $test->[0], 'expected.nested') . " unexpectely works"); }
		else { pass(join("/", $test->[0], 'expected.nested') . " is still failing"); }

		if ($css_compact eq $sass_compact)
		{ $surprise->(join("/", $test->[0], 'expected.compact') . " unexpectely works"); }
		else { pass(join("/", $test->[0], 'expected.compact') . " is still failing"); }

		if ($css_expanded eq $sass_expanded)
		{ $surprise->(join("/", $test->[0], 'expected.expanded') . " unexpectely works"); }
		else { pass(join("/", $test->[0], 'expected.expanded') . " is still failing"); }

		if ($css_compressed eq $sass_compressed)
		{ $surprise->(join("/", $test->[0], 'expected.compressed') . " unexpectely works") }
		else { pass(join("/", $test->[0], 'expected.compressed') . " is still failing"); }

	}

}
END {
	foreach my $surprise (@surprises)
	{
		printf STDERR "surprise: %s\n", $surprise->[0];
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