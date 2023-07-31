import '../../../xml_events.dart';
import '../entities/entity_mapping.dart';
import '../exceptions/parser_exception.dart';
import '../exceptions/tag_exception.dart';
import '../mixins/has_children.dart';
import '../visitors/visitor.dart';
import 'declaration.dart';
import 'doctype.dart';
import 'element.dart';
import 'node.dart';

/// XML document node.
class XmlDocument extends XmlNode with XmlHasChildren<XmlNode> {
  /// Returns an [XmlDocument] for the given [input] string, or throws an
  /// [XmlParserException] or [XmlTagException] if the input is invalid.
  ///
  /// For example, the following code prints `Hello World`:
  ///
  ///    final document = new XmlDocument.parse('<?xml?><root message="Hello World" />');
  ///    print(document.rootElement.getAttribute('message'));
  ///
  /// Note: It is the responsibility of the caller to provide a standard Dart
  /// [String] using the default UTF-16 encoding.
  factory XmlDocument.parse(
    String input, {
    XmlEntityMapping? entityMapping,
  }) {
    final events = parseEvents(
      input,
      entityMapping: entityMapping,
      validateNesting: true,
      validateDocument: true,
    );
    return XmlDocument(XmlNodeDecoder().convertIterable(events));
  }

  /// Create a document node with `children`.
  XmlDocument([Iterable<XmlNode> childrenIterable = const []]) {
    children.initialize(this, childrenNodeTypes);
    children.addAll(childrenIterable);
  }

  /// Return the [XmlDeclaration] element, or `null` if not defined.
  ///
  /// For example the following code prints `<?xml version="1.0">`:
  ///
  ///    var xml = '<?xml version="1.0">'
  ///              '<shelf></shelf>';
  ///    print(XmlDocument.parse(xml).doctypeElement);
  ///
  XmlDeclaration? get declaration {
    for (final node in children) {
      if (node is XmlDeclaration) {
        return node;
      }
    }
    return null;
  }

  /// Return the [XmlDoctype] element, or `null` if not defined.
  ///
  /// For example, the following code prints `<!DOCTYPE html>`:
  ///
  ///    var xml = '<!DOCTYPE html>'
  ///              '<html><body></body></html>';
  ///    print(XmlDocument.parse(xml).doctypeElement);
  ///
  XmlDoctype? get doctypeElement {
    for (final node in children) {
      if (node is XmlDoctype) {
        return node;
      }
    }
    return null;
  }

  /// Return the root [XmlElement] of the document, or throw a [StateError] if
  /// the document has no such element.
  ///
  /// For example, the following code prints `<books />`:
  ///
  ///     var xml = '<?xml version="1.0"?>'
  ///               '<books />';
  ///     print(XmlDocument.parse(xml).rootElement);
  ///
  XmlElement get rootElement {
    for (final node in children) {
      if (node is XmlElement) {
        return node;
      }
    }
    throw StateError('Empty XML document');
  }

  @override
  XmlNodeType get nodeType => XmlNodeType.DOCUMENT;

  @override
  XmlDocument copy() => XmlDocument(children.map((each) => each.copy()));

  @override
  void accept(XmlVisitor visitor) => visitor.visitDocument(this);
}

/// Supported child node types.
const Set<XmlNodeType> childrenNodeTypes = {
  XmlNodeType.CDATA,
  XmlNodeType.COMMENT,
  XmlNodeType.DECLARATION,
  XmlNodeType.DOCUMENT_TYPE,
  XmlNodeType.ELEMENT,
  XmlNodeType.PROCESSING,
  XmlNodeType.TEXT,
};
