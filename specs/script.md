Sky Script Language
===================

The Sky script language is Dart.

The way that Sky integrates the module system with its script language
is described in [modules.md](modules.md).

All the APIs defined in this documentation, unless explicitly called
out as being in a framework, are in the `dart:sky` built-in module.

When a method in `dart:sky` defined as ``external`` receives an
argument, it must type-check it, and, if the argument's value is the
wrong type, then it must throw an ArgumentError as follows:

   throw new ArgumentError(value, name: name);

...where "name" is the name of the argument. Type checking here
includes rejecting nulls unless otherwise indicated or unless null is
argument's default value.

The following definitions are exposed in ``dart:sky``:

```dart
import 'dart:mirrors';

abstract class AutomaticMetadata {
  const AutomaticMetadata();
  void init(DeclarationMirror target, Module module);

  static void runLibrary(LibraryMirror library, Module module) {
    library.declarations.values.toList() /* ..sort((DeclarationMirror a, DeclarationMirror b) {
      bool aHasLocation;
      try {
        aHasLocation = a.location != null;
      } catch(e) {
        aHasLocation = false;
      }
      bool bHasLocation;
      try {
        bHasLocation = b.location != null;
      } catch(e) {
        bHasLocation = false;
      }
      if (!aHasLocation)
        return bHasLocation ? 1 : 0;
      if (!bHasLocation)
        return -1;
      if (a.location.sourceUri != b.location.sourceUri)
        return a.location.sourceUri.toString().compareTo(b.location.sourceUri.toString());
      if (a.location.line != b.location.line)
        return a.location.line - b.location.line;
      return a.location.column - b.location.column;
    }) */
    ..forEach((DeclarationMirror d) {
      d.metadata.forEach((InstanceMirror i) {
        if (i.reflectee is AutomaticMetadata)
          i.reflectee.run(d, module);
      });
    });
  }
}

class AutomaticFunction extends AutomaticMetadata {
  const AutomaticFunction();
  void init(DeclarationMirror target, Module module) {
    assert(target is MethodMirror);
    MethodMirror f = target as MethodMirror;
    assert(!f.isAbstract);
    assert(f.isRegularMethod);
    assert(f.isTopLevel);
    assert(f.isStatic);
    assert(f.parameters.length == 0);
    assert(f.returnType == currentMirrorSystem().voidType);
    (f.owner as LibraryMirror).invoke(f.simpleName, []);
  }
}
const autorun = const AutomaticFunction();
```

Extensions
----------

The following as-yet unimplemented features of the Dart language are
assumed to exist:

* It is assumed that a subclass can define a constructor by reference
  to a superclass' constructor, wherein the subclass' constructor has
  the same arguments as the superclass' constructor and does nothing
  but invoke that superclass' constructor with the same arguments. The
  syntax for defining this is, within the class body for a class
  called ClassName:

```dart
     ClassName = SuperclassName;
     ClassName.namedConstructor = SuperclassName.otherNamedConstructor;
```

* The reflection APIs (`dart:mirrors`) are assumed to reflect a
  library's declarations in source order.
