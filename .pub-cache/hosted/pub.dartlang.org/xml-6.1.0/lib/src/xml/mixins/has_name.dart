import '../utils/name.dart';

/// Mixin for all nodes with a name.
mixin XmlHasName {
  /// Return the name of the node.
  XmlName get name;

  /// Return the fully qualified name, including the namespace prefix.
  String get qualifiedName => name.qualified;

  /// Return the local name, excluding the namespace prefix.
  String get localName => name.local;

  /// Return the namespace prefix, or `null`.
  String? get namespacePrefix => name.prefix;

  /// Return the namespace URI, or `null`.
  String? get namespaceUri => name.namespaceUri;
}
