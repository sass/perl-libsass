# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 3;
BEGIN { use_ok('CSS::Sass') };

sub major_version
{
	my $version = shift;
	$version =~ m/^v?([0-9]+\.[0-9]+\.?)/;
	return defined $1 ? $1 : $version;
}

my $mod_version = major_version($CSS::Sass::VERSION);
my $lib_version = major_version(CSS::Sass::libsass_version());
my $sass2scss_version = CSS::Sass::sass2scss_version();


is  ($mod_version, $lib_version, "Have compatible version");
like($sass2scss_version, qr/^[0-9\.]+$/, "Reports sass2scss version");
