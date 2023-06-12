Source Maps
===========

This project implements a Dart pub package to work with source maps. The
implementation is based on the [source map version 3 spec][spec] which was
originated from the [Closure Compiler][closure] and has been implemented in
Chrome and Firefox.

In this package we provide:

  * Data types defining file locations and spans: these are not part of the
    original source map specification. These data types are great for tracking
    source locations on source maps, but they can also be used by tools to
    reporting useful error messages that include on source locations.
  * A builder that creates a source map programatically and produces the encoded
    source map format.
  * A parser that reads the source map format and provides APIs to read the
    mapping information.

Some upcoming features we are planning to add to this package are:

  * A printer that lets you generate code, but record source map information in
    the process.
  * A tool that can compose source maps together. This would be useful for
    instance, if you have 2 tools that produce source maps and you call one with
    the result of the other.

[closure]: http://code.google.com/p/closure-compiler/wiki/SourceMaps
[spec]: https://docs.google.com/a/google.com/document/d/1U1RGAehQwRypUTovF1KRlpiOFze0b-_2gc6fAH0KY0k/edit
