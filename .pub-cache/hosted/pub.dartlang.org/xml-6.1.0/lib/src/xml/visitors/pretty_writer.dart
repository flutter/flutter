import 'package:meta/meta.dart';

import '../mixins/has_attributes.dart';
import '../nodes/attribute.dart';
import '../nodes/document.dart';
import '../nodes/element.dart';
import '../nodes/node.dart';
import '../nodes/text.dart';
import '../utils/functions.dart';
import '../utils/token.dart';
import 'writer.dart';

/// A visitor that writes XML nodes correctly indented and with whitespaces
/// adapted.
class XmlPrettyWriter extends XmlWriter {
  XmlPrettyWriter(
    super.buffer, {
    super.entityMapping,
    int? level,
    String? indent,
    String? newLine,
    this.preserveWhitespace,
    this.indentAttribute,
    this.sortAttributes,
    this.spaceBeforeSelfClose,
  })  : level = level ?? 0,
        indent = indent ?? '  ',
        newLine = newLine ?? '\n';

  int level;
  bool pretty = true;
  final String indent;
  final String newLine;
  final Predicate<XmlNode>? preserveWhitespace;
  final Predicate<XmlAttribute>? indentAttribute;
  final Comparator<XmlAttribute>? sortAttributes;
  final Predicate<XmlNode>? spaceBeforeSelfClose;

  @override
  void visitDocument(XmlDocument node) {
    buffer.write(indent * level);
    writeIterable(normalizeText(node.children), newLine + indent * level);
  }

  @override
  void visitElement(XmlElement node) {
    buffer.write(XmlToken.openElement);
    visit(node.name);
    writeAttributes(node);
    if (node.children.isEmpty && node.isSelfClosing) {
      if (spaceBeforeSelfClose != null && spaceBeforeSelfClose!(node)) {
        buffer.write(' ');
      }
      buffer.write(XmlToken.closeEndElement);
    } else {
      buffer.write(XmlToken.closeElement);
      if (node.children.isNotEmpty) {
        if (pretty) {
          if (preserveWhitespace != null && preserveWhitespace!(node)) {
            pretty = false;
            writeIterable(node.children);
            pretty = true;
          } else if (node.children.every((each) => each is XmlText)) {
            writeIterable(normalizeText(node.children));
          } else {
            level++;
            buffer.write(newLine);
            buffer.write(indent * level);
            writeIterable(
                normalizeText(node.children), newLine + indent * level);
            level--;
            buffer.write(newLine);
            buffer.write(indent * level);
          }
        } else {
          writeIterable(node.children);
        }
      }
      buffer.write(XmlToken.openEndElement);
      visit(node.name);
      buffer.write(XmlToken.closeElement);
    }
  }

  @override
  void writeAttributes(XmlHasAttributes node) {
    for (final attribute in normalizeAttributes(node.attributes)) {
      if (pretty && indentAttribute != null && indentAttribute!(attribute)) {
        buffer.write(newLine);
        buffer.write(indent * (level + 1));
      } else {
        buffer.write(XmlToken.whitespace);
      }
      visit(attribute);
    }
  }

  @protected
  List<XmlAttribute> normalizeAttributes(List<XmlAttribute> attributes) {
    final result = attributes.toList();
    if (sortAttributes != null) {
      result.sort(sortAttributes);
    }
    return result;
  }

  // Normalizes the text nodes within a sequence of nodes. Trims leading and
  // trailing whitespaces, replaces all whitespaces with a clean space, removes
  // duplicated whitespaces, drops empty nodes, and combines consecutive nodes.
  @protected
  List<XmlNode> normalizeText(List<XmlNode> nodes) {
    final result = <XmlNode>[];
    for (final node in nodes) {
      if (node is XmlText) {
        final text =
            node.text.trim().replaceAll(_whitespaceOrLineTerminators, ' ');
        if (text.isNotEmpty) {
          if (result.isNotEmpty && result.last is XmlText) {
            result.last =
                XmlText(result.last.text + XmlToken.whitespace + text);
          } else if (node.text != text) {
            result.add(XmlText(text));
          } else {
            result.add(node);
          }
        }
      } else {
        result.add(node);
      }
    }
    return result;
  }
}

final _whitespaceOrLineTerminators = RegExp(r'\s+');
