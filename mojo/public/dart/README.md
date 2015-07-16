Dart Mojo Applications
====

## Mojo Application API

*TODO(zra)*

## Application Packaging

All Dart sources for a Mojo application are collected in a specially formatted
zip file, which is understood by Dart's content handler in the Mojo shell.
This section describes what the various parts of that package are, and how they
all make it to the right place.

### GN Template

Dart Mojo applications are built with the GN template
'dartzip_packaged_application' defined in `//mojo/public/dart/rules.gni`.
Here is an example:


```
dartzip_packaged_application("foo") {
  output_name = "dart_foo"
  uses_pub = true
  sources = [
    "main.dart",
    "foo.dart",
  ]
  deps = [
    "//mojo/public/dart",
    "//mojo/services/network/public/interfaces",
  ]
}
```

There are several parts:
* `output_name` is the name of the resulting .mojo file if it should be
  different from the name of the target. (In this case we get dart_foo.mojo
  instead of foo.mojo.)
* `uses_pub` should be true when the application depends on Dart packages pulled
  down from pub. The application should have `pubspec.yaml` and `pubspec.lock`
  files adjacent to `main.dart`. More on this below.
* `sources` is the list of Dart sources for the application. Each application
  **must** contain a `main.dart` file. `main.dart` must be the library entry
  point, and must contain the `main()` function.
* `deps` has the usual meaning. In the example above,
  `//mojo/services/network/public/interfaces` indicates that the "foo"
  application uses the Dart bindings generated for the network service.

### pub packages

Dart Mojo applications may use packages from the pub package repository at
pub.dartlang.org.

The "foo" example above has `uses_pub` set to true. Suppose its `pubspec.yaml`
is as follows:

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

During the build, The `dartzip_packaged_application` rule looks for a
"packages/" directory, and copies its contents into the zip file.

### Generated bindings

The script `//mojo/public/tools/bindings/generators/mojom_dart_generator.py`
and the templates under `//mojo/public/tools/bindings/generators/dart_templates`
govern how `.mojom` files are compiled into Dart code.

Consider the `network_error.mojom` file from the network services used by our
"foo" example:

```
module mojo;

struct NetworkError {
  int32 code;
  string? description;
};
```

This contents of this file are in the `mojo` module. The Dart source generated
for this file will end up under, e.g.
`//out/Debug/gen/dart-gen/mojom/mojo/network_error.mojom.dart`, along with the
other Dart sources generated for `.mojom` files in the `mojo` module.

### Resulting layout

They layout for our "foo" example will be the following:

```
//main.dart
//foo.dart
//crypto/...  # Dart's crypto pub package.
//mojo/public/dart/...  # Mojo SDK Dart libraries.
//mojom/mojo/...  # Generated bindings in the mojo module.
```

Where `//mojo/public/dart` contains Dart's Mojo bindings, `//crypto` contains
the `crypto` pub package, and `//mojom/mojo` contains the generated bindings in
the mojom module for the network service.

Mojo's Dart content handler sets the package root for a Dart application to be
the root directory of the unpacked zip file. Therefore, Dart sources in this
application can use the following imports:

```dart
import 'package:crypto/crypto.dart';
import 'package:mojo/public/dart/application.dart';
import 'package:mojom/mojo/network_error.mojom.dart';
```
