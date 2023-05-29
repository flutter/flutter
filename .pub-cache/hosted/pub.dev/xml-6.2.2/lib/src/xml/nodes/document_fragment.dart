import '../../../xml_events.dart';
import '../entities/entity_mapping.dart';
import '../exceptions/parser_exception.dart';
import '../mixins/has_children.dart';
import '../visitors/visitor.dart';
import 'node.dart';

/// XML document fragment node.
class XmlDocumentFragment extends XmlNode with XmlHasChildren<XmlNode> {
  /// Return an [XmlDocumentFragment] for the given [input] string, or throws an
  /// [XmlParserException] if the input is invalid.
  ///
  /// Note: It is the responsibility of the caller to provide a standard Dart
  /// [String] using the default UTF-16 encoding.
  factory XmlDocumentFragment.parse(
    String input, {
    XmlEntityMapping? entityMapping,
  }) {
    final events = parseEvents(
      input,
      entityMapping: entityMapping,
      validateNesting: true,
    );
    return XmlDocumentFragment(XmlNodeDecoder().convertIterable(events));
  }

  /// Create a document fragment node with `children`.
  XmlDocumentFragment([Iterable<XmlNode> childrenIterable = const []]) {
    children.initialize(this, childrenNodeTypes);
    children.addAll(childrenIterable);
  }

  @override
  XmlNodeType get nodeType => XmlNodeType.DOCUMENT_FRAGMENT;

  @override
  XmlDocumentFragment copy() =>
      XmlDocumentFragment(children.map((each) => each.copy()));

  @override
  void accept(XmlVisitor visitor) => visitor.visitDocumentFragment(this);
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
