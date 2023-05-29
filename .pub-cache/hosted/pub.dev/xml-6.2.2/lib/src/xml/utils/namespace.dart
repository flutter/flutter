import '../nodes/attribute.dart';
import '../nodes/node.dart';

// XML namespace declarations.
const String xml = 'xml';
const String xmlUri = 'http://www.w3.org/XML/1998/namespace';
const String xmlns = 'xmlns';

/// Lookup [XmlAttribute] with the given `prefix` and `local` name by walking up
/// the XML DOM from the provided `start`. Return `null`, if the attribute
/// cannot be found.
XmlAttribute? lookupAttribute(XmlNode? start, String? prefix, String local) {
  for (var node = start; node != null; node = node.parent) {
    for (final attribute in node.attributes) {
      final name = attribute.name;
      if (name.prefix == prefix && name.local == local) {
        return attribute;
      }
    }
  }
  return null;
}

/// Lookup the namespace prefix (possibly an empty string), for the given
/// namespace `uri` by walking up the XML DOM from the provided `start`.
/// Return `null`, if the prefix cannot be found.
String? lookupNamespacePrefix(XmlNode? start, String uri) {
  for (var node = start; node != null; node = node.parent) {
    for (final attribute in node.attributes) {
      if (attribute.value == uri) {
        final name = attribute.name;
        if (name.prefix == xmlns) {
          return name.local;
        } else if (name.prefix == null && name.local == xmlns) {
          return '';
        }
      }
    }
  }
  return null;
}
