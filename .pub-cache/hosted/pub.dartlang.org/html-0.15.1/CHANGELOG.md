## 0.15.1

- Move `htmlSerializeEscape` to its own library,
  `package:html/html_escape.dart`, which is exported from
  `package:html/dom_parsing.dart`.
- Use more non-growable lists, and type annotations on List literals.
- Switch analysis option `implicit-casts: false` to `strict-casts: true`.

## 0.15.0

- Migrate to null safety.
- Drop `lastPhase`, `beforeRcDataPhase`, and `container` fields from
  `HtmlParser` class. These fields never had a value other than `null`.

## 0.14.0+4

- Fix a bug parsing bad HTML where a 'button' end tag needs to close other
  elements.

## 0.14.0+3

- Fix spans generated for HTML with higher-plane unicode characters
  (eg. emojis).

## 0.14.0+2

- Support `package:css` `>=0.13.2 <0.17.0`.

## 0.14.0+1

- Support `package:css` `>=0.13.2 <0.16.0`.

## 0.14.0

*BREAKING CHANGES*

- Drop support for encodings other than UTF-8 and ASCII.
- Removed `parser_console.dart` library.

## 0.13.4+1

* Fixes to readme and pubspec.

## 0.13.4

* Require Dart 2.0 stable.

## 0.13.3+3

* Do not use this tag in our systems - there was an earlier version of it
  pointing to a different commit, that is still in some caches.

* Fix missing_return analyzer errors in `processStartTag` and `processEndTag`
  methods.

## 0.13.3+2

* Set max SDK version to `<3.0.0`, and adjust other dependencies.

## 0.13.3+1

 * Updated SDK version to 2.0.0-dev.17.0

## 0.13.3

 * Update the signatures of `FilteredElementList.indexOf` and
   `FilteredElementList.lastIndexOf` to include type annotations.

## 0.13.2+2

 * Update signature for implementations of `Iterable.singleWhere` to include
   optional argument.

## 0.13.2+1

 * Changed the implementation of `Set` and `List` classes to use base classes
   from `dart:collection`.

## 0.13.2

 * Support the latest release of `pkg/csslib`.

## 0.13.1
 * Update Set.difference to take a Set<Object>.

## 0.13.0

 * **BREAKING** Fix all [strong mode][] errors and warnings.
   This involved adding more precise types on some public APIs, which is why it
   may break users.

[strong mode]: https://github.com/dart-lang/dev_compiler/blob/master/STRONG_MODE.md

#### Pub version 0.12.2+2
  * Support `csslib` versions `0.13.x`.

#### Pub version 0.12.2+1
  * Exclude `.packages` file from the published package.

#### Pub version 0.12.2
  * Added `Element.endSourceSpan`, containing the span of a closing tag.

#### Pub version 0.12.0+1
  * Support `csslib` version `0.12.0`.

#### Rename to package:html 0.12.0
  * package has been renamed to `html`

#### Pub version 0.12.0
  * switch from `source_maps`' `Span` class to `source_span`'s
    `SourceSpan` class.

#### Pub version 0.11.0+2
  * expand the version constraint for csslib.

#### Pub version 0.10.0+1
  * use a more recent source_maps version.

#### Pub version 0.10.0
  * fix how document fragments are added in NodeList.add/addAll/insertAll.

#### Pub version 0.9.2-dev
  * add Node.text, Node.append, Document.documentElement
  * add Text.data, deprecate Node.value and Text.value.
  * deprecate Node.$dom_nodeType
  * added querySelector/querySelectorAll, deprecated query/queryAll.
    This matches the current APIs in dart:html.
