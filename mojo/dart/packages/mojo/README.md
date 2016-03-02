Dart Mojo Applications
====

## Mojo Application API

*TODO(zra)*

## Application Packaging

All Dart sources for a Mojo application are collected in a specially formatted
snapshot file, which is understood by Dart's content handler in the Mojo shell.
This section describes what the various parts of that package are, and how they
all make it to the right place.

### GN Template

Dart Mojo applications are built with the GN template 'dart_pkg' defined in
`//mojo/public/dart/rules.gni`. Here is an example:


```
dart_pkg("foo") {
  app_name_override = "dart_foo"
  app = "lib/main.dart"
  sources = [
    "lib/foo.dart",
    "pubspec.yaml",
  ]
  deps = [
    ":foo_mojom",
    "//third_party/dart-pkg",
  ]
}

mojom("foo_mojom") {
  sources = [
    "foo.mojom",
  ]
}
```

There are several parts. See the documentation in `//mojo/public/dart/rules.gni`
for all the details.

### pub packages

Dart Mojo applications may use packages from the pub package repository at
pub.dartlang.org.

The "foo" example above has `uses_pub` set to true. Suppose the "foo" package's
`pubspec.yaml` is as follows:

```
name: foo
version: 0.0.1
description: Foo
dependencies:
  crypto: ">=0.9.0 <0.10.0"
```

The script `//mojo/public/tools/git/dart_pub_get.py` should be run before build
time, e.g. as a "runhooks" action during `gclient sync`. The script traverses
a directory tree looking for `pubspec.yaml` files. On finding one, in the
containing directory, it runs `pub get`. This creates a "packages/" directory
in the source tree adjacent to the `pubspec.yaml` file containing the downloaded
Dart packages. `pub get` also creates a `pubspec.lock` file that locks down
pub packages to specific versions. This `pubspec.lock` file must be checked in
in order to have hermetic builds.

During the build, The `dart_pkg` rule looks for a "packages/" directory, and
ensures that its contents are available when running the application.

### Generated bindings

The script `//mojo/public/tools/bindings/generators/mojom_dart_generator.py`
and the templates under `//mojo/public/tools/bindings/generators/dart_templates`
govern how `.mojom` files are compiled into Dart code.

Consider the `foo.mojom` file used by our example:

```
[DartPackage="foo"]
module foo;

struct Foo {
  int32 code;
  string? description;
};
```

This contents of this file are in the `foo` module. The Dart source generated
for this file will end up under, e.g. `//out/Debug/gen/dart-
pkg/foo/lib/foo/network_error.mojom.dart`, along with the other Dart sources
generated for `.mojom` files with the "foo" `DartPackage` annotation in the
`foo` module.

### Resulting file

The `dart_pkg` rule has two results. The first result is a Dart snapshot file
zipped up into a .mojo file in the build output directory---something like
`//out/Release/foo.mojo`. This file is understood by the Dart content handler
and is suitable for deployment. The second result is a directory layout of the
"foo" app that can be served by a webserver. When the URL of `lib/main.dart` is
given to the `mojo_shell`, the app will be run in the Dart content handler.

They layout for our "foo" example will be the following:

```
//lib/main.dart
//lib/foo.dart
//lib/foo/foo.mojom.dart
//packages/crypto/...  # Dart's crypto pub package.
//packages/mojo/...  # Mojo SDK Dart libraries.
```

Where `//packages/mojo` contains Dart's Mojo bindings, `//packages/crypto`
contains the `crypto` pub package, and `//lib/foo/` contains the bindings
generated for `foo.mojom`.

Mojo's Dart content handler sets the package root for a Dart application to be
the packages directory. Therefore, Dart sources in this application can use the
following imports:

```dart
import 'package:crypto/crypto.dart';
import 'package:foo/foo/foo.mojom.dart';
import 'package:mojo/application.dart';
```
