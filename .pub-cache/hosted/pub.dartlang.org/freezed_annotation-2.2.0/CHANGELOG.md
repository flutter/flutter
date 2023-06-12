# 2.2.0

- Re-introduced `@With.fromString` and `@Implements.fromString` to allow unions
  to implement generic types. (thanks to @rorystephenson)

# 2.1.0

- Add support for de/serializing generic Freezed classes (Thanks to @TimWhiting)

# 2.0.3

– fix: build.yaml decoding crash

# 2.0.1

- Fixed a bug where the generated when/map methods were potentially invalid when
  using default values
- Fixed a bug where when/map methods were generated even when not necessary

# 2.0.0

- **Breaking**: freezed_annotation no-longer exports the entire package:collection
- **Breaking** Removed `@Freezed(maybeMap: )` & `@Freezed(maybeWhen: )` in favor of a separate:

  ```Dart
  @Freezed(map: FreezedMap(...), when: FreezedWhenOptions(...))
  ```

- Feat: Add screaming snake union case type (#617) (thanks to @zbarbuto)
- Added `@unfreezed` as a variant to `@freezed`, for mutable classes

# 1.1.0

Added support for disabling the generation of `maybeMap`/`maybeWhen` (thanks to @Lyokone)

# 1.0.0

freezed_annotation is now stable

# 0.15.0

- **Breaking** Changed the syntax for `@With` and `@Implements` to use a generic annotation.
  Before:

  ```dart
  @With(MyClass)
  @With.fromString('Generic<int>')
  ```

  After:

  ```dart
  @With<MyClass>()
  @With<Generic<int>>()
  ```

# 0.14.3

Upgraded to support last json_annotation version

# 0.14.2

- Added the ability to specify a fallback constructor when deserializing unions (thanks to @Brazol)

# 0.14.1

- Added the ability to customise the JSON value of a union. See https://github.com/rrousselGit/freezed#fromjson---classes-with-multiple-constructors for more information (Thanks to @ookami-kb)

# 0.14.0

- Stable null safety release
- removed `@nullable`.
  Instead of:
  ```dart
  factory Example({@nullable int a}) = _Example;
  ```
  Do:
  ```dart
  factory Example({int? a}) = _Example;
  ```
- removed `@late`.
  Instead of:

  ```dart
  abstract class Person with _$Person {
    factory Person({
      required String firstName,
      required String lastName,
    }) = _Person;

    @late
    String get fullName => '$firstName $lastName';
  }
  ```

  Do:

  ```dart
  abstract class Person with _$Person {
  Person._();
  factory Person({
    required String firstName,
    required String lastName,
  }) = _Person;

  late final fullName = '$firstName $lastName';
  }
  ```

# 0.13.0-nullsafety.0

- Migrated to null safety
- removed `@nullable`.
  Instead of:
  ```dart
  factory Example({@nullable int a}) = _Example;
  ```
  Do:
  ```dart
  factory Example({int? a}) = _Example;
  ```
- removed `@late`.
  Instead of:

  ```dart
  abstract class Person with _$Person {
    factory Person({
      required String firstName,
      required String lastName,
    }) = _Person;

    @late
    String get fullName => '$firstName $lastName';
  }
  ```

  Do:

  ```dart
  abstract class Person with _$Person {
  Person._();
  factory Person({
    required String firstName,
    required String lastName,
  }) = _Person;

  late final fullName = '$firstName $lastName';
  }
  ```

# 0.12.0

- Added `Assert` decorator to generate `assert(...)` statements on Freezed classes:

  ```dart
  abstract class Person with _$Person {
    @Assert('name.trim().isNotEmpty', 'name cannot be empty')
    @Assert('age >= 0')
    factory Person({
      String name,
      int age,
    }) = _Person;
  }
  ```

- Added a way to customize the de/serialization of union types using the
  `@Freezed(unionKey: 'my-key')` decorator.

  See also https://github.com/rrousselGit/freezed#fromjson---classes-with-multiple-constructors

# 0.11.0

- Added `@With` and `@Implements` decorators to allow only a specific constructor
  of a union type to implement an interface:

  ```dart
  @freezed
  abstract class Example with _$Example {
    const factory Example.person(String name, int age) = Person;

    @Implements(GeographicArea)
    const factory Example.city(String name, int population) = City;
  }
  ```

  Thanks to @long1eu~

# 0.7.1

Minor change to `@Default` to fix an issue with complex default values.

# 0.7.0

Add `@Default` annotation

# 0.6.0

Added `@late` annotation.

# 0.4.0

Added a `@nullable` annotation.

# 0.3.1

Change version of `collection` to work with `flutter_test`.

# 0.3.0

Initial release of the annotation package.
