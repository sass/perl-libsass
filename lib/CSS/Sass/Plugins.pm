# Copyright (c) 2013-2014 David Caldwell.
# Copyright (c) 2014-2017 Marcel Greter.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

use strict;
use warnings;

################################################################################
package CSS::Sass::Plugins;
our $VERSION = "3.4.2";
################################################################################
# collect plugins
our %plugins;
################################################################################
use Exporter 'import'; # gives you Exporter's import() method directly
our @EXPORT = qw(%plugins); # symbols to export by default
################################################################################

# prefix to append to root path
my $path = '/auto/CSS/Sass/plugins/';
# get our own path for module file
# we asume plugin path from install
my $root = $INC{'CSS/Sass/Plugins.pm'};
die "Module path not found" unless $root;
# only interested in base path
$root = substr($root, 0, -20) . $path;
# silently ignore missing directory
return \%plugins unless -d $root;
# open plugins directory to query
opendir (my $dh, $root) or
	die "error querying plugins";
while (my $item = readdir($dh)) {
	next unless $item =~ m/^[a-zA-Z]+$/;
	$plugins{$item} = $root . $item
}

################################################################################
################################################################################
1;