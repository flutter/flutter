Defines the basic pieces of how a build happens and how they interact.

## [`Builder`][dartdoc:Builder]

The business logic for code generation. Most consumers of the `build` package
will create custom implementations of `Builder`.

## [`BuildStep`][dartdoc:BuildStep]

The way a `Builder` interacts with the outside world. Defines the unit of work
and allows reading/writing files and resolving Dart source code.

## [`Resolver`][dartdoc:Resolver] class

An interface into the dart [analyzer][pub:analyzer] to allow resolution of code
that needs static analysis and/or code generation.

## Implementing your own Builders

A `Builder` gets invoked one by one on it's inputs, and may read other files and
output new files based on those inputs.

The basic API looks like this:

```dart
abstract class Builder {
  /// You can only output files that are configured here by suffix substitution.
  /// You are not required to output all of these files, but no other builder
  /// may declare the same outputs.
  Map<String, List<String>> get buildExtensions;

  /// This is where you build and output files.
  FutureOr<void> build(BuildStep buildStep);
}
```

Here is an implementation of a `Builder` which just copies files to other files
with the same name, but an additional extension:

```dart
import 'package:build/build.dart';

/// A really simple [Builder], it just makes copies of .txt files!
class CopyBuilder implements Builder {
  @override
  final buildExtensions = const {
    '.txt': ['.txt.copy']
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    // Each `buildStep` has a single input.
    var inputId = buildStep.inputId;

    // Create a new target `AssetId` based on the old one.
    var copy = inputId.addExtension('.copy');
    var contents = await buildStep.readAsString(inputId);

    // Write out the new asset.
    await buildStep.writeAsString(copy, contents);
  }
}
```

It should be noted that you should _never_ touch the file system directly. Go
through the `buildStep#readAsString` and `buildStep#writeAsString` methods in
order to read and write assets. This is what enables the package to track all of
your dependencies and do incremental rebuilds. It is also what enables your
[`Builder`][dartdoc:Builder] to run on different environments.

### Using the analyzer

If you need to do analyzer resolution, you can use the `BuildStep#resolver`
object. This makes sure that all `Builder`s in the system share the same
analysis context, which greatly speeds up the overall system when multiple
`Builder`s are doing resolution.

Here is an example of a `Builder` which uses the `resolve` method:

```dart
import 'package:build/build.dart';

class ResolvingCopyBuilder implements Builder {
  // Take a `.dart` file as input so that the Resolver has code to resolve
  @override
  final buildExtensions = const {
    '.dart': ['.dart.copy']
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    // Get the `LibraryElement` for the primary input.
    var entryLib = await buildStep.inputLibrary;
    // Resolves all libraries reachable from the primary input.
    var resolver = buildStep.resolver;
    // Get a `LibraryElement` for another asset.
    var libFromAsset = await resolver.libraryFor(
        AssetId.resolve(Uri.parse('some_import.dart'),
        from: buildStep.inputId));
    // Or get a `LibraryElement` by name.
    var libByName = await resolver.findLibraryByName('my.library');
  }
}
```

Once you have gotten a `LibraryElement` using one of the methods on `Resolver`,
you are now just using the regular `analyzer` package to explore your app.

### Sharing expensive objects across build steps

The build package includes a `Resource` class, which can give you an instance
of an expensive object that is guaranteed to be unique across builds, but may
be re-used by multiple build steps within a single build (to the extent that
the implementation allows). It also gives you a way of disposing of your
resource at the end of its lifecycle.

The `Resource<T>` constructor takes a single required argument which is a
factory function that returns a `FutureOr<T>`. There is also a named argument
`dispose` which is called at the end of life for the resource, with the
instance that should be disposed. This returns a `FutureOr<dynamic>`.

So a simple example `Resource` would look like this:

```dart
final resource = Resource(
  () => createMyExpensiveResource(),
  dispose: (instance) async {
    await instance.doSomeCleanup();
  });
```

You can get an instance of the underlying resource by using the
`BuildStep#fetchResource` method, whose type signature looks like
`Future<T> fetchResource<T>(Resource<T>)`.

**Important Note**: It may be tempting to try and use a `Resource` instance to
cache information from previous build steps (or even assets), but this should
be avoided because it can break the soundness of the build, and may introduce
subtle bugs for incremental builds (remember the whole build doesn't run every
time!). The `build` package relies on the `BuildStep#canRead` and
`BuildStep#readAs*` methods to track build step dependencies, so sidestepping
those can and will break the dependency tracking, resulting in inconsistent and
stale assets.

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/dart-lang/build/issues

[dartdoc:Builder]: https://pub.dev/documentation/build/latest/build/Builder-class.html
[dartdoc:BuildStep]: https://pub.dev/documentation/build/latest/build/BuildStep-class.html
[dartdoc:Resolver]: https://pub.dev/documentation/build/latest/build/Resolver-class.html
[pub:analyzer]: https://pub.dev/packages/analyzer
