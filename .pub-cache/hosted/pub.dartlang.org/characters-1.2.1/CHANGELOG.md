## 1.2.1

* Update the value of the pubspec `repository` field.

## 1.2.0

* Fix `Characters.where` which unnecessarily did the iteration and test twice.
* Adds `Characters.empty` constant and makes `Characters("")` return it.
* Changes the argument type of `Characters.contains` to (covariant) `String`.
  The implementation still accepts `Object?`, so it can be cast to
  `Iterable<Object?>`, but you get warned if you try to call directly with a
  non-`String`.

## 1.1.0

* Stable release for null safety.
* Added `stringBeforeLength` and `stringAfterLength` to `CharacterRange`.
* Added `CharacterRange.at` constructor.
* Added `getRange(start, end)` and `characterAt(pos)` to `Characters`
  as alternative to `.take(end).skip(start)` and `getRange(pos, pos + 1)`.
* Change some positional parameter names from `other` to `characters`.

## 1.0.0

* Core APIs deemed stable; package version set to 1.0.0.
* Added `split` methods on `Characters` and `CharacterRange`.

## 0.5.0

* Change [codeUnits] getter to [utf16CodeUnits] which returns an iterable.
  This avoids leaking that the underlying string has efficient UTF-16
  code unit access in the API, and allows the same interface to be
  just as efficiently implemented on top of UTF-8.

## 0.4.0

* Added an extension method on `String` to allow easy access to the `Characters`
  of the string:

  ```dart
  print('The first character is: ' + myString.characters.first)
  ```

* Updated Dart SDK dependency to Dart 2.6.0

## 0.3.1

* Added small example in `example/main.dart`
* Enabled pedantic lints and updated code to resolve issues.

## 0.3.0

* Updated API which does not expose the underlying string indices.

## 0.1.0

* Initial release
