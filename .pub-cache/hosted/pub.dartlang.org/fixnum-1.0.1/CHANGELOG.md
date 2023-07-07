## 1.0.1

* Switch to using `package:lints`.
* Populate the pubspec `repository` field.

## 1.0.0

* Stable null safety release.

## 1.0.0-nullsafety.0

* Migrate to null safety.
  * This is meant to be mostly non-breaking, for opted in users runtime errors
    will be promoted to static errors. For non-opted in users the runtime
    errors are still present in their original form.

## 0.10.11

* Update minimum SDK constraint to version 2.1.1.

## 0.10.10

* Fix `Int64` parsing to throw `FormatException` on an empty string or single
  minus sign. Previous incorrect behaviour was to throw a `RangeError` or
  silently return zero.

## 0.10.9

* Add `Int64.toStringUnsigned()` and `Int64.toRadixStringUnsigned()` functions.

## 0.10.8

* Set SDK version constraint to `>=2.0.0-dev.65 <3.0.0`.

## 0.10.7

* Bug fix: Make bit shifts work at bitwidth boundaries. Previously,
  `new Int64(3) << 64 == Int64(3)`. This ensures that the result is 0 in such
  cases.
* Updated maximum SDK constraint from 2.0.0-dev.infinity to 2.0.0.

## 0.10.6

* Fix `Int64([int value])` constructor to avoid rounding error on intermediate
  results for large negative inputs when compiled to JavaScript. `new
  Int64(-1000000000000000000)` used to produce the same value as
  `Int64.parseInt("-1000000000000000001")`

## 0.10.5

* Fix strong mode warning in overridden `compareTo()` methods.

*No changelog entries for previous versions...*
