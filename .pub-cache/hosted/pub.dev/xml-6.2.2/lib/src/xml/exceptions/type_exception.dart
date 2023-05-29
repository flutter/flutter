import '../enums/node_type.dart';
import '../mixins/has_children.dart';
import '../nodes/node.dart';
import 'exception.dart';

/// Exception thrown when an unsupported node type is used.
class XmlNodeTypeException extends XmlException {
  /// Creates a new XmlNodeTypeException.
  XmlNodeTypeException(super.message,
      {required this.node, required this.types});

  /// Ensure that [node] is of one of the provided [types].
  static void checkValidType(XmlNode node, Iterable<XmlNodeType> types) {
    if (!types.contains(node.nodeType)) {
      throw XmlNodeTypeException(
        'Got ${node.nodeType}, but expected one of ${types.join(', ')}',
        node: node,
        types: types,
      );
    }
  }

  /// Ensure that [node] can have children.
  static void checkHasChildren(XmlNode node) {
    if (node is! XmlHasChildren) {
      throw XmlNodeTypeException(
        '${node.nodeType} cannot have child nodes.',
        node: node,
        types: const [],
      );
    }
  }

  /// The unsupported node.
  final XmlNode node;

  /// The expected node types.
  final Iterable<XmlNodeType> types;

  @override
  String toString() => 'XmlNodeTypeException: $message';
}
