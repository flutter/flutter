[![pub package](https://img.shields.io/pub/v/meta.svg)](https://pub.dev/packages/meta)
[![package publisher](https://img.shields.io/pub/publisher/meta.svg)](https://pub.dev/packages/meta/publisher)

This package defines annotations that can be used by the tools that are shipped
with the Dart SDK.

## Library Structure

The annotations in this package are defined in two libraries.

The library in `meta.dart` defines annotations that can be used by static
analysis tools to provide a more complete analysis of the code that uses them.
Within the SDK, these tools include the command-line analyzer (`dart analyze`)
and the analysis server that is used to power many of the Dart-enabled
development tools.

The library in `dart2js.dart` defines annotations that provide hints to dart2js
to improve the quality of the JavaScript code that it produces. These
annotations are currently experimental and might be removed in a future version
of this package.

## Support

Post issues and feature requests on the GitHub [issue tracker][issues].

Questions and discussions are welcome at the
[Dart Analyzer Discussion Group][list].

## License

See the [LICENSE][license] file.

[issues]: https://github.com/dart-lang/sdk/issues
[license]: https://github.com/dart-lang/sdk/blob/main/pkg/analyzer/LICENSE
[list]: https://groups.google.com/a/dartlang.org/forum/#!forum/analyzer-discuss
