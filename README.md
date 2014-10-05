CSS::Sass
=========

### Compile .scss and .sass files using libsass

CSS::Sass provides a perl interface to [libsass][1], a fairly complete
Sass compiler written in C++. It is currently somewhere around ruby sass
3.2 feature parity. It can compile .scss and .sass files.

[1]: https://github.com/sass/libsass

Installation
------------

[![Build Status](https://travis-ci.org/sass/perl-libsass.svg?branch=master)](https://travis-ci.org/sass/perl-libsass)
[![Coverage Status](https://img.shields.io/coveralls/sass/perl-libsass.svg)](https://coveralls.io/r/sass/perl-libsass?branch=master)

To install this module type the following:

    perl Build.PL
    ./Build verbose=1
    ./Build test verbose=1
    ./Build install verbose=1

On windows you may need to install [Strawberry Perl](http://strawberryperl.com/).

Documentation
-------------

Before installing:

    perldoc lib/CSS/Sass.pm

After installing:

    man CSS::Sass

Or view [converted markdown version][1]

[1]: https://github.com/sass/perl-libsass/blob/master/lib/CSS/Sass.md

Dependencies
------------

This module requires these other modules and libraries:

  * Module::Build
  * Test::More

Command line utility
--------------------

```
psass [options] [ source | - ]
```

```
-v, --version                 print version
-h, --help                    print this help
-p, --precision               precision for float output
-t, --output-style=style      output style [nested|compressed]
-I, --include-path=path       sass include path (repeatable)
-c, --source-comments         enable source debug comments
-m, --source-map-file=file    create and write source map to file
    --omit-source-map-url     omit sourceMappingUrl from output
```

Copyright And Licence
---------------------

Copyright © 2013 by David Caldwell  
Copyright © 2014 by Marcel Greter

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.
