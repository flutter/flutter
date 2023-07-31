## 1.10.0

* Add a `SourceFile.codeUnits` property.
* Require Dart 2.18
* Add an API usage example in `example/`.

## 1.9.1

* Properly handle multi-line labels for multi-span highlights.

* Populate the pubspec `repository` field.

## 1.9.0

* Add `SourceSpanWithContextExtension.subspan` that returns a
  `SourceSpanWithContext` rather than a plain `SourceSpan`.

## 1.8.2

* Fix a bug where highlighting multiple spans with `null` URLs could cause an
  assertion error. Now when multiple spans are passed with `null` URLs, they're
  highlighted as though they all come from different source files.

## 1.8.1

* Fix a bug where the URL header for the highlights with multiple files would
  get omitted only one span has a non-null URI.

## 1.8.0

* Stable release for null safety.

## 1.7.0

* Add a `SourceSpan.subspan()` extension method which returns a slice of an
  existing source span.

## 1.6.0

* Add support for highlighting multiple source spans at once, providing more
  context for span-based messages. This is exposed through the new APIs
  `SourceSpan.highlightMultiple()` and `SourceSpan.messageMultiple()` (both
  extension methods), `MultiSourceSpanException`, and
  `MultiSourceSpanFormatException`.

## 1.5.6

* Fix padding around line numbers that are powers of 10 in
  `FileSpan.highlight()`.

## 1.5.5

* Fix a bug where `FileSpan.highlight()` would crash for spans that covered a
  trailing newline and a single additional empty line.

## 1.5.4

* `FileSpan.highlight()` now properly highlights point spans at the beginning of
  lines.

## 1.5.3

* Fix an edge case where `FileSpan.highlight()` would put the highlight
  indicator in the wrong position when highlighting a point span after the end
  of a file.

## 1.5.2

* `SourceFile.span()` now goes to the end of the file by default, rather than
  ending one character before the end of the file. This matches the documented
  behavior.

* `FileSpan.context` now includes the full line on which the span appears for
  empty spans at the beginning and end of lines.

* Fix an edge case where `FileSpan.highlight()` could crash when highlighting a
  span that ended with an empty line.

## 1.5.1

* Produce better source span highlights for multi-line spans that cover the
  entire last line of the span, including the newline.

* Produce better source span highlights for spans that contain Windows-style
  newlines.

## 1.5.0

* Improve the output of `SourceSpan.highlight()` and `SourceSpan.message()`:

  * They now include line numbers.
  * They will now print every line of a multiline span.
  * They will now use Unicode box-drawing characters by default (this can be
    controlled using [`term_glyph.ascii`][]).

[`term_glyph.ascii`]: https://pub.dartlang.org/documentation/term_glyph/latest/term_glyph/ascii.html

## 1.4.1

* Set max SDK version to `<3.0.0`, and adjust other dependencies.

## 1.4.0

* The `new SourceFile()` constructor is deprecated. This constructed a source
  file from a string's runes, rather than its code units, which runs counter to
  the way Dart handles strings otherwise. The `new StringFile.fromString()`
  constructor (see below) should be used instead.

* The `new SourceFile.fromString()` constructor was added. This works like `new
  SourceFile()`, except it uses code units rather than runes.

* The current behavior when characters larger than `0xFFFF` are passed to `new
  SourceFile.decoded()` is now considered deprecated.

## 1.3.1

* Properly highlight spans for lines that include tabs with
  `SourceSpan.highlight()` and `SourceSpan.message()`.

## 1.3.0

* Add `SourceSpan.highlight()`, which returns just the highlighted text that
  would be included in `SourceSpan.message()`.

## 1.2.4

* Fix a new strong mode error.

## 1.2.3

* Fix a bug where a point span at the end of a file without a trailing newline
  would be printed incorrectly.

## 1.2.2

* Allow `SourceSpanException.message`, `SourceSpanFormatException.source`, and
  `SourceSpanWithContext.context` to be overridden in strong mode.

## 1.2.1

* Fix the declared type of `FileSpan.start` and `FileSpan.end`. In 1.2.0 these
  were mistakenly changed from `FileLocation` to `SourceLocation`.

## 1.2.0

* **Deprecated:** Extending `SourceLocation` directly is deprecated. Instead,
  extend the new `SourceLocationBase` class or mix in the new
  `SourceLocationMixin` mixin.

* Dramatically improve the performance of `FileLocation`.

## 1.1.6

* Optimize `getLine()` in `SourceFile` when repeatedly called.

## 1.1.5

* Fixed another case in which `FileSpan.union` could throw an exception for
  external implementations of `FileSpan`.

## 1.1.4

* Eliminated dart2js warning about overriding `==`, but not `hashCode`.

## 1.1.3

* `FileSpan.compareTo`, `FileSpan.==`, `FileSpan.union`, and `FileSpan.expand`
  no longer throw exceptions for external implementations of `FileSpan`.

* `FileSpan.hashCode` now fully agrees with `FileSpan.==`.

## 1.1.2

* Fixed validation in `SourceSpanWithContext` to allow multiple occurrences of
  `text` within `context`.

## 1.1.1

* Fixed `FileSpan`'s context to include the full span text, not just the first
  line of it.

## 1.1.0

* Added `SourceSpanWithContext`: a span that also includes the full line of text
  that contains the span.

## 1.0.3

* Cleanup equality operator to accept any Object rather than just a
  `SourceLocation`.

## 1.0.2

* Avoid unintentionally allocating extra objects for internal `FileSpan`
  operations.

* Ensure that `SourceSpan.operator==` works on arbitrary `Object`s.

## 1.0.1

* Use a more compact internal representation for `FileSpan`.

## 1.0.0

This package was extracted from the
[`source_maps`](https://pub.dev/packages/source_maps) package, but the
API has many differences. Among them:

* `Span` has been renamed to `SourceSpan` and `Location` has been renamed to
  `SourceLocation` to clarify their purpose and maintain consistency with the
  package name. Likewise, `SpanException` is now `SourceSpanException` and
  `SpanFormatException` is not `SourceSpanFormatException`.

* `FixedSpan` and `FixedLocation` have been rolled into the `Span` and
  `Location` classes, respectively.

* `SourceFile` is more aggressive about validating its arguments. Out-of-bounds
  lines, columns, and offsets will now throw errors rather than be silently
  clamped.

* `SourceSpan.sourceUrl`, `SourceLocation.sourceUrl`, and `SourceFile.url` now
  return `Uri` objects rather than `String`s. The constructors allow either
  `String`s or `Uri`s.

* `Span.getLocationMessage` and `SourceFile.getLocationMessage` are now
  `SourceSpan.message` and `SourceFile.message`, respectively. Rather than
  taking both a `useColor` and a `color` parameter, they now take a single
  `color` parameter that controls both whether and which color is used.

* `Span.isIdentifier` has been removed. This property doesn't make sense outside
  of a source map context.

* `SourceFileSegment` has been removed. This class wasn't widely used and was
  inconsistent in its choice of which parameters were considered relative and
  which absolute.
