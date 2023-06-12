import '../mixins/has_parent.dart';
import '../nodes/node.dart';
import 'exception.dart';

/// Exception thrown when the parent relationship between nodes is invalid.
class XmlParentException extends XmlException {
  /// Creates a new XmlParentException.
  XmlParentException(super.message, {required this.node, this.parent});

  /// Ensure that [node] has no parent.
  static void checkNoParent(XmlParentBase node) {
    if (node.parent != null) {
      throw XmlParentException(
        'Node already has a parent, copy or remove it first',
        node: node,
        parent: node.parent,
      );
    }
  }

  /// Ensure that [node] has a matching parent.
  static void checkMatchingParent(XmlParentBase node, XmlNode parent) {
    if (node.parent != parent) {
      // If this exception is ever thrown, this is likely a bug in the internal
      // code of the library.
      throw XmlParentException(
        'Node already has a non-matching parent',
        node: node,
        parent: parent,
      );
    }
  }

  final XmlParentBase node;
  final XmlNode? parent;

  @override
  String toString() => 'XmlParentException: $message';
}
