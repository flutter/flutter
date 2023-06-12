## 3.7.0

* Add support for converting a Method to a generic closure, with
  `Method.genericClosure`.

## 3.6.0

* Add support for creating `extension` methods.
* Expand constraint on `built_value` to allow null safe migrated version.

## 3.5.0

* Add support for defining enums.
* Fix keyword ordering for `const factory` constructors.

## 3.4.1

* Fix confusing mismatch description from `equalsDart`.
  https://github.com/dart-lang/code_builder/issues/293

## 3.4.0

* Introduce `Expression.thrown` for throwing an expression.
* Introduce `FunctionType.isNullable`.
* Update SDK requirement to `>=2.7.0 <3.0.0`.

## 3.3.0

* Add `??` null-aware operator.
* Add `..` cascade assignment operator.
* Add `part` directive.
* Introduce `TypeReference.isNullable`.
* Add an option in `DartEmitter` to emit nullable types with trailing `?`
  characters.

## 3.2.2

* Require minimum Dart SDK of `2.6.0`.

## 3.2.1

* Escape newlines in String literals.
* Introduce `Expression.or` for boolean OR.
* Introduce `Expression.negate` for boolean NOT.
* No longer emits redundant `,`s in `FunctionType`s.
* Added support for `literalSet` and `literalConstSet`.
* Depend on the latest `package:built_value`.

## 3.2.0

* Emit `=` instead of `:` for named parameter default values.
* The `new` keyword will not be used in generated code.
* The `const` keyword will be omitted when it can be inferred.
* Add an option in `DartEmitter` to order directives.
* `DartEmitter` added a `startConstCode` function to track the creation of
  constant expression trees.
* `BinaryExpression` added the `final bool isConst` field.

## 3.1.3

* Bump dependency on built_collection to include v4.0.0.

## 3.1.2

* Set max SDK version to `<3.0.0`.

## 3.1.1

* `Expression.asA` is now wrapped with parenthesis so that further calls may be
  made on it as an expression.


## 3.1.0

* Added `Expression.asA` for creating explicit casts:

```dart
void main() {
  test('should emit an explicit cast', () {
    expect(
      refer('foo').asA(refer('String')),
      equalsDart('foo as String'),
    );
  });
}
```

## 3.0.3

* Fix a bug that caused all downstream users of `code_builder` to crash due to
  `build_runner` trying to import our private builder (in `tool/`). Sorry for
  the inconvenience.

## 3.0.2

* Require `source_gen: ^0.7.5`.

## 3.0.1

* Upgrade to `built_value` 5.1.0.
* Export the `literalNum` function.
* **BUG FIX**: `literal` supports a `Map`.

## 3.0.0

* Also infer `Constructor.lambda` for `factory` constructors.

## 3.0.0-alpha

* Using `equalsDart` no longer formats automatically with `dartfmt`.

* Removed deprecated `Annotation` and `File` classes.

* `Method.lambda` is inferred based on `Method.body` where possible and now
  defaults to `null`.

## 2.4.0

* Add `equalTo`, `notEqualTo`, `greaterThan`, `lessThan`, `greateOrEqualTo`, and
  `lessOrEqualTo` to `Expression`.

## 2.3.0

* Using `equalsDart` and expecting `dartfmt` by default is *deprecated*. This
  requires this package to have a direct dependency on specific versions of
  `dart_style` (and transitively `analyzer`), which is problematic just for
  testing infrastructure. To future proof, we've exposed the `EqualsDart` class
  with a `format` override:

```dart
// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';

final DartFormatter _dartfmt = new DartFormatter();
String _format(String source) {
  try {
    return _dartfmt.format(source);
  } on FormatException catch (_) {
    return _dartfmt.formatStatement(source);
  }
}

/// Should be invoked in `main()` of every test in `test/**_test.dart`.
void useDartfmt() => EqualsDart.format = _format;
```

* Added `Expression.isA` and `Expression.isNotA`:

```dart
void main() {
  test('should emit an is check', () {
    expect(
      refer('foo').isA(refer('String')),
      equalsDart('foo is String'),
    );
  });
}
```

* Deprecated `Annotation`. It is now legal to simply pass any `Expression` as
  a metadata annotation to `Class`, `Method`, `Field,` and `Parameter`. In
  `3.0.0`, the `Annotation` class will be completely removed:

```dart
void main() {
  test('should create a class with a annotated constructor', () {
    expect(
      new Class((b) => b
        ..name = 'Foo'
        ..constructors.add(
          new Constructor((b) => b..annotations.add(refer('deprecated'))))),
      equalsDart(r'''
        class Foo {
          @deprecated
          Foo();
        }
      '''),
    );
  });
}
```

* Added inference support for `Method.lambda` and `Constructor.lambda`. If not
  explicitly provided and the body of the function originated from an
  `Expression` then `lambda` is inferred to be true. This is not a breaking
  change yet, as it requires an explicit `null` value. In `3.0.0` this will be
  the default:

```dart
void main() {
  final animal = new Class((b) => b
    ..name = 'Animal'
    ..extend = refer('Organism')
    ..methods.add(new Method.returnsVoid((b) => b
      ..name = 'eat'
      // In 3.0.0, this may be omitted and still is inferred.
      ..lambda = null
      ..body = refer('print').call([literalString('Yum!')]).code)));
  final emitter = new DartEmitter();
  print(new DartFormatter().format('${animal.accept(emitter)}'));
}
```

* Added `nullSafeProperty` to `Expression` to access properties with `?.`
* Added `conditional` to `Expression` to use the ternary operator `? : `
* Methods taking `positionalArguments` accept `Iterable<Expression>`
* **BUG FIX**: Parameters can take a `FunctionType` as a `type`.
  `Reference.type` now returns a `Reference`. Note that this change is
  technically breaking but should not impacts most clients.

## 2.2.0

* Imports are prefixed with `_i1` rather than `_1` which satisfies the lint
  `lowercase_with_underscores`. While not a strictly breaking change you may
  have to fix/regenerate golden file-like tests. We added documentation that
  the specific prefix is not considered stable.

* Added `Expression.index` for accessing the `[]` operator:

```dart
void main() {
  test('should emit an index operator', () {
    expect(
      refer('bar').index(literalTrue).assignVar('foo').statement,
      equalsDart('var foo = bar[true];'),
    );
  });

  test('should emit an index operator set', () {
    expect(
      refer('bar')
        .index(literalTrue)
        .assign(literalFalse)
        .assignVar('foo')
        .statement,
      equalsDart('var foo = bar[true] = false;'),
    );
  });
}
```

* `literalList` accepts an `Iterable` argument.

* Fixed an NPE when a method had a return type of a `FunctionType`:

```dart
void main() {
  test('should create a method with a function type return type', () {
    expect(
      new Method((b) => b
        ..name = 'foo'
        ..returns = new FunctionType((b) => b
          ..returnType = refer('String')
          ..requiredParameters.addAll([
            refer('int'),
          ]))),
      equalsDart(r'''
        String Function(int) foo();
      '''),
    );
  });
}
```

## 2.1.0

We now require the Dart 2.0-dev branch SDK (`>= 2.0.0-dev`).

* Added support for raw `String` literals.
* Automatically escapes single quotes in now-raw `String` literals.
* Deprecated `File`, which is now a redirect to the preferred class, `Library`.

This helps avoid symbol clashes when used with `dart:io`, a popular library. It
is now safe to do the following and get full access to the `code_builder` API:

```dart
import 'dart:io';

import 'package:code_builder/code_builder.dart' hide File;
```

We will remove `File` in `3.0.0`, so use `Library` instead.

## 2.0.0

Re-released without a direct dependency on `package:analyzer`!

For users of the `1.x` branch of `code_builder`, this is a pretty big breaking
change but ultimately is for the better - it's easier to evolve this library
now and even add your own builders on top of the library.

```dart
// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';

void main() {
  final animal = new Class((b) => b
    ..name = 'Animal'
    ..extend = refer('Organism')
    ..methods.add(new Method.returnsVoid((b) => b
      ..name = 'eat'
      ..lambda = true
      ..body = const Code('print(\'Yum\')'))));
  final emitter = new DartEmitter();
  print(new DartFormatter().format('${animal.accept(emitter)}'));
}
```

...outputs...

```dart
class Animal extends Organism {
  void eat() => print('Yum!');
}
```

**Major changes**:

* Builders now use `built_value`, and have a more consistent, friendly API.
* Builders are now consistent - they don't any work until code is emitted.
* It's possible to overwrite the built-in code emitting, formatting, etc by
  providing your own visitors. See `DartEmitter` as an example of the built-in
  visitor/emitter.
* Most of the expression and statement level helpers were removed; in practice
  they were difficult to write and maintain, and many users commonly asked for
  opt-out type APIs. See the `Code` example below:

```dart
void main() {
  var code = new Code('x + y = z');
  code.expression;
  code.statement;
}
```

See the commit log, examples, and tests for full details. While we want to try
and avoid breaking changes, suggestions, new features, and incremental updates
are welcome!

## 2.0.0-beta

* Added `lazySpec` and `lazyCode` to lazily create code on visit [#145](https://github.com/dart-lang/code_builder/issues/145).

* **BUG FIX**: `equalsDart` emits the failing source code [#147](https://github.com/dart-lang/code_builder/issues/147).
* **BUG FIX**: Top-level `lambda` `Method`s no longer emit invalid code [#146](https://github.com/dart-lang/code_builder/issues/146).

## 2.0.0-alpha+3

* Added `Expression.annotation` and `Expression.annotationNamed`.
* Added `Method.closure` to create an `Expression`.
* Added `FunctionType`.
* Added `{new|const}InstanceNamed` to `Expression` [#135](https://github.com/dart-lang/code_builder/issues/135).
  * Also added a `typeArguments` option to all invocations.
* Added `assign{...}` variants to `Expression` [#137](https://github.com/dart-lang/code_builder/issues/137).
* Added `.awaited` and `.returned` to `Expression` [#138](https://github.com/dart-lang/code_builder/issues/138).

* **BUG FIX**: `Block` now implements `Code` [#136](https://github.com/dart-lang/code_builder/issues/136).
* **BUG FIX**: `new DartEmitter.scoped()` applies prefixing [#139](https://github.com/dart-lang/code_builder/issues/139).

* Renamed many of the `.asFoo(...)` and `.toFoo(...)` methods to single getter:
  * `asCode()` to `code`
  * `asStatement()` to `statement`
  * `toExpression()` to `expression`

* Moved `{new|const}Instance{[Named]}` from `Expression` to `Reference`.

## 2.0.0-alpha+2

* Upgraded `build_runner` from `^0.3.0` to `>=0.4.0 <0.6.0`.
* Upgraded `build_value{_generator}` from `^1.0.0` to `>=2.0.0 <5.0.0`.
* Upgraded `source_gen` from `>=0.5.0 <0.7.0` to `^0.7.0`.

* Added `MethodModifier` to allow emit a `Method` with `async|async*|sync*`.
* Added `show|hide` to `Directive`.
* Added `Directive.importDeferredAs`.
* Added a new line character after emitting some types (class, method, etc).
* Added `refer` as a short-hand for `new Reference(...)`.
  * `Reference` now implements `Expression`.

* Added many classes/methods for writing bodies of `Code` fluently:
  * `Expression`
  * `LiteralExpression`
    * `literal`
    * `literalNull`
    * `literalBool`
    * `literalTrue`
    * `literalFalse`
    * `literalNum`
    * `literalString`
    * `literalList` and `literalConstList`
    * `literalMap` and `literalConstMap`
  * `const Code(staticString)`
  * `const Code.scope((allocate) => '')`

* Removed `SimpleSpecVisitor` (it was unused).
* Removed `implements Reference` from `Method` and `Field`; not a lot of value.

* `SpecVisitor<T>`'s methods all have an optional `[T context]` parameter now.
  * This makes it much easier to avoid allocating extra `StringBuffer`s.
* `equalsDart` removes insignificant white space before comparing results.

## 2.0.0-alpha+1

* Removed `Reference.localScope`. Just use `Reference(symbol)` now.
* Allow `Reference` instead of an explicit `TypeReference` in most APIs.
  * `toType()` is performed for you as part the emitter process

```dart
final animal = new Class((b) => b
  ..name = 'Animal'
  // Used to need a suffix of .toType().
  ..extend = const Reference('Organism')
  ..methods.add(new Method.returnsVoid((b) => b
    ..name = 'eat'
    ..lambda = true
    ..body = new Code((b) => b..code = 'print(\'Yum\')'))));
```

* We now support the Dart 2.0 pre-release SDKs (`<2.0.0-dev.infinity`)
* Removed the ability to treat `Class` as a `TypeReference`.
  * Was required for compilation to `dart2js`, which is now tested on travis.

## 2.0.0-alpha

* Complete re-write to not use `package:analyzer`.
* Code generation now properly uses the _builder_ pattern (via `built_value`).
* See examples and tests for details.

## 1.0.4

* Added `isInstanceOf` to `ExpressionBuilder`, which performs an `is` check:

```dart
expect(
  reference('foo').isInstanceOf(_barType),
  equalsSource('foo is Bar'),
);
```

## 1.0.3

* Support latest `pkg/analyzer` and `pkg/func`.

## 1.0.2

* Update internals to use newer analyzer API

## 1.0.1

* Support the latest version of `package:dart_style`.

## 1.0.0

First full release. At this point all changes until `2.0.0` will be backwards
compatible (new features) or bug fixes that are not breaking. This doesn't mean
that the entire Dart language is buildable with our API, though.

**Contributions are welcome.**

- Exposed `uri` in `ImportBuilder`, `ExportBuilder`, and `Part[Of]Builder`.

## 1.0.0-beta+7

- Added `ExpressionBuilder#ternary`.

## 1.0.0-beta+6

- Added `TypeDefBuilder`.
- Added `FunctionParameterBuilder`.
- Added `asAbstract` to various `MethodBuilder` constructors.

## 1.0.0-beta+5

- Re-published the package without merge conflicts.

## 1.0.0-beta+4

- Renamed `PartBuilder` to `PartOfBuilder`.
- Added a new class, `PartBuilder`, to represent `part '...dart'` directives.
- Added the `HasAnnotations` interface to all library/part/directive builders.
- Added `asFactory` and `asConst` to `ConstructorBuilder`.
- Added `ConstructorBuilder.redirectTo` for a redirecting factory constructor.
- Added a `name` getter to `ReferenceBuilder`.
- Supplying an empty constructor name (`''`) is equivalent to `null` (default).
- Automatically encodes string literals with multiple lines as `'''`.
- Added `asThrow` to `ExpressionBuilder`.
- Fixed a bug that prevented `FieldBuilder` from being used at the top-level.

## 1.0.0-beta+3

- Added support for `genericTypes` parameter for `ExpressionBuilder#invoke`:

```dart
expect(
  explicitThis.invoke('doThing', [literal(true)], genericTypes: [
    lib$core.bool,
  ]),
  equalsSource(r'''
    this.doThing<bool>(true)
  '''),
);
```

- Added a `castAs` method to `ExpressionBuilder`:

```dart
expect(
  literal(1.0).castAs(lib$core.num),
  equalsSource(r'''
    1.0 as num
  '''),
);
```

### BREAKING CHANGES

- Removed `namedNewInstance` and `namedConstInstance`, replaced with `constructor: `:

```dart
expect(
  reference('Foo').newInstance([], constructor: 'other'),
  equalsSource(r'''
    new Foo.other()
  '''),
);
```

- Renamed `named` parameter to `namedArguments`:

```dart
expect(
  reference('doThing').call(
    [literal(true)],
    namedArguments: {
      'otherFlag': literal(false),
    },
  ),
  equalsSource(r'''
    doThing(true, otherFlag: false)
  '''),
);
```

## 1.0.0-beta+2

### BREAKING CHANGES

Avoid creating symbols that can collide with the Dart language:

- `MethodModifier.async` -> `MethodModifier.asAsync`
- `MethodModifier.asyncStar` -> `MethodModifier.asAsyncStar`
- `MethodModifier.syncStar` -> `MethodModifier.asSyncStar`

## 1.0.0-beta+1

- Add support for `switch` statements
- Add support for a raw expression and statement
  - `new ExpressionBuilder.raw(...)`
  - `new StatemnetBuilder.raw(...)`

This should help cover any cases not covered with builders today.

- Allow referring to a `ClassBuilder` and `TypeBuilder` as an expression
- Add support for accessing the index `[]` operator on an expression

### BREAKING CHANGES

- Changed `ExpressionBuilder.asAssign` to always take an `ExpressionBuilder` as
  target and removed the `value` property. Most changes are pretty simple, and
  involve just using `reference(...)`. For example:

```dart
literal(true).asAssign(reference('flag'))
```

... emits `flag = true`.

## 1.0.0-beta

- Add support for `async`, `sync`, `sync*` functions
- Add support for expression `asAwait`, `asYield`, `asYieldStar`
- Add `toExportBuilder` and `toImportBuilder` to types and references
- Fix an import scoping bug in `return` statements and named constructor invocations.
- Added constructor initializer support
- Add `while` and `do {} while` loop support
- Add `for` and `for-in` support
- Added a `name` getter for `ParameterBuilder`

## 1.0.0-alpha+7

- Make use of new analyzer API in preparation for analyzer version 0.30.

## 1.0.0-alpha+6

- `MethodBuilder.closure` emits properly as a top-level function

## 1.0.0-alpha+5

- MethodBuilder with no statements will create an empty block instead of
  a semicolon.

```dart
// main() {}
method('main')
```

- Fix lambdas and closures to not include a trailing semicolon when used
  as an expression.

```dart
 // () => false
 new MethodBuilder.closure(returns: literal(false));
```

## 1.0.0-alpha+4

- Add support for latest `pkg/analyzer`.

## 1.0.0-alpha+3

- BREAKING CHANGE: Added generics support to `TypeBuilder`:

`importFrom` becomes a _named_, not positional argument, and the named
argument `genericTypes` is added (`Iterable<TypeBuilder>`).

```dart
// List<String>
new TypeBuilder('List', genericTypes: [reference('String')])
```

- Added generic support to `ReferenceBuilder`:

```dart
// List<String>
reference('List').toTyped([reference('String')])
```

- Fixed a bug where `ReferenceBuilder.buildAst` was not implemented
- Added `and` and `or` methods to `ExpressionBuilder`:

```dart
// true || false
literal(true).or(literal(false));

// true && false
literal(true).and(literal(false));
```

- Added support for creating closures - `MethodBuilder.closure`:

```dart
// () => true
new MethodBuilder.closure(
  returns: literal(true),
  returnType: lib$core.bool,
)
```

## 1.0.0-alpha+2

- Added `returnVoid` to well, `return;`
- Added support for top-level field assignments:

```dart
new LibraryBuilder()..addMember(literal(false).asConst('foo'))
```

- Added support for specifying a `target` when using `asAssign`:

```dart
// Outputs bank.bar = goldBar
reference('goldBar').asAssign('bar', target: reference('bank'))
```

- Added support for the cascade operator:

```dart
// Outputs foo..doThis()..doThat()
reference('foo').cascade((c) => <ExpressionBuilder> [
  c.invoke('doThis', []),
  c.invoke('doThat', []),
]);
```

- Added support for accessing a property

```dart
// foo.bar
reference('foo').property('bar');
```

## 1.0.0-alpha+1

- Slight updates to confusing documentation.
- Added support for null-aware assignments.
- Added `show` and `hide` support to `ImportBuilder`
- Added `deferred` support to `ImportBuilder`
- Added `ExportBuilder`
- Added `list` and `map` literals that support generic types

## 1.0.0-alpha

- Large refactor that makes the library more feature complete.

## 0.1.1

- Add concept of `Scope` and change `toAst` to support it

Now your entire AST tree can be scoped and import directives
automatically added to a `LibraryBuilder` for you if you use
`LibraryBuilder.scope`.

## 0.1.0

- Initial version
