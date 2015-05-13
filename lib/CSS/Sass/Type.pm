use strict;
use warnings;

# load new package name
use CSS::Sass::Value qw();

# link old package namespace with new package
BEGIN { *CSS::Sass::Type:: = *CSS::Sass::Value:: }

1;