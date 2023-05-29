# Changelog

## 6.2.0

* Upgrade to PetitParser 5.1.0 brings a 10% speed improvement (typed sequences).
* Add the ability to tap into a stream of `XmlEvent` with `tapEachEvent` (similar to `forEachEvent`).
* Remove `XmlName` equality operator `==` and `hashCode`. This is inconsistent with the other DOM nodes, and the provided implementation might not have the desired behavior.
* Improved error reporting when accessing `innerText` or `innerXml` on DOM nodes that cannot have children.

## 6.1.0

* Dart 2.17 requirement.
* Validate the presence and order of root nodes when parsing; this got lost in 6.0.0 and can now also optionally be enabled for streaming and iterable parsers.
* Add support for basic document type parsing. The contents of the `XmlDoctype` can now be accessed through `name`, `externalId` and `internalSubset`.

## 6.0.0 

* Significantly improve parsing performance by up to 30%.
* Improved error handling to include more information, such as tag names and location in the parsed source.
* Use the pull-based parser for all underlying parsing operations:
  * Reduce size of library by removing duplicated parsing and validation functionality.
  * Fix entity decoding if the entity spawns multiple chunks.
* Cleanup dynamic calls and type declarations:
  * Avoid all dynamic calls across the library (thanks to [srawlins](https://github.com/srawlins)).
  * Remove deprecated `XmlTransformer` as it requires dynamic calls in the `XmlVisitor`.
  * Cleanup the dynamic typing of `XmlVisitor`.
* `XmlBuilder` keeps keeps correct nesting, even in case of exceptions.
* Remove deprecated code:
  * `parse(String input)`: use `XmlDocument.parse(String input)` or `XmlDocumentFragment.parse(String input)` instead.
  * `XmlBuilder.build()`: use `XmlBuilder.buildDocument()` or `XmlBuilder.buildFragment()` instead.
  * `XmlNormalizer.defaultInstance`: use `const XmlNormalizer()` instead.  
  * `XmlProductionDefinition`, `XmlGrammarDefinition`, and `XmlParserDefinition`.

## 5.4.0

* Dart 2.16 requirement.
* Update to PetitParser 5.0.
* Escape control characters (thanks to [rspilker](https://github.com/rspilker)).
* Add a predicate to pretty printer to insert a space character before self-closing elements (thanks to [rspilker](https://github.com/rspilker)).
* Add predicates to normalizer to trim leading and trailing whitespaces, as well as collapse consecutive whitespaces.
* Expose `qualifiedName`, `localName`, `namespacePrefix` and `namespaceUri` for convenience on the named nodes.

## 5.3.0

* Dart 2.15 requirement.
* Upgrade to PetitParser 4.3.

## 5.2.0

* A series of read-only accessors that simplify navigating the XML DOM with `XmlElements`:
  * Add `XmlNode.childElements`.
  * Add `XmlNode.siblings` and `XmlNode.siblingElements`.
  * Add `XmlNode.previousElementSibling` and `XmlNode.nextElementSibling`. 
  * Add `XmlNode.ancestorElements`, `XmlNode.precedingElements`, `XmlNode.descendantElements`, and `XmlNode.followingElements`.

## 5.1.1

* Fix printing of Exceptions.
* Fix parsing of DOCTYPE tags.

## 5.1.0

* Upgrade to PetitParser 4.1.0.

## 5.0.0

* Dart 2.12 requirement and null-safety.
* Add the possibility to `XmlBuilder` to add raw strings.
* Improve error reporting (particularly for fragment parsing).
* Default entity mapping is now a global setting.
* Improve tutorials and documentation.

## 4.5.0

* Fixed a bug in the XML name parsing where certain unicode planes were not correctly recognized.
* Removed const constructor from `XmlEvent` to be able to add a lazy initialized `parentEvent` field.
* Add `XmlWithParentEvents` that provides validation of event nesting and efficient access to the parent events. Use `stream.withParentEvents()` to annotate the stream accordingly.
* Add namespace resolution to events through `event.namespaceUri`. Note that the data is only available when the parent information is present (see above).
* Fix namespace resolutions for events in selected sub-tree nodes, even if the namespace declaration is not part of the visible DOM.
* Add `stream.forEachEvent(onText: ...)` for easier callback based stream processing.

## 4.4.0

* Add a `XmlSubtreeSelector` that allows efficient filtering of events in specific sub-trees. Use `stream.selectSubtreeEvents(...)` to filter the stream accordingly.
* Add more options to XML pretty printer, namely the possibility to sort and indent attributes.
* Add typed extension methods for all stream converters, for simpler and more fluent API.
* Improvements to documentation and examples.

## 4.3.0

* Improve error reporting of `XmlBuilder` and add possibility to build `XmlDocumentFragments`.
* Improvements to documentation and examples.

## 4.2.0

* Deprecate standalone `XmlDocument parse(String input)` method, and introduce factory methods in the respective nodes `XmlDocument.parse(String input)` and `XmlDocumentFragment.parse(String input)`.
* Introduce getters and setters for `XmlNode.innerText` (in most cases an alias to `XmlNode.text`), `XmlNode.innerXml` and `XmlNode.outerXml`.
* Improved support for `XmlDocumentFragment` across the library.
* Remove the `XmlDocument.text` override, which returned `null`.
* Add `XmlNode.replace(XmlNode other)` to make it easier to replace nodes in an existing tree.
* Add `XmlNode.getElement(String name)` as a shortcut to find the first child element with a given name.
* Add `XmlNode.firstElementChild` and `XmlNode.lastElementChild` to easy access the first/last child element.
* Add support to selectively disable whitespace normalization while pretty-printing, for example `document.toXmlString(pretty: true, preserveWhitespace: (node) => node is XmlElement && node.name.local == 'pre')` would keep everything within `<pre>` tags as-is.

## 4.1.0

* Improve the pretty printing and the customization of the pretty printing:
  * `XmlWriter` and `XmlPrettyWriter` are now initialized with optional arguments.
  * Pretty printing now also supports to customize the newline support.
  * Example is updated to also syntax highlight / colorize the output.
* Add full namespace support to attribute accessors `setAttribute` and `removeAttribute`.
* Improved the documentation, particularly started a section on `xml_events` package.

## 4.0.0

* Cleanup the node hierarchy. Specifically removed `XmlOwned` and `XmlParent` that added a lot of complexity and confusion. Instead, introduced dedicated mixins for nodes with attributes (`XmlHasAttributes`), children (`XmlHasChildren`), names (`XmlHasName`) or parents (`XmlHasParent`).
* Introduce `XmlDeclaration` nodes, events and builder to make accessing XML version and encoding simpler.

## 3.7.0

* Update to PetitParser 3.0.0.
* Dart 2.7 compatibility and requirement.

## 3.6.0

* Entity decoding and encoding is now configurable with an `XmlEntityMapping`. All operations that 
  read or write XML can now (optionally) be configured with an entity mapper.
* The default entity mapping used only maps XML entities, as opposed to all HTML entities as in 
  previous versions. To get the old behavior use `XmlDefaultEntityMapping.html5`.
* Made `XmlParserError` a `FormatException` to follow typical Dart exception style. 
* Add an example demonstrating the interaction with HTTP APIs.

## 3.5.0

* Dart 2.3 compatibility and requirement.
* Turn various abstract classes into proper mixins.
* Numerous documentation improvements and code optimizations.
* Add an event parser example.

## 3.4.0

* Dart 2.2 compatibility and requirement.
* Take advantage of PetitParser fast-parse mode:
  * 15-30% faster DOM parsing, and
  * 15-50% faster event parsing.
* Improve error messages and reporting.

## 3.3.0

* New events based parsing in `xml_events`:
  * Lazy event parsing from an XML string into an `Iterable` of `XmlEvent`.
  * Async converters between streams of XML, `XmlEvent` and `XmlNode`.
* Clean up package structure by moving internal packages into the `src/` subtree.
* Remove the experimental SAX parser, the event parser allows more flexible streaming XML consumption.

## 3.2.4

* Remove unnecessary whitespace when printing self-closing tags.
* Remember if an element is self-closing for stable printing.

## 3.2.0

* Migrated to PetitParser 2.0

## 3.1.0

* Drop Dart 1.0 compatibility
* Cleanup, optimization and improved documentation
* Add experimental support for SAX parsing

## 3.0.0

* Mutable DOM
* Cleaned up documentation
* Dart 2.0 strong mode compatibility
* Reformatted using dartfmt

## 2.6.0

* Fix CDATA encoding
* Migrate to micro libraries
* Fixed linter issues

## 2.5.0

* Generic Method syntax with Dart 1.21

## 2.4.5

* Do no longer use `ArgumentError`, but instead use proper exceptions.

## 2.4.4

* Fixed attribute escaping
* Preserve single and double quotes

## 2.4.3

* Improved documentation

## 2.4.2

* Use enum as the node type

## 2.4.1

* Fixed attribute escaping

## 2.4.0

* Fixed linter issues
* Cleanup node hierarchy

## 2.3.2

* Improved documentation

## 2.3.1

* Improved test coverage

## 2.3.0

* Improved comments
* Optimize namespaces

## 2.2.2

* Formatted source

## 2.2.1

* Cleanup pretty printing

## 2.2.0

* Improved comments
