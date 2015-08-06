mojom
====

This package is a placeholder for generated mojom bindings. It contains a script
lib/generate.dart.

This script generates Mojo bindings for a Dart package. Dart packages will be
populated according to the DartPackage annotations in .mojom files. Any .mojom
files that don't have an annotation will have their bindings generated into a
local copy of the 'mojom' package. Annotations specifying the host package will
cause generation into the host package's lib/ directory. For every other
DartPackage annotation, the bindings will be generated into the named package,
either into the global package cache if a package of that name has already been
fetched, or into a local directory created under the current package's packages/
directory.

Generated Mojo bindings in other pub packages should be installed into this
package by saying the following after `pub get`:

```
$ dart -p packages packages/mojom/generate.dart
```
If desired, additional directories holding .mojom.dart files can be specified;
their contents will be installed to this package as well:

```
$ dart -p packages packages/mojom/generate.dart -a </path/to/mojom/dir>
```

Full options:

```
$ dart packages/mojom/generate.dart [-p package-root]
                                    [-a additional-dirs]
                                    [-m mojo-sdk]
                                    [-g]  # Generate from .mojom files
                                    [-d]  # Download from .mojoms files
                                    [-i]  # Ignore duplicates
                                    [-v]  # verbose
                                    [-f]  # Fake (dry) run
```
