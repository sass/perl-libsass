CSS::Sass
=========

### Compile .scss files using libsass

CSS::Sass provides a perl interface to [libsass][1], a fairly complete
Sass compiler written in C. Despite its name, CSS::Sass can only
compile the newer ".scss" files (support for indented syntax is in
[alpha stage][2]).

[1]: https://github.com/hcatlin/libsass
[2]: https://github.com/hcatlin/libsass/issues/16

Installation
------------

[![Build Status](https://travis-ci.org/mgreter/CSS-Sass.svg?branch=master)](https://travis-ci.org/mgreter/CSS-Sass)
[![Coverage Status](https://img.shields.io/coveralls/mgreter/CSS-Sass.svg)](https://coveralls.io/r/mgreter/CSS-Sass?branch=master)

To install this module type the following:

    perl Build.PL
    ./Build verbose=1
    ./Build test verbose=1
    ./Build install verbose=1

On windows you need to install [Strawberry Perl](http://strawberryperl.com/).

Documentation
-------------

Before installing:

    perldoc lib/CSS/Sass.pm

After installing:

    man CSS::Sass

Dependencies
------------

This module requires these other modules and libraries:

  * Module::Build
  * Test::More

Copyright And Licence
---------------------

Copyright © 2013 by David Caldwell
Copyright © 2014 by Marcel Greter

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.
