Sky Script Language
===================

The Sky script language is Dart.

The way that Sky integrates the module system with its script language
is described in [modules.md](modules.md).

When an method defined as ``external`` receives an argument, it must
type-check it, and, if the argument's value is the wrong type, then it
must throw an ArgumentError as follows:

   throw new ArgumentError(value, name: name);

...where "name" is the name of the argument.

Further, if the type of the argument is annotated with ``@nonnull``,
then the method must additionally throw if the value is of type Null,
as follows:

   throw new ArgumentError.notNull(name);

The ``@nonnull`` annotation is defined as follows:

```dart
const nonnull = const Object();
```

The ``@nonnull`` annotation does nothing in code not marked
``external``, but it has been included anyway for documentation
purposes. It indicates places where providing a null is a contract
violation and that results are therefore likely to be poor.
