## 1.3.1

* Switch to using `package:lints`.
* Populate the pubspec `repository` field.

## 1.3.0

* Stable release for null safety.

## 1.3.0-nullsafety.5

* Update SDK constraints to `>=2.12.0-0 <3.0.0` based on beta release
  guidelines.

## 1.3.0-nullsafety.4

* Allow prerelease versions of the `2.12` sdk.

## 1.3.0-nullsafety.3

* Allow 2.10 stable and 2.11.0 dev SDK versions.

## 1.3.0-nullsafety.2

* Update for the 2.10 dev sdk.

## 1.3.0-nullsafety.1

* Allow the <=2.9.10 stable sdks.

## 1.3.0-nullsafety

* Migrate to NNBD

## 1.2.0

* Add typed queue classes such as `Uint8Queue`. These classes implement both
  `Queue` and `List` with a highly-efficient typed-data-backed implementation.
  Their `sublist()` methods also return typed data classes.
* Update min Dart SDK to `2.4.0`.

## 1.1.6

* Set max SDK version to `<3.0.0`, and adjust other dependencies.

## 1.1.5

* Undo unnessesary SDK version constraint tweak.

## 1.1.4

* Expand the SDK version constraint to include `<2.0.0-dev.infinity`.

## 1.1.3

* Fix all strong-mode warnings.

## 1.1.2

* Fix a bug where `TypedDataBuffer.insertAll` could fail to insert some elements
  of an `Iterable`.

## 1.1.1

* Optimize `insertAll` with an `Iterable` argument and no end-point.

## 1.1.0

* Add `start` and `end` parameters to the `addAll()` and `insertAll()` methods
  for the typed data buffer classes. These allow efficient concatenation of
  slices of existing typed data.

* Make `addAll()` for typed data buffer classes more efficient for lists,
  especially typed data lists.

## 1.0.0

* ChangeLog starts here
