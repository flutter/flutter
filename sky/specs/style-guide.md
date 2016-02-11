Flutter Style Guide
===================

In general, follow our [Design Principles](design.md) for all code.

The primary goal of this style guide is to improve code readability so
that everyone, whether reading the code for the first time or
maintaining it for years, can quickly determine what the code does. A
secondary goal is avoiding arguments when there are disagreements.

All languages
-------------

Avoid checking in commented-out code. It will bitrot too fast to be
useful, and will confuse people maintaining the code.

Avoid checking in comments that ask questions (like "What should this
be?"). Find the answers to the questions, or describe the confusion,
including references to where you found answers. ("According to this
specification, this should be 2.0, but according to that
specification, it should be 3.0. We split the difference and went with
2.5, because we didn't know what else to do.")




Dart
----

In general, follow the [Dart style
guide](https://www.dartlang.org/articles/style-guide/) for Dart code,
except where that would contradict this page. (`dartfmt` [doesn't yet
support](https://github.com/dart-lang/dart_style/issues/442) our style
rules, so avoid using that for now.)

Always use the Dart Analyzer. Avoid checking in code that increases
the output of the analyzer unless you've filed a bug with the Dart
team. (Use `flutter analyze` to run the analyzer on Flutter code.)

Use assert()s liberally to describe the contracts that you expect your
code to follow.


Types (i.e. classes, typedefs (function signature definitions) and
enums) are named UpperCamelCase. Everything else (methods, fields,
variables, constants, enum values, etc) is lowerCamelCase. Constant
doubles and strings are prefixed with k. Prefer using a local const
or a static const in a relevant class than using a global constant.

When naming callbacks, use `FooCallback` for the typedef, `onFoo` for
the callback argument or property, and `handleFoo` for the method
that is called.

If you have a callback with arguments but you want to ignore the
arguments, name them `_`, `__`, `___`, etc. If you name any of them,
name all of them. Always be explicit with the types of variables in
callbacks unless you are ignoring them (and have named them with
underscores).

If you have variables or methods that are only used in checked mode,
prefix their names with `debug` or `_debug`.

Avoid naming your libraries (no ```library``` keyword), unless it's a
documented top-level library, like `painting.dart`. Name the files in
```lower_under_score.dart``` format.


Class constructors and methods should be ordered in the order that
their members will be used in an instance's typical lifecycle. In
particular, this means constructors all come first in class
declarations.

The default (unnamed) constructor should come first, then the named
constructors.

If you call super() in your initialiser list, put a space between the
constructor arguments closing parenthesis and the colon. If there's
other things in the initialiser list, align the super() call with the
other arguments. Don't call super if you have no arguments to pass up
to the superclass.

```dart
class Foo extends Bar {
  Foo({ this._argument, baz }) : super(baz: baz);
}

class Quuz extends Bar {
  Quuz({
    TheType argument, baz
  }) : _argument = argument,
       super(
    baz: baz
  );
}
```

Fields should come before the methods that manipulate them, if they
are specific to a particular group of methods.

> For example, RenderObject groups all the layout fields and layout
> methods together, then all the paint fields and paint methods.

Fields that aren't specific to a particular group of methods should
come immediately after the constructors.

Be consistent in the order of members. If a constructor lists a bunch
of fields, then those fields should declared be in the same order, and
any code that operates on all of them should operate on them in the
same order (unless the order matters).


All variables and arguments are typed; avoid "dynamic" or "Object" in
any case where you could figure out the actual type. Always specialise
generic types where possible. Explicitly type all array and map
literals.

Always avoid "var". Use "dynamic" if you are being explicit that the
type is unknown. Use "Object" if you are being explicit that you want
an object that implements `==` and `hashCode`.

Avoid using "as". If you know the type is correct, use an assertion or
assign to a more narrowly-typed variable (this avoids the type check
in release mode; "as" is not compiled out in release mode). If you
don't know whether the type is correct, check using "is" (this avoids
the exception that "as" raises).


Aim for a line length of 80 characters, but go over if breaking the
line would make it less readable. When wrapping lines, avoid doing so
around assignment operators. Indent the next line by two characters
or align the expressions, whichever makes the code more readable.

When breaking an argument list into multiple lines, indent the
arguments two characters from the previous line.

> Example:
> ```dart
> Foo f = new Foo(
>   bar: 1.0,
>   quux: 2.0
> );
> ```

When breaking a parameter list into multiple lines, do the same.

Use `//` and `///`, not `/* */` and `/** */`.

Prefer single quotes for strings. Use double quotes for nested
strings.

> Example:
> ```dart
>   print('Hello ${name.split(" ")[0]}');
> ```

Only use => when the result fits on a single line.

When using ```{ }``` braces, put a space or a newline after the open
brace and before the closing brace. (If the block is empty, the same
space will suffice for both.) Use spaces if the whole block fits on
one line, and newlines if you need to break it over multiple lines.
Use the `{}` expression (without a space in the middle) for the empty Map
literal (but type it, so it looks like `<Foo, Bar>{}`).

Don't put the statement part of an "if" statement on the same line as
the expression, even if it is short. (Doing so makes it unobvious that
there is relevant code there. This is especially important for early
returns.)

If a flow control structure's statement is one line long, then don't
use braces around it, unless it's part of an "if" chain and any of the
other blocks have more than one line. (Keeping the code free of
boilerplate or redundant punctuation keeps it concise and readable.
The analyzer will catch "goto fail"-style errors with its dead-code
detection.)

> For example,
> ```dart
>   if (children != null) {
>     for (RenderBox child in children)
>       add(child);
>   }
> ```
> ...rather than:
> ```dart
>   if (children != null) {
>     for (RenderBox child in children) {
>       add(child);
>     }
>   }
> ```

> For example:
> ```dart
>   if (a != null)
>     a()
>   else if (b != null)
>     b()
>   else
>     c()
> ```
> ...but:
> ```dart
>   if (a != null) {
>     a()
>   } else if (b != null) {
>     b()
>   } else {
>     c()
>     d()
>   }
> ```

Use a switch if you are examining an enum (and avoid using "if" chains
with enums), since the analyzer will warn you if you missed any of the
values when you use a switch.

Use the most relevant constructor or method, when there are multiple
options.

> For example,
> ```dart
>    new EdgeDims.symmetric(horizontal: 8.0);
> ```
> ...rather than:
> ```dart
>    new EdgeDims.TRBL(0.0, 8.0, 0.0, 8.0);
> ```


Use for-in loops rather than forEach() where possible, since that
saves a stack frame per iteration.


When defining mutable properties that mark a class dirty when set, use
the following pattern:

```dart
/// Documentation here (don't wait for a later commit).
TheType get theProperty => _theProperty;
TheType _theProperty;
void set theProperty(TheType value) {
  assert(value != null);
  if (_theProperty == value)
    return;
  _theProperty = value;
  markNeedsWhatever(); // the method to mark the object dirty
}
```

The argument is called 'value' for ease of copy-and-paste reuse of
this pattern. If for some reason you don't want to use 'value', use
'newTheProperty' (where 'theProperty' is the property name).

Start the method with any asserts you need to validate the value.


### Packages

As per normal Dart conventions, a package should have a single import that reexports all of its API.

> For example, [rendering.dart](https://github.com/flutter/engine/blob/master/sky/packages/sky/lib/rendering.dart) exports all of lib/src/rendering/*.dart

If a package uses, as part of its exposed API, types that it imports from a lower layer, it should reexport those types.

> For example, [material.dart](https://github.com/flutter/engine/blob/master/sky/packages/sky/lib/material.dart) reexports everything from [widgets.dart](https://github.com/flutter/engine/blob/master/sky/packages/sky/lib/widgets.dart). Similarly, the latter [reexports](https://github.com/flutter/engine/blob/master/sky/packages/sky/lib/src/widgets/basic.dart) many types from [rendering.dart](https://github.com/flutter/engine/blob/master/sky/packages/sky/lib/rendering.dart), such as `BoxConstraints`, that it uses in its API. On the other hand, it does not reexport, say, `RenderProxyBox`, since that is not part of the widgets API.

For the `rendering.dart` library, if you are creating new `RenderObject` subclasses, import the entire library. If you are only referencing specific `RenderObject` subclasses, then import the `rendering.dart` library with a `show` keyword explicitly listing the types you are importing. This latter approach is generally good for documenting why exactly you are importing particularly libraries and can be used more generally when importing large libraries for very narrow purposes.

By convention, `dart:ui` is imported using `import 'dart:ui' show ...;` for common APIs (this isn't usually necessary because a lower level will have done it for you), and as `import 'dart:ui' as ui show ...;` for low-level APIs, in both cases listing all the identifiers being imported. See [basic_types.dart](https://github.com/flutter/flutter/blob/master/packages/flutter/lib/src/painting/basic_types.dart) in the `painting` package for details of which identifiers we import which way. Other packages are usually imported undecorated unless they have a convention of their own (e.g. `path` is imported `as path`).

As a general rule, when you have a lot of constants, wrap them in a class. For examples of this, see [lib/src/material/colors.dart](https://github.com/flutter/flutter/blob/master/packages/flutter/lib/src/material/colors.dart)


C++
---

Put spaces around operators in expressions.


Java
----


Objective C
-----------
