import '../enums/node_type.dart';
import '../nodes/document.dart';
import '../nodes/document_fragment.dart';
import '../nodes/element.dart';
import '../nodes/node.dart';
import '../nodes/text.dart';
import '../utils/functions.dart';
import 'visitor.dart';

extension XmlNormalizerExtension on XmlNode {
  /// Puts all child nodes into a "normalized" form, that is no text nodes in
  /// the sub-tree are empty and there are no adjacent text nodes.
  ///
  /// - If the predicate [trimWhitespace] returns `true`, leading and trailing
  ///   whitespace in text nodes are removed.
  /// - If the predicate [collapseWhitespace] returns `true`, consecutive
  ///   whitespace in text nodes are replace with a single space-character.
  void normalize({
    Predicate<XmlText>? trimWhitespace,
    Predicate<XmlText>? collapseWhitespace,
  }) =>
      XmlNormalizer(
        trimWhitespace: trimWhitespace,
        collapseWhitespace: collapseWhitespace,
      ).visit(this);
}

/// Normalizes a node tree in-place.
class XmlNormalizer with XmlVisitor {
  const XmlNormalizer({this.trimWhitespace, this.collapseWhitespace});

  final Predicate<XmlText>? trimWhitespace;
  final Predicate<XmlText>? collapseWhitespace;

  @override
  void visitDocument(XmlDocument node) => _normalize(node.children);

  @override
  void visitDocumentFragment(XmlDocumentFragment node) =>
      _normalize(node.children);

  @override
  void visitElement(XmlElement node) => _normalize(node.children);

  @override
  void visitText(XmlText node) {
    if (trimWhitespace != null && trimWhitespace!(node)) {
      node.text = node.text.trim();
    }
    if (collapseWhitespace != null && collapseWhitespace!(node)) {
      node.text = node.text.replaceAll(_whitespace, ' ');
    }
  }

  void _normalize(List<XmlNode> children) {
    _mergeAdjacent(children);
    children.forEach(visit);
    _removeEmpty(children);
  }

  void _removeEmpty(List<XmlNode> children) {
    for (var i = 0; i < children.length;) {
      final node = children[i];
      if (node.nodeType == XmlNodeType.TEXT && node.text.isEmpty) {
        children.removeAt(i);
      } else {
        i++;
      }
    }
  }

  void _mergeAdjacent(List<XmlNode> children) {
    XmlText? previousText;
    for (var i = 0; i < children.length;) {
      final node = children[i];
      if (node is XmlText) {
        if (previousText == null) {
          previousText = node;
          i++;
        } else {
          previousText.text += node.text;
          children.removeAt(i);
        }
      } else {
        previousText = null;
        i++;
      }
    }
  }
}

final _whitespace = RegExp(r'\s+');
