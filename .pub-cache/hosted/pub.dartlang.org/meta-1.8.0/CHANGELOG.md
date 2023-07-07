## 1.8.0

* Add `@UseResult.unless`.
* The mechanism behind `noInline` and `tryInline` from `dart2js.dart` has been
  changed. This should not affect the use of these annotations in practice.

## 1.7.0

* Restore `TargetKindExtension` and `get displayString`.
  We published `analyzer 1.7.2` that is compatible with `TargetKindExtension`.

## 2.0.0 - removed

* Restore `TargetKindExtension` and `get displayString`.

## 1.6.0

* Remove `TargetKindExtension`. Adding it was a breaking change, because there
  are clients, e.g. `analyze 1.7.0`, that also declare an extension on
  `TargetKind`, and also declare `get displayString`. This causes a conflict.

## 1.5.0

* Add `TargetKindExtension.displayString`.

## 1.4.0

* Introduce `TargetKind.topLevelVariable` that indicates that an annotation
  is valid on any top-level variable declaration.
* Introduce `@useResult` to annotate methods, fields, or getters that
  return values that should be used - stored, passed as arguments, etc.
* Updates for documentation.

## 1.3.0

* Stable release for null safety.

## 1.3.0-nullsafety.6

* Update SDK constraints to `>=2.12.0-0 <3.0.0` based on beta release
    guidelines.

## 1.3.0-nullsafety.5

* Allow prerelease versions of the `2.12` sdk.

## 1.3.0-nullsafety.4

* Introduce `@internal` to annotate elements that should not be used outside of
  the package in which the element is declared.

## 1.3.0-nullsafety.3

* Allow 2.10 stable and 2.11.0 dev SDK versions.

## 1.3.0-nullsafety.2

* Update for the 2.10 dev sdk.

## 1.3.0-nullsafety.1

* Allow the <=2.9.10 stable sdk.

## 1.3.0-nullsafety

* Opt into null safety.

## 1.2.2

* Removed `unawaited` because the attempt to move it from `package:pedantic`
  caused too many issues. If you see errors about `unawaited` being declared in
  two places, please update the version constraints for `meta` to `1.2.2` or
  later.

## 1.2.1

* Fixed a bug by adding an import of dart:async so that the code really is
  compatible with the lower bound of the SDK constraints.

## 1.2.0

* Introduce `unawaited` to mark invocations that return a `Future` where it's
  intentional that the future is not being awaited. (Moved from
  `package:pedantic`.)
* Introduce `@doNotStore` to annotate methods, getters and functions to
  indicate that values obtained by invoking them should not be stored in a
  field or top-level variable.

## 1.1.8

* Introduce `@nonVirtual` to annotate instance members that should not be
  overridden in subclasses or when mixed in.

## 1.1.7

* Introduce `@sealed` to declare that a class or mixin is not allowed as a
  super-type.

  Only classes in the same package as a class or mixin annotated with `@sealed`
  may extend, implement or mix-in the annotated class or mixin. (SDK issue
  [27372](https://github.com/dart-lang/sdk/issues/27372)).

## 1.1.6

* Set max SDK version to <3.0.0.

## 1.1.5

* Introduce @isTest and @isTestGroup to declare a function that is a
  test, or a test group.

## 1.1.4

* Added dart2js.dart.

## 1.1.2

* Rollback SDK constraint update for 2.0.0. No longer needed.

## 1.1.1

* Update SDK constraint to be 2.0.0 dev friendly.

## 1.1.0

* Introduce `@alwaysThrows` to declare that a function always throws
    (SDK issue [17999](https://github.com/dart-lang/sdk/issues/17999)). This
    is first available in Dart SDK 1.25.0-dev.1.0.

    ```dart
    import 'package:meta/meta.dart';

    // Without knowing that [failBigTime] always throws, it looks like this
    // function might return without returning a bool.
    bool fn(expected, actual) {
      if (expected != actual)
        failBigTime(expected, actual);
      else
        return True;
    }

    @alwaysThrows
    void failBigTime(expected, actual) {
      throw new StateError('Expected $expected, but was $actual.');
    }
    ```

## 1.0.5

* Introduce `@experimental` to annotate a library, or any declaration that is
  part of the public interface of a library (such as top-level members, class
  members, and function parameters) to indicate that the annotated API is
  experimental and may be removed or changed at any-time without updating the
  version of the containing package, despite the fact that it would otherwise
  be a breaking change.

## 1.0.4

* Introduce `@virtual` to allow field overrides in strong mode
    (SDK issue [27384](https://github.com/dart-lang/sdk/issues/27384)).

    ```dart
    import 'package:meta/meta.dart' show virtual;
    class Base {
      @virtual int x;
    }
    class Derived extends Base {
      int x;

      // Expose the hidden storage slot:
      int get superX => super.x;
      set superX(int v) { super.x = v; }
    }
    ```

## 1.0.3

* Introduce `@checked` to override a method and tighten a parameter
    type (SDK issue [25578](https://github.com/dart-lang/sdk/issues/25578)).

    ```dart
    import 'package:meta/meta.dart' show checked;
    class View {
      addChild(View v) {}
    }
    class MyView extends View {
      // this override is legal, it will check at runtime if we actually
      // got a MyView.
      addChild(@checked MyView v) {}
    }
    main() {
      dynamic mv = new MyView();
      mv.addChild(new View()); // runtime error
    }
    ```

## 1.0.2

* Introduce `@visibleForTesting` annotation for declarations that may be referenced only in the library or in a test.

## 1.0.1

* Updated `@factory` to allow statics and methods returning `null`.

## 1.0.0

* First stable API release.

## 0.12.2

* Updated `@protected` to include implemented interfaces (linter#252).

## 0.12.1

* Fixed markdown in dartdocs.

## 0.12.0

* Introduce `@optionalTypeArgs` annotation for classes whose type arguments are to be treated as optional.

## 0.11.0

* Added new `Required` constructor with a means to specify a reason to explain why a parameter is required.

## 0.10.0

* Introduce `@factory` annotation for methods that must either be abstract or must return a newly allocated object.
* Introduce `@literal` annotation that indicates that any invocation of a
constructor must use the keyword `const` unless one or more of the
arguments to the constructor is not a compile-time constant.

## 0.9.0

* Introduce `@protected` annotation for members that must only be called from
instance members of subclasses.
* Introduce `@required` annotation for optional parameters that should be treated
as required.
* Introduce `@mustCallSuper` annotation for methods that must be invoked by all
overriding methods.
