## 3.1.1

* Switch to using package:lints.
* Populate the pubspec `repository` field.

## 3.1.0

* `loadYaml` and related functions now accept a `recover` flag instructing the parser
  to attempt to recover from parse errors and may return invalid or synthetic nodes.
  When recovering, an `ErrorListener` can also be supplied to listen for errors that
  are recovered from.
* Drop dependency on `package:charcode`.

## 3.0.0

* Stable null safety release.

## 3.0.0-nullsafety.0

* Updated to support 2.12.0 and null safety.
* Allow `YamlNode`s to be wrapped with an optional `style` parameter.
* **BREAKING** The `sourceUrl` named argument is statically typed as `Uri`
  instead of allowing `String` or `Uri`.

## 2.2.1

* Update min Dart SDK to `2.4.0`.
* Fixed span for null nodes in block lists.

## 2.2.0

* POSSIBLY BREAKING CHANGE: Make `YamlMap` preserve parsed key order.
  This is breaking because some programs may rely on the
  `HashMap` sort order.

## 2.1.16

* Fixed deprecated API usage in README.
* Fixed lints that affect package score.

## 2.1.15

* Set max SDK version to `<3.0.0`, and adjust other dependencies.

## 2.1.14

* Remove use of deprecated features.
* Updated SDK version to 2.0.0-dev.17.0

## 2.1.13

* Stop using comment-based generic syntax.

## 2.1.12

* Properly refuse mappings with duplicate keys.

## 2.1.11

* Fix an infinite loop when parsing some invalid documents.

## 2.1.10

* Support `string_scanner` 1.0.0.

## 2.1.9

* Fix all strong-mode warnings.

## 2.1.8

* Remove the dependency on `path`, since we don't actually import it.

## 2.1.7

* Fix more strong mode warnings.

## 2.1.6

* Fix two analysis issues with DDC's strong mode.

## 2.1.5

* Fix a bug with 2.1.4 where source span information was being discarded for
  scalar values.

## 2.1.4

* Substantially improve performance.

## 2.1.3

* Add a hint that a colon might be missing when a mapping value is found in the
  wrong context.

## 2.1.2

* Fix a crashing bug when parsing block scalars.

## 2.1.1

* Properly scope `SourceSpan`s for scalar values surrounded by whitespace.

## 2.1.0

* Rewrite the parser for a 10x speed improvement.

* Support anchors and aliases (`&foo` and `*foo`).

* Support explicit tags (e.g. `!!str`). Note that user-defined tags are still
  not fully supported.

* `%YAML` and `%TAG` directives are now parsed, although again user-defined tags
  are not fully supported.

* `YamlScalar`, `YamlList`, and `YamlMap` now expose the styles in which they
  were written (for example plain vs folded, block vs flow).

* A `yamlWarningCallback` field is exposed. This field can be used to customize
  how YAML warnings are displayed.

## 2.0.1+1

* Fix an import in a test.

* Widen the version constraint on the `collection` package.

## 2.0.1

* Fix a few lingering references to the old `Span` class in documentation and
  tests.

## 2.0.0

* Switch from `source_maps`' `Span` class to `source_span`'s `SourceSpan` class.

* For consistency with `source_span` and `string_scanner`, all `sourceName`
  parameters have been renamed to `sourceUrl`. They now accept Urls as well as
  Strings.

## 1.1.1

* Fix broken type arguments that caused breakage on dart2js.

* Fix an analyzer warning in `yaml_node_wrapper.dart`.

## 1.1.0

* Add new publicly-accessible constructors for `YamlNode` subclasses. These
  constructors make it possible to use the same API to access non-YAML data as
  YAML data.

* Make `YamlException` inherit from source_map's `SpanFormatException`. This
  improves the error formatting and allows callers access to source range
  information.

## 1.0.0+1

* Fix a variable name typo.

## 1.0.0

* **Backwards incompatibility**: The data structures returned by `loadYaml` and
  `loadYamlStream` are now immutable.

* **Backwards incompatibility**: The interface of the `YamlMap` class has
  changed substantially in numerous ways. External users may no longer construct
  their own instances.

* Maps and lists returned by `loadYaml` and `loadYamlStream` now contain
  information about their source locations.

* A new `loadYamlNode` function returns the source location of top-level scalars
  as well.

## 0.10.0

* Improve error messages when a file fails to parse.

## 0.9.0+2

* Ensure that maps are order-independent when used as map keys.

## 0.9.0+1

* The `YamlMap` class is deprecated. In a future version, maps returned by
  `loadYaml` and `loadYamlStream` will be Dart `HashMap`s with a custom equality
  operation.
