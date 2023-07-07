## 0.17.2

- Fixed a crash caused by `min()`, `max()` and `clamp()` functions that contain
  mathematical expressions.
- Add commas between PercentageTerms in keyframe rules.

## 0.17.1

- Fix `Color.css` constructor when there are double values in the `rgba` string.

## 0.17.0

- Migrate to null safety.
- `Font.merge` and `BoxEdge.merge` are now static methods instead of factory
  constructors.
- Add a type on the `identList` argument to `TokenKind.matchList`.
- Remove workaround for https://github.com/dart-lang/sdk/issues/43136, which is
  now fixed.

## 0.16.2

- Added support for escape codes in identifiers.

## 0.16.1

- Fixed a crash caused by parsing certain calc() expressions and variables names that contain numbers.

## 0.16.0

- Removed support for the shadow-piercing comibnators `/deep/` and `>>>`. These
  were dropped from the Shadow DOM specification.

## 0.15.0

- **BREAKING**
  - Removed `css` executable from `bin` directory.
  - Removed the deprecated `css.dart` library.
  - `Message.level` is now of type `MessageLevel` defined in this package.
- Removed dependencies on `package:args` and `package:logging`.
- Require Dart SDK `>=2.1.0`.

## 0.14.6

* Removed whitespace between comma-delimited expressions in compact output.

  Before:
  ```css
  div{color:rgba(0, 0, 0, 0.5);}
  ```

  After:
  ```css
  div{color:rgba(0,0,0,0.5);}
  ```

* Removed last semicolon from declaration groups in compact output.

  Before:
  ```css
  div{color:red;background:blue;}
  ```

  After:
  ```css
  div{color:red;background:blue}
  ```

## 0.14.5

* Fixed a crashed caused by parsing `:host()` without an argument and added an
  error message explaining that a selector argument is expected.

## 0.14.4+1

* Set max SDK version to `<3.0.0`, and adjust other dependencies.

## 0.14.4

* Reduced whitespace in compact output for the `@page` at-rule and margin boxes.
* Updated SDK version to 2.0.0-dev.17.0.
* Stop using deprecated constants.

## 0.14.3

* Reduced the amount of whitespace in compact output around braces.

## 0.14.2

* Fixed Dart 2 runtime failure.

## 0.14.1

* Deprecated `package:csslib/css.dart`.
  Use `parser.dart` and `visitor.dart` instead.

## 0.14.0

### New features

* Supports nested at-rules.
* Supports nested HTML comments in CSS comments and vice-versa.

### Breaking changes

* The `List<RuleSet> rulesets` field on `MediaDirective`, `HostDirective`, and
  `StyletDirective` has been replaced by `List<TreeNode> rules` to allow nested
  at-rules in addition to rulesets.

## 0.13.6

* Adds support for `@viewport`.
* Adds support for `-webkit-calc()` and `-moz-calc()`.
* Adds support for querying media features without specifying an expression. For
  example: `@media (transform-3d) { ... }`.
* Prevents exception being thrown for invalid dimension terms, and instead
  issues an error.

## 0.13.5

* Adds support for `@-moz-document`.
* Adds support for `@supports`.

## 0.13.4

* Parses CSS 2.1 pseudo-elements as pseudo-elements instead of pseudo-classes.
* Supports signed decimal numbers with no integer part.
* Fixes parsing hexadecimal numbers when followed by an identifier.
* Fixes parsing strings which contain unicode-range character sequences.

## 0.13.3+1

* Fixes analyzer error.

## 0.13.3

* Adds support for shadow host selectors `:host()` and `:host-context()`.
* Adds support for shadow-piercing descendant combinator `>>>` and its alias
  `/deep/` for backwards compatibility.
* Adds support for non-functional IE filter properties (i.e. `filter: FlipH`).
* Fixes emitted CSS for `@page` directive when body includes declarations and
  page-margin boxes.
* Exports `Message` from `parser.dart` so it's no longer necessary to import
  `src/messages.dart` to use the parser API.

## 0.13.2+2

* Fix static warnings.

## 0.13.2+1

* Fix new strong mode error.

## 0.13.2

* Relax type of TreeNode.visit, to allow returning values from visitors.

## 0.13.1

* Fix two checked mode bugs introduced in 0.13.0.

## 0.13.0

 * **BREAKING** Fix all [strong mode][] errors and warnings.
   This involved adding more precise on some public APIs, which
   is why it may break users.

[strong mode]: https://github.com/dart-lang/dev_compiler/blob/master/STRONG_MODE.md

## 0.12.2

 * Fix to handle calc functions however, the expressions are treated as a
   LiteralTerm and not fully parsed into the AST.

## 0.12.1

 * Fix to handling of escapes in strings.

## 0.12.0+1

* Allow the lastest version of `logging` package.

## 0.12.0

* Top-level methods in `parser.dart` now take `PreprocessorOptions` instead of
  `List<String>`.

* `PreprocessorOptions.inputFile` is now final.

## 0.11.0+4

* Cleanup some ambiguous and some incorrect type signatures.

## 0.11.0+3

* Improve the speed and memory efficiency of parsing.

## 0.11.0+2

* Fix another test that was failing on IE10.

## 0.11.0+1

* Fix a test that was failing on IE10.

## 0.11.0

* Switch from `source_maps`' `Span` class to `source_span`'s `SourceSpan` class.
