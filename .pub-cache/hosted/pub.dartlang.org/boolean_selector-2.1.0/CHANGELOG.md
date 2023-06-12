## 2.1.0

* Stable release for null safety.

## 2.1.0-nullsafety.3

* Update SDK constraints to `>=2.12.0-0 <3.0.0` based on beta release
  guidelines.

## 2.1.0-nullsafety.2

* Allow prerelease versions of the 2.12 sdk.

## 2.1.0-nullsafety.1

* Allow 2.10 stable and 2.11.0 dev SDK versions.

## 2.1.0-nullsafety

* Migrate to null safety. There are no expected semantic changes.

## 2.0.0

* Breaking: `BooleanSelector.evaluate` always takes a `bool Function(String)`.
  For use cases previously passing a `Set<String>`, tear off the `.contains`
  method. For use cases passing an `Iterable<String>` it may be worthwhile to
  first use `.toSet()` before tearing off `.contains`.

## 1.0.5

* Update package metadata & add `example/` folder

## 1.0.4

* Now requires Dart 2.

## 1.0.3

* Work around an inference bug in the new common front-end.

## 1.0.2

* Declare compatibility with `string_scanner` 1.0.0.

## 1.0.1

* Fix all strong mode warnings.

## 1.0.0

* Initial release.
