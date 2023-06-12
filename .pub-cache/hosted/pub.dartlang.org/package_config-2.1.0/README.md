[![Build Status](https://github.com/dart-lang/package_config/workflows/Dart%20CI/badge.svg)](https://github.com/dart-lang/package_config/actions?query=workflow%3A"Dart+CI"+branch%3Amaster)
[![pub package](https://img.shields.io/pub/v/package_config.svg)](https://pub.dev/packages/package_config)
[![package publisher](https://img.shields.io/pub/publisher/package_config.svg)](https://pub.dev/packages/package_config/publisher)

Support for working with **Package Configuration** files as described
in the Package Configuration v2 [design document](https://github.com/dart-lang/language/blob/master/accepted/2.8/language-versioning/package-config-file-v2.md).

A Dart package configuration file is used to resolve Dart package names (e.g.
`foobar`) to Dart files containing the source code for that package (e.g.
`file:///Users/myuser/.pub-cache/hosted/pub.dartlang.org/foobar-1.1.0`). The
standard package configuration file is `.dart_tool/package_config.json`, and is
written by the Dart tool when the command `dart pub get` is run.

The primary libraries of this package are
* `package_config.dart`:
    Defines the `PackageConfig` class and other types needed to use
    package configurations, and provides functions to find, read and
    write package configuration files.

* `package_config_types.dart`:
    Just the `PackageConfig` class and other types needed to use
    package configurations. This library does not depend on `dart:io`.

The package includes deprecated backwards compatible functionality to
work with the `.packages` file. This functionality will not be maintained,
and will be removed in a future version of this package.
