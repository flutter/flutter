## 1.2.0

* Require Dart 2.18.0

* Add better support for reading code points in the Unicode supplementary plane:

  * Added `StringScanner.readCodePoint()`, which consumes an entire Unicode code
    point even if it's represented by two UTF-16 code units.

  * Added `StringScanner.peekCodePoint()`, which returns an entire Unicode code
    point even if it's represented by two UTF-16 code units.

  * `StringScanner.scanChar()` and `StringScanner.expectChar()` will now
    properly consume two UTF-16 code units if they're passed Unicode code points
    in the supplementary plane.

## 1.1.1

* Populate the pubspec `repository` field.
* Switch to `package:lints`.
* Remove a dependency on `package:charcode`.

## 1.1.0

* Stable release for null safety.

## 1.1.0-nullsafety.3

* Update SDK constraints to `>=2.12.0-0 <3.0.0` based on beta release
  guidelines.

## 1.1.0-nullsafety.2

* Allow prerelease versions of the 2.12 sdk.

## 1.1.0-nullsafety.1

- Allow 2.10 stable and 2.11.0 dev SDK versions.

## 1.1.0-nullsafety

- Migrate to null safety.

## 1.0.5

- Added an example.

- Update Dart SDK constraint to `>=2.0.0 <3.0.0`.

## 1.0.4

* Add @alwaysThrows annotation to error method.

## 1.0.3

* Set max SDK version to `<3.0.0`, and adjust other dependencies.

## 1.0.2

* `SpanScanner` no longer crashes when creating a span that contains a UTF-16
  surrogate pair.

## 1.0.1

* Fix the error text emitted by `StringScanner.expectChar()`.

## 1.0.0

* **Breaking change**: `StringScanner.error()`'s `length` argument now defaults
  to `0` rather than `1` when no match data is available.

* **Breaking change**: `StringScanner.lastMatch` and related methods are now
  reset when the scanner's position changes without producing a new match.

**Note**: While the changes in `1.0.0` are user-visible, they're unlikely to
actually break any code in practice. Unless you know that your package is
incompatible with 0.1.x, consider using 0.1.5 as your lower bound rather
than 1.0.0. For example, `string_scanner: ">=0.1.5 <2.0.0"`.

## 0.1.5

* Add `new SpanScanner.within()`, which scans within a existing `FileSpan`.

* Add `StringScanner.scanChar()` and `StringScanner.expectChar()`.

## 0.1.4+1

* Remove the dependency on `path`, since we don't actually import it.

## 0.1.4

* Add `new SpanScanner.eager()` for creating a `SpanScanner` that eagerly
  computes its current line and column numbers.

## 0.1.3+2

* Fix `LineScanner`'s handling of carriage returns to match that of
  `SpanScanner`.

## 0.1.3+1

* Fixed the homepage URL.

## 0.1.3

* Add an optional `endState` argument to `SpanScanner.spanFrom`.

## 0.1.2

* Add `StringScanner.substring`, which returns a substring of the source string.

## 0.1.1

* Declare `SpanScanner`'s exposed `SourceSpan`s and `SourceLocation`s to be
  `FileSpan`s and `FileLocation`s. They always were underneath, but callers may
  now rely on it.

* Add `SpanScanner.location`, which returns the scanner's current
  `SourceLocation`.

## 0.1.0

* Switch from `source_maps`' `Span` class to `source_span`'s `SourceSpan` class.

* `new StringScanner()`'s `sourceUrl` parameter is now named to make it clear
  that it can be safely `null`.

* `new StringScannerException()` takes different arguments in a different order
  to match `SpanFormatException`.

* `StringScannerException.string` has been renamed to
  `StringScannerException.source` to match the `FormatException` interface.

## 0.0.3

* Make `StringScannerException` inherit from source_map's `SpanFormatException`.

## 0.0.2

* `new StringScanner()` now takes an optional `sourceUrl` argument that provides
  the URL of the source file. This is used for error reporting.

* Add `StringScanner.readChar()` and `StringScanner.peekChar()` methods for
  doing character-by-character scanning.

* Scanners now throw `StringScannerException`s which provide more detailed
  access to information about the errors that were thrown and can provide
  terminal-colored messages.

* Add a `LineScanner` subclass of `StringScanner` that automatically tracks line
  and column information of the text being scanned.

* Add a `SpanScanner` subclass of `LineScanner` that exposes matched ranges as
  [source map][] `Span` objects.

[source_map]: https://pub.dev/packages/source_maps
