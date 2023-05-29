Dart XML
========

[![Pub Package](https://img.shields.io/pub/v/xml.svg)](https://pub.dev/packages/xml)
[![Build Status](https://github.com/renggli/dart-xml/actions/workflows/dart.yml/badge.svg?branch=main)](https://github.com/renggli/dart-xml/actions/workflows/dart.yml)
[![Code Coverage](https://codecov.io/gh/renggli/dart-xml/branch/main/graph/badge.svg?token=TDwmzZtPdj)](https://codecov.io/gh/renggli/dart-xml)
[![GitHub Issues](https://img.shields.io/github/issues/renggli/dart-xml.svg)](https://github.com/renggli/dart-xml/issues)
[![GitHub Forks](https://img.shields.io/github/forks/renggli/dart-xml.svg)](https://github.com/renggli/dart-xml/network)
[![GitHub Stars](https://img.shields.io/github/stars/renggli/dart-xml.svg)](https://github.com/renggli/dart-xml/stargazers)
[![GitHub License](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/renggli/dart-xml/main/LICENSE)

Dart XML is a lightweight library for parsing, traversing, querying, transforming and building XML documents.

This library is open source, stable and well tested. Development happens on [GitHub](https://github.com/renggli/dart-xml). Feel free to report issues or create a pull-request there. General questions are best asked on [StackOverflow](https://stackoverflow.com/questions/tagged/xml+dart).

The package is hosted on [dart packages](https://pub.dev/packages/xml). Up-to-date [class documentation](https://pub.dev/documentation/xml/latest/) is created with every release.


Tutorial
--------

### Installation

Follow the installation instructions on [dart packages](https://pub.dev/packages/xml/install).

Import the library into your Dart code using:

```dart
import 'package:xml/xml.dart';
```

:warning: This library makes extensive use of [static extension methods](https://dart.dev/guides/language/extension-methods). If you [import the library](https://dart.dev/guides/language/language-tour#using-libraries) using a _library prefix_ or only _selectively show classes_ you might miss some of its functionality. For historical reasons public classes have an `Xml` prefix, so conflicts with other code should be rare.

### Reading and Writing

To read XML input use the factory method `XmlDocument.parse(String input)`:

```dart
final bookshelfXml = '''<?xml version="1.0"?>
    <bookshelf>
      <book>
        <title lang="en">Growing a Language</title>
        <price>29.99</price>
      </book>
      <book>
        <title lang="en">Learning XML</title>
        <price>39.95</price>
      </book>
      <price>132.00</price>
    </bookshelf>''';
final document = XmlDocument.parse(bookshelfXml);
```

The resulting object is an instance of `XmlDocument`. In case the document cannot be parsed, a `XmlException` is thrown.

To write back the parsed XML document, simply call `toString()` or `toXmlString(...)` if you need more control:

```dart
print(document.toString());
print(document.toXmlString(pretty: true, indent: '\t'));
```

To read XML from a file use the [dart:io](https://api.dart.dev/dart-io/dart-io-library.html) library:

```dart
final file = new File('bookshelf.xml');
final document = XmlDocument.parse(file.readAsStringSync());
```

If your file is not _UTF-8_ encoded pass the correct encoding to `readAsStringSync`. It is the responsibility of the caller to provide a standard Dart [String] using the default UTF-16 encoding. To read and write large files you might want to use the [event-driven API](#event-driven) instead.

### Traversing and Querying

Accessors allow accessing nodes in the XML tree:

- `attributes` returns the attributes of the node.
- `children` returns the direct children of the node.

Both lists are mutable and support all common `List` methods, such as `add(XmlNode)`, `addAll(Iterable<XmlNode>)`, `insert(int, XmlNode)`, and `insertAll(int, Iterable<XmlNode>)`. Trying to add a `null` value or an unsupported node type throws an `XmlNodeTypeError` error. Nodes that are already part of a tree _are not_ automatically moved, you need to first create a copy as otherwise an `XmlParentError` is thrown. `XmlDocumentFragment` nodes are automatically expanded and copies of their children are added.

There are methods to traverse the XML tree along different axes:

- `siblings` returns an iterable over the nodes at the same level that preceed and follow this node in document order.
- `preceding` returns an iterable over nodes preceding the opening tag of the current node in document order.
- `descendants` returns an iterable over the descendants of the current node in document order. This includes the attributes of the current node, its children, the grandchildren, and so on.
- `following` the nodes following the closing tag of the current node in document order.
- `ancestors` returns an iterable over the ancestor nodes of the current node, that is the parent, the grandparent, and so on. Note that this is the only iterable that traverses nodes in reverse document order.

For example, the `descendants` iterator could be used to extract all textual contents from an XML tree:

```dart
final textual = document.descendants
    .where((node) => node is XmlText && node.text.trim().isNotEmpty)
    .join('\n');
print(textual);
```

There are convenience helpers to filter by element nodes only: `childElements`, `siblingElements`, `precedingElements`, `descendantElements`, `followingElements`, and `ancestorElements`.

Additionally, there are helpers to find elements with a specific tag:

- `getElement(String name)` finds the first direct child with the provided tag `name`, or `null`.
- `findElements(String name)` finds direct children of the current node with the provided tag `name`.
- `findAllElements(String name)` finds direct and indirect children of the current node with the provided tag `name`.

For example, to find all the nodes with the _&lt;title&gt;_ tag you could write:

```dart
final titles = document.findAllElements('title');
```

The above code returns a lazy iterator that recursively walks the XML document and yields all the element nodes with the requested tag name. To extract the textual contents call `text`:

```dart
titles
    .map((node) => node.text)
    .forEach(print);
```

This prints _Growing a Language_ and _Learning XML_.

Similarly, to compute the total price of all the books one could write the following expression:

```dart
final total = document.findAllElements('book')
    .map((node) => double.parse(node.findElements('price').single.text))
    .reduce((a, b) => a + b);
print(total);
```

Note that this first finds all the books, and then extracts the price to avoid counting the price tag that is included in the bookshelf.

### Building

While it is possible to instantiate and compose `XmlDocument`, `XmlElement` and `XmlText` nodes manually, the `XmlBuilder` provides a simple fluent API to build complete XML trees. To create the above bookshelf example one would write:

```dart
final builder = XmlBuilder();
builder.processing('xml', 'version="1.0"');
builder.element('bookshelf', nest: () {
  builder.element('book', nest: () {
    builder.element('title', nest: () {
      builder.attribute('lang', 'en');
      builder.text('Growing a Language');
    });
    builder.element('price', nest: 29.99);
  });
  builder.element('book', nest: () {
    builder.element('title', nest: () {
      builder.attribute('lang', 'en');
      builder.text('Learning XML');
    });
    builder.element('price', nest: 39.95);
  });
  builder.element('price', nest: '132.00');
});
final document = builder.buildDocument();
```

The `element` method supports optional named arguments:

- The most common is the `nest:` argument which is used to insert contents into the element. In most cases this will be a function that calls more methods on the builder to define attributes, declare namespaces and add child elements. However, the argument can also be a string or an arbitrary Dart object that is converted to a string and added as a text node.
- While attributes can be defined from within the element, for simplicity there is also an argument `attributes:` that takes a map to define simple name-value pairs.
- Furthermore, we can provide a URI as the namespace of the element using `namespace:` and declare new namespace prefixes using `namespaces:`. For details see the documentation of the method.

The builder pattern allows you to easily extract repeated parts into specific methods. In the example above, one could put the part writing a book into a separate method as follows:

```dart
void buildBook(XmlBuilder builder, String title, String language, num price) {
  builder.element('book', nest: () {
    builder.element('title', nest: () {
      builder.attribute('lang', language);
      builder.text(title);
    });
    builder.element('price', nest: price);
  });
}
```

The above `buildDocument()` method returns the built document. To attach built nodes into an existing XML document, use `buildFragment()`. Once the builder returns the built node, its internal state is reset.

```dart
final builder = XmlBuilder();
buildBook(builder, 'The War of the Worlds', 'en', 12.50);
buildBook(builder, 'Voyages extraordinaries', 'fr', 18.20);
document.rootElement.children.add(builder.buildFragment());
```

### Event-driven

Reading large XML files and instantiating their DOM into the memory can be expensive. As an alternative this library provides the possibility to read and transform XML documents as a sequence of events using Dart Iterables or [Streams](https://dart.dev/tutorials/language/streams). These approaches are comparable to event-driven SAX parsing known from other libraries.

```dart
import 'package:xml/xml_events.dart';
```

#### Iterables

In the simplest case you can get a `Iterable<XmlEvent>` over the input string using the following code. This parses the input lazily, and only parses input when requested:

```dart
parseEvents(bookshelfXml)
    .whereType<XmlTextEvent>()
    .map((event) => event.text.trim())
    .where((text) => text.isNotEmpty)
    .forEach(print);
```

The function `parseEvents` supports various other options, see [its documentation](https://pub.dev/documentation/xml/latest/xml_events/parseEvents.html) for further examples.

This approach requires the whole input to be available at the beginning and does not work if the data itself is only available asynchronous, such as coming from a slow network connection. A more flexible, but also more complicated API is provided with [Dart Streams](https://dart.dev/tutorials/language/streams).

#### Streams

To asynchronously parse and process events directly from a file or HTTP stream use the provided codecs to convert between strings, events and DOM tree nodes:

- Codec: `XmlEventCodec`
  - Decodes a `String ` to a sequence of `XmlEvent ` objects. \
    `Stream<List<XmlEvent>> toXmlEvents()` on `Stream<String>`
  - Encodes a sequence of `XmlEvent ` objects to a `String `. \
    `Stream<String> toXmlString()` on `Stream<List<XmlEvent>>`
- Codec: `XmlNodeCodec`
  - Decodes a sequence of `XmlEvent ` objects to `XmlNode ` objects. \
    `Stream<List<XmlNode>> toXmlNodes()` on `Stream<List<XmlEvent>>`
  - Encodes a sequence of `XmlNode ` objects to `XmlEvent ` objects. \
    `Stream<List<XmlEvent>> toXmlEvents()` on `Stream<List<XmlNode>>`

Various transformations are provided to simplify processing complex streams:

- Normalizes a sequence of `XmlEvent` objects by removing empty and combining adjacent text events. \
  `Stream<List<XmlEvent>> normalizeEvents()` on `Stream<List<XmlEvent>>`
- Annotates `XmlEvent` objects with their parent events that is thereafter accessible through `XmlParented.parentEvent`. Validates the nesting and throws an exception if it is invalid. \
  `Stream<List<XmlEvent>> withParentEvents()` on `Stream<List<XmlEvent>>`
- From a sequence of `XmlEvent` objects filter the event sequences that form sub-trees for which a predicate returns `true`. \
  `Stream<List<XmlEvent>> selectSubtreeEvents(Predicate<XmlStartElementEvent>)` on `Stream<List<XmlEvent>>`
- Flattens a chunked stream of objects to a stream of objects. \
  `Stream<T> flatten()` on `Stream<Iterable<T>>`
- Executes the provided callbacks on each event of this stream. \
  `Future forEachEvent({onText: ...})` on `Stream<XmlEvent>`.

For example, the following snippet downloads data from the Internet, converts the UTF-8 input to a Dart `String`, decodes the stream of characters to `XmlEvent`s, and finally normalizes and prints the events:

```dart
final url = Uri.parse('http://ip-api.com/xml/');
final request = await HttpClient().getUrl(url);
final response = await request.close();
await response
    .transform(utf8.decoder)
    .toXmlEvents()
    .normalizeEvents()
    .forEachEvent(onText: (event) => print(event.text));
```

Similarly, the following snippet extracts sub-trees with location information from a `sitemap.xml` file, converts the XML events to XML nodes, and finally prints out the containing text:

```dart
final file = File('sitemap.xml');
await file.openRead()
    .transform(utf8.decoder)
    .toXmlEvents()
    .normalizeEvents()
    .selectSubtreeEvents((event) => event.name == 'loc')
    .toXmlNodes()
    .expand((nodes) => nodes)
    .forEach((node) => print(node.innerText));
```

A common challenge when processing XML event streams is the lack of hierarchical information, thus it is very hard to figure out parent dependencies such as looking up a namespace URI. The `.withParentEvents()` transformation validates the hierarchy and annotates the events with their parent event. This enables features (such as `parentEvent` and the `namespaceUri` accessor) and makes mapping and selecting events considerably simpler. For example:

```dart
await Stream.fromIterable([shiporderXsd])
    .toXmlEvents()
    .normalizeEvents()
    .withParentEvents()
    .selectSubtreeEvents((event) =>
        event.localName == 'element' &&
        event.namespaceUri == 'http://www.w3.org/2001/XMLSchema')
    .toXmlNodes()
    .expand((nodes) => nodes)
    .forEach((node) => print(node.toXmlString(pretty: true)));
```

Misc
----

### Examples

This package comes with several [examples](https://github.com/renggli/dart-xml/tree/main/example).

Furthermore, there are [numerous packages](https://pub.dev/packages?q=dependency%3Axml) depending on this package.

### Supports

- [x] Standard well-formed XML (and HTML).
- [x] Reading documents using an event based API (SAX).
- [x] Decodes and encodes commonly used character entities.
- [x] Querying, traversing, and mutating API using Dart principles.
- [x] Building XML trees using a builder API.

### Limitations

- [ ] Doesn't validate namespace declarations.
- [ ] Doesn't validate schema declarations.
- [ ] Doesn't parse, apply or enforce the DTD.

### Standards

- [Extensible Markup Language (XML) 1.0](https://www.w3.org/TR/xml/)
- [Namespaces in XML 1.0](https://www.w3.org/TR/xml-names/)
- [W3C DOM4](https://www.w3.org/TR/domcore/)

### History

This library started as an example of the [PetitParser](https://github.com/renggli/PetitParserDart) library. To my own surprise various people started to use it to read XML files. In April 2014 I was asked to replace the original [dart-xml](https://github.com/prujohn/dart-xml) library from John Evans.

### License

The MIT License, see [LICENSE](https://github.com/renggli/dart-xml/raw/main/LICENSE).
