The rule for packages in this directory is that they can depend on
nothing but core Dart packages. They can't depend on `dart:ui`, they
can't depend on any `package:`, and they can't depend on anything
outside this directory.
