## 0.12.12

* Add a best practices section to readme.
* Populate the pubspec `repository` field.

## 0.12.11

* Change many argument types from `dynamic` to `Object?`.
* Fix `stringContainsInOrder` to account for repetitions and empty strings.
  * **Note**: This may break some existing tests, as the behavior does change.

## 0.12.10

* Stable release for null safety.

## 0.12.10-nullsafety.3

* Update SDK constraints to `>=2.12.0-0 <3.0.0` based on beta release
  guidelines.

## 0.12.10-nullsafety.2

- Allow prerelease versions of the 2.12 sdk.

## 0.12.10-nullsafety.1

- Allow 2.10 stable and 2.11.0 dev SDK versions.

## 0.12.10-nullsafety

- Migrate to NNBD.
  - Apis have been updated to express intent of the existing code and how it
    handled nulls.

## 0.12.9

- Improve mismatch descriptions for deep matches.  Previously, if the user tried
  to do a deep match where the expectation included a complex matcher (such as a
  "having" matcher), the failure message would just say "failed to match ...";
  it wouldn't call on the expectation's matcher to explain why the match failed.

## 0.12.8

- Add a mismatch description to `TypeMatcher`.

## 0.12.7

- Deprecate the `mirror_matchers.dart` library.

## 0.12.6

- Update minimum Dart SDK to `2.2.0`.
- Consistently point to `isA` as a replacement for `instanceOf`.
- Pretty print with private type names.

## 0.12.5

- Add `isA()` to create `TypeMatcher` instances in a more fluent way.
- **Potentially breaking bug fix**. Ordering matchers no longer treat objects
  with a partial ordering (such as NaN for double values) as if they had a
  complete ordering. For instance `greaterThan` now compares with the `>`
  operator rather not `<` and not `=`. This could cause tests which relied on
  this bug to start failing.

## 0.12.4

- Add isCastError.

## 0.12.3+1

- Set max SDK version to <3.0.0, and adjusted other dependencies.

## 0.12.3

- Many improvements to `TypeMatcher`
  - Can now be used directly as `const TypeMatcher<MyType>()`.
  - Added a type parameter to specify the target `Type`.
    - Made the `name` constructor parameter optional and marked it deprecated.
      It's redundant to the type parameter.
  - Migrated all `isType` matchers to `TypeMatcher`.
  - Added a `having` function that allows chained validations of specific
    features of the target type.

    ```dart
    /// Validates that the object is a [RangeError] with a message containing
    /// the string 'details' and `start` and `end` properties that are `null`.
    final _rangeMatcher = isRangeError
       .having((e) => e.message, 'message', contains('details'))
       .having((e) => e.start, 'start', isNull)
       .having((e) => e.end, 'end', isNull);
    ```

- Deprecated the `isInstanceOf` class. Use `TypeMatcher` instead.

- Improved the output of `Matcher` instances that fail due to type errors.

## 0.12.2+1

- Updated SDK version to 2.0.0-dev.17.0

## 0.12.2

* Fixed `unorderedMatches` in cases where the matchers may match more than one
  element and order of the elements doesn't line up with the order of the
  matchers.

* Add containsAll matcher for Iterables. This Matcher checks that all
  values/matchers in an expected iterable are satisfied by an element in the
  value without allowing the same value to satisfy multiple matchers.

## 0.12.1+4

* Fixed SDK constraint to allow edge builds.

## 0.12.1+3

* Make `predicate` and `pairwiseCompare` generic methods to allow typed
 functions to be passed to them as arguments.

* Make internal implementations take better advantage of type promotion to avoid
  dynamic call overhead.

## 0.12.1+2

* Fixed small documentation issues.

* Fixed small issue in `StringEqualsMatcher`.

* Update to support future Dart language changes.

## 0.12.1+1

* Produce a better error message when a `CustomMatcher`'s feature throws.

## 0.12.1

* Add containsAllInOrder matcher for Iterables

## 0.12.0+2

* Fix all strong-mode warnings.

## 0.12.0+1

* Fix test files to use `test` instead of `unittest` pkg.

## 0.12.0

* Moved a number of members to the
  [`unittest`](https://pub.dev/packages/unittest) package.
  * `TestFailure`, `ErrorFormatter`, `expect`, `fail`, and 'wrapAsync'.
  * `completes`, `completion`, `throws`, and `throwsA` Matchers.
  * The `Throws` class.
  * All of the `throws...Error` Matchers.

* Removed `FailureHandler`, `DefaultFailureHandler`,
  `configureExpectFailureHandler`, and `getOrCreateExpectFailureHandler`.
  Now that `expect` is in the `unittest` package, these are no longer needed.

* Removed the `name` parameter for `isInstanceOf`. This was previously
  deprecated, and is no longer necessary since all language implementations now
  support converting the type parameter to a string directly.

## 0.11.4+6

* Fix a bug introduced in 0.11.4+5 in which operator matchers broke when taking
  lists of matchers.

## 0.11.4+5

* Fix all strong-mode warnings.

## 0.11.4+4

* Deprecate the name parameter to `isInstanceOf`. All language implementations
  now support converting the type parameter to a string directly.

## 0.11.4+3

* Fix the examples for `equalsIgnoringWhitespace`.

## 0.11.4+2

* Improve the formatting of strings that contain unprintable ASCII characters.

## 0.11.4+1

* Correctly match and print `String`s containing characters that must be
  represented as escape sequences.

## 0.11.4

* Remove the type checks in the `isEmpty` and `isNotEmpty` matchers and simply
  access the `isEmpty` respectively `isNotEmpty` fields. This allows them to
  work with custom collections. See [Issue
  21792](https://code.google.com/p/dart/issues/detail?id=21792) and [Issue
  21562](https://code.google.com/p/dart/issues/detail?id=21562)

## 0.11.3+1

* Fix the `prints` matcher test on dart2js.

## 0.11.3

* Add a `prints` matcher that matches output a callback emits via `print`.

## 0.11.2

* Add an `isNotEmpty` matcher.

## 0.11.1+1

* Refactored libraries and tests.

* Fixed spelling mistake.

## 0.11.1

* Added `isNaN` and `isNotNaN` matchers.

## 0.11.0

* Removed deprecated matchers.

## 0.10.1+1

* Get the tests passing when run on dart2js in minified mode.

## 0.10.1

* Compare sets order-independently when using `equals()`.

## 0.10.0+3

* Removed `@deprecated` annotation on matchers due to
[Issue 19173](https://code.google.com/p/dart/issues/detail?id=19173)

## 0.10.0+2

* Added types to a number of constants.

## 0.10.0+1

* Matchers related to bad language use have been removed. These represent code
structure that should rarely or never be validated in tests.
    * `isAbstractClassInstantiationError`
    * `throwsAbstractClassInstantiationError`
    * `isFallThroughError`
    * `throwsFallThroughError`

* Added types to a number of method arguments.

* The structure of the library and test code has been updated.
