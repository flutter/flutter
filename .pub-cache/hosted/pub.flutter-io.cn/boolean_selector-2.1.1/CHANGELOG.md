## 2.1.1

* Increase the SDK minimum to `2.17.0`.
* Populate the pubspec `repository` field.

## 2.1.0

* Stable release for null safety.

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
