import '../nodes/document.dart';
import '../nodes/element.dart';
import '../nodes/node.dart';

extension XmlParentExtension on XmlNode {
  /// Return the root of the tree in which this node is found, whether that's
  /// a document or another element.
  XmlNode get root {
    var current = this;
    while (current.parent != null) {
      current = current.parent!;
    }
    return current;
  }

  /// Return the document that contains this node, or `null` if the node is
  /// not part of a document.
  XmlDocument? get document {
    final node = root;
    return node is XmlDocument ? node : null;
  }

  /// Return the first parent of this node that is of type [XmlElement], or
  /// `null` if there is none.
  XmlElement? get parentElement {
    for (var current = parent; current != null; current = current.parent) {
      if (current is XmlElement) {
        return current;
      }
    }
    return null;
  }

  /// Return the depth of this node in its tree, a root node has depth 0.
  int get depth {
    var result = 0;
    var current = this;
    while (current.parent != null) {
      current = current.parent!;
      result++;
    }
    return result;
  }
}
