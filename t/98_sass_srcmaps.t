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

use Test::More;
plan(tests => 1);
SKIP: { skip("deactivated", 1); }
exit(0);


if (eval { require OCBNET::SourceMap; 1 })
{
	plan(tests => 1 + @tests * 2);
}
else
{
	plan(skip_all => 'OCBNET::SourceMap not installed');
}

use_ok('OCBNET::SourceMap');

use CSS::Sass qw(SASS_STYLE_NESTED);

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

1;
