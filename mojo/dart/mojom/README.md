mojom
====

This package is a placeholder for generated mojom bindings.

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
