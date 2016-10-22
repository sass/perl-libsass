CSS::Sass
=========

### Compile .scss and .sass files using libsass

CSS::Sass provides a perl interface to [libsass][1], a fairly complete Sass
compiler written in C++. It is currently around ruby sass 3.3/3.4 feature parity and
heading towards full 3.4 compatibility. It can compile .scss and .sass files.

[1]: https://github.com/sass/libsass

Installation
------------

[![Build Status](https://travis-ci.org/sass/perl-libsass.svg?branch=master)](https://travis-ci.org/sass/perl-libsass)
[![Coverage Status](https://img.shields.io/coveralls/sass/perl-libsass.svg)](https://coveralls.io/r/sass/perl-libsass?branch=master)
[![CPAN version](https://badge.fury.io/pl/CSS-Sass.svg)](http://badge.fury.io/pl/CSS-Sass)

Manual installation:
```bash
  git clone https://github.com/sass/libsass
  cd libsass
  perl Makefile.PL
  make verbose=1
  make test verbose=1
  make install verbose=1
```

Standard CPAN:
```bash
  cpan CSS::Sass
```

CPAN-Minus*:
```bash
  cpanm CSS::Sass
```

CPAN-Minus* directly via github:
```bash
  cpanm https://github.com/sass/perl-libsass/archive/latest.tar.gz
```

(*) CPAN-Minus may not be installed by default, but there is a good
chance your distribution has a package for it:
```bash
  # example for ubuntu:
  apt install cpanminus
```

On windows I recommend [Strawberry Perl](http://strawberryperl.com/).
You then also need to use `dmake` instead of `make` for manual installs.

Documentation
-------------

Before installing:

    perldoc lib/CSS/Sass.pm

After installing:

    man CSS::Sass

Or view [converted markdown version][1]

[1]: https://github.com/sass/perl-libsass/blob/master/lib/CSS/Sass.md

Command line utility
--------------------

```
psass [options] [ path_in | - ] [ path_out | - ]
```

```
-v, --version                 print version
-h, --help                    print this help
-w, --watch                   start watchdog mode
-p, --precision=int           precision for float output
    --indent=string           set indent string used for output
    --linefeed=type           linefeed used for output [auto|unix|win|none]
-o, --output-file=file        output file to write result to
-t, --output-style=style      output style [expanded|nested|compressed|compact]
-P, --plugin-path=path        plugin load path (repeatable)
-I, --include-path=path       sass include path (repeatable)
-c, --source-comments         enable source debug comments
-l, --line-comments           synonym for --source-comments
    --line-numbers            synonym for --source-comments
-e, --source-map-embed        embed source-map in mapping url
-s, --source-map-contents     include original contents
-m, --source-map-file=file    create and write source-map to file
    --source-map-file-urls    create file urls for source paths
    --source-map-root=.       specific root for relative paths
    --no-source-map-url       omit sourceMappingUrl from output
    --benchmark               print benchmark for compilation time
```

Copyright And Licence
---------------------

Copyright © 2013-2014 by David Caldwell  
Copyright © 2014-2017 by Marcel Greter

This library is released under the MIT license.