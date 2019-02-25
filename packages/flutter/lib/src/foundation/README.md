The rule for packages in this directory is that they can depend on
nothing but core Dart packages. They can't depend on `dart:ui`, they
can't depend on any `package:`, and they can't depend on anything
outside this directory.

Currently they do depend on dart:ui, but only for `VoidCallback` and
`hashValues` (and maybe one day `hashList` and `lerpDouble`), which
are all intended to be moved out of `dart:ui` and into `dart:core`.

See also:

 * https://github.com/dart-lang/sdk/issues/27791 (`VoidCallback`)
 * https://github.com/dart-lang/sdk/issues/25217 (`hashValues`, `hashList`, and `lerpDouble`)
