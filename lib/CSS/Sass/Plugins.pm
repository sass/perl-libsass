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
our $VERSION = "3.4.13";
################################################################################
# collect plugins
our %plugins;
################################################################################
# all plugin directory variants
# propably too many, check-a-lot
our @ppaths = (
  'arch',
  'arch/auto',
  'arch/auto/lib',
  'blib',
  'blib/auto',
  'blib/auto/arch',
  'blib/arch',
  'blib/arch/auto',
  'blib/lib',
  'blib/lib/arch',
  'blib/lib/arch/auto',
  'lib',
  'lib/arch',
  'lib/arch/auto',
  'lib/auto',
);
################################################################################
use Exporter 'import'; # gives you Exporter's import() method directly
our @EXPORT = qw(%plugins @ppaths); # symbols to export by default
################################################################################

foreach my $path (map {
  $_ . '/CSS/Sass/plugins'
} @ppaths) {
  # get our own path for module file
  # we asume plugin path from install
  my $rpath = $INC{'CSS/Sass/Plugins.pm'};
  die "Module path not found" unless $rpath;
  # normalize all slashes
  $rpath =~ s/[\\\/]+/\//g;
  # remove our own file from path
  $rpath =~ s/CSS\/Plugins\.pm$//;
  # remove perl path parts
  $rpath =~ s/(?:b?lib\/+)+//g;
  # remove trailing slash
  $rpath =~ s/[\\\/]+$//g;
  # only interested in base path
  $rpath = $rpath . $path;
  # silently ignore missing directory
  next unless -d $rpath;
  # open plugins directory to query
  opendir (my $dh, $rpath) or
    die "error querying plugins";
  while (my $item = readdir($dh)) {
    next unless $item =~ m/^[a-zA-Z\-]+$/;
    $plugins{$item} = $rpath . $item
  }

}

return \%plugins;

################################################################################
################################################################################
1;
