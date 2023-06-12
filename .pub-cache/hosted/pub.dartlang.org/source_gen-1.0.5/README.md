<p align="center">
  <a href="https://travis-ci.org/dart-lang/source_gen">
    <img src="https://travis-ci.org/dart-lang/source_gen.svg?branch=master" alt="Build Status" />
  </a>
  <a href="https://pub.dev/packages/source_gen">
    <img src="https://img.shields.io/pub/v/source_gen.svg" alt="Pub Package Version" />
  </a>
  <a href="https://gitter.im/dart-lang/build">
    <img src="https://badges.gitter.im/dart-lang/build.svg" alt="Join the chat on Gitter" />
  </a>
</p>

## Overview

`source_gen` provides utilities for automated source code generation for Dart:

* A **framework** for writing Builders that consume and produce Dart code.
* A **convention** for human and tool generated Dart code to coexist with clean
  separation, and for multiple code generators to integrate in the same project.

It's main purpose is to expose a developer-friendly API on top of lower-level
packages like the [analyzer][] or [build][]. You don't _have_ to use
`source_gen` in order to generate source code; we also expose a set of library
APIs that might be useful in your generators.

## Quick Start Guide for writing a Generator

Add a dependency on `source_gen` in your pubspec.

```yaml
dependencies:
  source_gen:
```

If you're only using `source_gen` in your own project to generate code and you
won't publish your Generator for others to use, it can be a `dev_dependency`:

```yaml
dev_dependencies:
  source_gen:
```

Once you have `source_gen` setup, you should reference the examples below.

### Writing a generator to output Dart source code

Extend the `Generator` or `GeneratorForAnnotation` class and `source_gen` will
call your generator for a Dart library or for each element within a library
tagged with the annotation you are interested in.

* [Trivial example][]
* [Full example package][] with [example usage][].

### Configuring and Running generators

`source_gen` is based on the [build][] package and exposes options for using
your `Generator` in a `Builder`. Choose a Builder based on where you want the
generated code to end up:

- If you want to write to `.g.dart` files which are referenced as a `part` in
  the original source file, use `SharedPartBuilder`. This is the convention for
  generated code in part files, and this file may also contain code from
  `Generator`s provided by other packages.
- If you want to write to `.some_name.dart` files which are referenced as a
  `part` in the original source file, use `PartBuilder`. You should choose an
  extension unique to your package. Multiple `Generator`s may output to this
  file, but they will all come from your package and you will set up the entire
  list when constructing the builder.
- If you want to write standalone Dart library which can be `import`ed use
  `LibraryBuilder`. Only a single `Generator` may be used as a `LibraryBuilder`.

In order to get the `Builder` used with [build_runner][] it must be configured
in a `build.yaml` file. See [build_config][] for more details. Whenever you are
publishing a package that includes a `build.yaml` file you should include a
dependency on `build_config` in your pubspec.

When using `SharedPartBuilder` it should always be configured to `build_to:
cache` (hidden files) and apply the `combining_builder` from this package. The
combining builder reads in all the pieces written by different shared part
builders and writes them to the final `.g.dart` output in the user's source
directory. You should never use the `.g.dart` extension for any other Builder.

```yaml
builders:
  some_cool_builder:
    import: "package:this_package/builder.dart"
    builder_factories: ["someCoolBuilder"]
    # The `partId` argument to `SharedPartBuilder` is "some_cool_builder"
    build_extensions: {".dart": [".some_cool_builder.g.part"]}
    auto_apply: dependents
    build_to: cache
    # To copy the `.g.part` content into `.g.dart` in the source tree
    applies_builders: ["source_gen|combining_builder"]
```

### Configuring `combining_builder` `ignore_for_file`

Sometimes generated code does not support all of the
[lints](https://dart-lang.github.io/linter/) specified in the target package.
When using a `Builder` based on `package:source_gen` which applies
`combining_builder`, set the `ignore_for_file` option to a list of lints you
wish to be ignored in all generated libraries.

_Example `build.yaml` configuration:_

```yaml
targets:
  $default:
    builders:
      source_gen|combining_builder:
        options:
          ignore_for_file:
          - lint_alpha
          - lint_beta
```

If you provide a builder that uses `SharedPartBuilder` and `combining_builder`,
you should document this feature for your users.

## FAQ

### What is the difference between `source_gen` and [build][]?

Build is a platform-agnostic framework for Dart asset or code generation that
is pluggable into build systems including [bazel][bazel_codegen], and
standalone tools like [build_runner][]. You could also build your own.

Meanwhile, `source_gen` provides an API and tooling that is easily usable on
top of `build` to make common tasks easier and more developer friendly. For
example the [`PartBuilder`][api:PartBuilder] class wraps one or more
[`Generator`][api:Generator] instances to make a [`Builder`][api:Builder] which
creates `part of` files, while the [`LibraryBuilder`][api:LibraryBuilder] class
wraps a single Generator to make a `Builder` which creates Dart library files.

<!-- Packages -->
[analyzer]: https://pub.dev/packages/analyzer
[bazel_codegen]: https://pub.dev/packages/_bazel_codegen
[build]: https://pub.dev/packages/build
[build_config]: https://pub.dev/packages/build_config
[build_runner]: https://pub.dev/packages/build_runner

<!-- Dartdoc -->
[api:Builder]: https://pub.dev/documentation/build/latest/build/Builder-class.html
[api:Generator]: https://pub.dev/documentation/source_gen/latest/source_gen/Generator-class.html
[api:PartBuilder]: https://pub.dev/documentation/source_gen/latest/source_gen/PartBuilder-class.html
[api:LibraryBuilder]: https://pub.dev/documentation/source_gen/latest/source_gen/LibraryBuilder-class.html

[Trivial example]: https://github.com/dart-lang/source_gen/blob/master/source_gen/test/src/comment_generator.dart
[Full example package]: https://github.com/dart-lang/source_gen/tree/master/example
[example usage]: https://github.com/dart-lang/source_gen/tree/master/example_usage
