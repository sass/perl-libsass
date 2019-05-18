CSS::Sass
=========

### Compile .scss and .sass files using LibSass

CSS::Sass provides a perl interface to [LibSass][1], a nearly complete Sass
compiler written in C++. It is currently at ruby sass 3.4 feature parity and
heading towards 3.5 compatibility. It can compile .scss and .sass files.

[1]: https://github.com/sass/libsass

Installation
------------

[![Build Status](https://travis-ci.org/sass/perl-libsass.svg?branch=master)](https://travis-ci.org/sass/perl-libsass)
[![Build status](https://ci.appveyor.com/api/projects/status/wg7joe46resvh1ow/branch/master?svg=true)](https://ci.appveyor.com/project/sass/perl-libsass/branch/master)
[![Coverage Status](https://img.shields.io/coveralls/sass/perl-libsass.svg)](https://coveralls.io/r/sass/perl-libsass?branch=master)
[![CPAN version](https://badge.fury.io/pl/CSS-Sass.svg)](http://badge.fury.io/pl/CSS-Sass)

Manual installation:
```bash
  git clone https://github.com/sass/libsass
  cd libsass
  # disable plugins if you have problems compiling
  perl Makefile.PL --no-plugins
  make -j4 verbose=1
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
  cpanm git://github.com/sass/perl-libsass.git
```

(*) CPAN-Minus may not be installed by default, but there is a good
chance your distribution has a package for it:
```bash
  # example for ubuntu:
  apt install cpanminus
```

On windows I recommend [Strawberry Perl](http://strawberryperl.com/).
Tip: Use `dmake -PX` instead of `make -jX` for manual installs.

Build Options
-------------

Since we need LibSass for perl-libsass, we need to compile the sources
when building CSS::Sass. LibSass can be compiled in different ways and
Makefile.PL knows some switches to support most common use cases:

```
$ perl Makefile.PL --help

CSS::Sass Makefile.PL end-user options:

  --sassc              Install optional sassc cli utility
  --plugins            Install optional libsass plugins (default)
  --library            Install libsass library (auto-enabled)
  --native-watcher     Depend on optimized file watcher module
  --help               This help screen

  The following options are for developers only:

  --debug              Build libsass in debug mode
  --profiling          Enable gcov profiling switches
  --compiler           Skips compiler autodetection (passed to CppGuess)
  --skip-manifest      Skips manifest generation (would need git repo)
  --skip-version       Skips generating libsass/VERSION (would need git repo)
  --update-deps        Update libsass and specs to latest master (needs git repo)
  --checkout-deps      Checkout submodules at linked commit (needs git repo)
  --get-versions       Show versions of all perl package (.pm) files
  --set-versions       Set versions of all perl package (.pm) files
  --patch-gcc44        Patch libsass for gcc44 compatibility
  --skip-git           Do not try to use anything git related

  You may use environment variables to set any option
  Prefix them with `PSASS_` and write all in uppercase
  e.g. --native-watcher becomes PSASS_NATIVE_WATCHER
```

Documentation
-------------

Before installing:

    perldoc lib/CSS/Sass.pm

After installing:

    man CSS::Sass

Or view [converted markdown version][4]

[4]: https://github.com/sass/perl-libsass/blob/master/lib/CSS/Sass.md

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

Plugins may be pre-installed by CSS::Sass or from 3rd parties.
There are some options available for each known plugin.

    --all-plugins             enables all known plugins
    --list-plugin             print list of all known plugins
    --[name]-plugin           enables the plugin with [name]
    --no-[name]-plugin        disabled the plugin with [name]
```


Included default plugins
------------------------

```
$ psass --list-plugins
```

- [--digest-plugin][2]
- [--glob-plugin][3]
- [--img-size-plugin][4]
- [--math-plugin][5]

[2]: https://github.com/mgreter/libsass-digest
[3]: https://github.com/mgreter/libsass-glob
[4]: https://github.com/mgreter/libsass-img-size
[5]: https://github.com/mgreter/libsass-math


Copyright And Licence
---------------------

Copyright © 2013-2014 by David Caldwell  
Copyright © 2014-2017 by Marcel Greter

This library is released under the MIT license.