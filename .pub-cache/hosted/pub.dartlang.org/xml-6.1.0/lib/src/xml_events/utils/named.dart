import '../../xml/utils/namespace.dart';
import '../../xml/utils/token.dart';
import '../annotations/has_parent.dart';
import '../events/start_element.dart';

/// Mixin with additional accessors for named objects.
mixin XmlNamed implements XmlHasParent {
  /// The fully qualified name.
  String get name;

  /// The fully qualified name (alias to name).
  String get qualifiedName => name;

  /// The namespace prefix, or `null`.
  String? get namespacePrefix {
    final index = name.indexOf(XmlToken.namespace);
    return index > 0 ? name.substring(0, index) : null;
  }

  /// The namespace URI, or `null`. Can only be resolved when the named entity
  /// has complete and up-to-date [XmlHasParent.parent] information.
  String? get namespaceUri {
    // Identify the prefix and local name to match.
    final index = name.indexOf(XmlToken.namespace);
    final prefix = index < 0 ? null : xmlns;
    final local = index < 0 ? xmlns : name.substring(0, index);
    // Identify the start element to match.
    final start =
        this is XmlStartElementEvent ? this as XmlStartElementEvent : parent;
    // Walk up the tree to find the matching namespace.
    for (var event = start; event != null; event = event.parent) {
      for (final attribute in event.attributes) {
        if (attribute.namespacePrefix == prefix &&
            attribute.localName == local) {
          return attribute.value;
        }
      }
    }
    // Namespace could not be identified.
    return null;
  }

  /// The local name, excluding the namespace prefix.
  String get localName {
    final index = name.indexOf(XmlToken.namespace);
    return index > 0 ? name.substring(index + 1) : name;
  }
}
