Text::Sass::XS
==============

### Compile .scss files using libsass

Text::Sass::XS provides a perl interface to [libsass][1], a fairly complete
Sass compiler written in C. Despite its name, Text::Sass::XS can only
compile the newer ".scss" files.

[1]: https://github.com/hcatlin/libsass

Installation
------------

To install this module type the following:

   perl Build.PL
   ./Build
   ./Build test
   ./Build install

Documentation
-------------

Before installing:

    perldoc lib/Text/Sass/XS.pm

After installing:

    man Test::Sass::XS

Dependencies
------------

This module requires these other modules and libraries:

  * Module::Build
  * Test::More

Copyright And Licence
---------------------

Copyright © 2013 by David Caldwell

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.
