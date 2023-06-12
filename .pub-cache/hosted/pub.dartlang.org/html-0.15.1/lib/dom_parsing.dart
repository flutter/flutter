/// This library contains extra APIs that aren't in the DOM, but are useful
/// when interacting with the parse tree.
library dom_parsing;

import 'dom.dart';
import 'html_escape.dart';
import 'src/constants.dart' show rcdataElements;

// Export a function which was previously declared here.
export 'html_escape.dart';

/// A simple tree visitor for the DOM nodes.
class TreeVisitor {
  void visit(Node node) {
    switch (node.nodeType) {
      case Node.ELEMENT_NODE:
        return visitElement(node as Element);
      case Node.TEXT_NODE:
        return visitText(node as Text);
      case Node.COMMENT_NODE:
        return visitComment(node as Comment);
      case Node.DOCUMENT_FRAGMENT_NODE:
        return visitDocumentFragment(node as DocumentFragment);
      case Node.DOCUMENT_NODE:
        return visitDocument(node as Document);
      case Node.DOCUMENT_TYPE_NODE:
        return visitDocumentType(node as DocumentType);
      default:
        throw UnsupportedError('DOM node type ${node.nodeType}');
    }
  }

  void visitChildren(Node node) {
    // Allow for mutations (remove works) while iterating.
    for (var child in node.nodes.toList(growable: false)) {
      visit(child);
    }
  }

  /// The fallback handler if the more specific visit method hasn't been
  /// overriden. Only use this from a subclass of [TreeVisitor], otherwise
  /// call [visit] instead.
  void visitNodeFallback(Node node) => visitChildren(node);

  void visitDocument(Document node) => visitNodeFallback(node);

  void visitDocumentType(DocumentType node) => visitNodeFallback(node);

  void visitText(Text node) => visitNodeFallback(node);

  // TODO(jmesserly): visit attributes.
  void visitElement(Element node) => visitNodeFallback(node);

  void visitComment(Comment node) => visitNodeFallback(node);

  void visitDocumentFragment(DocumentFragment node) => visitNodeFallback(node);
}

/// Converts the DOM tree into an HTML string with code markup suitable for
/// displaying the HTML's source code with CSS colors for different parts of the
/// markup. See also [CodeMarkupVisitor].
String htmlToCodeMarkup(Node node) {
  return (CodeMarkupVisitor()..visit(node)).toString();
}

/// Converts the DOM tree into an HTML string with code markup suitable for
/// displaying the HTML's source code with CSS colors for different parts of the
/// markup. See also [htmlToCodeMarkup].
class CodeMarkupVisitor extends TreeVisitor {
  final StringBuffer _str;

  CodeMarkupVisitor() : _str = StringBuffer();

  @override
  String toString() => _str.toString();

  @override
  void visitDocument(Document node) {
    _str.write('<pre>');
    visitChildren(node);
    _str.write('</pre>');
  }

  @override
  void visitDocumentType(DocumentType node) {
    _str.write('<code class="markup doctype">&lt;!DOCTYPE ${node.name}>'
        '</code>');
  }

  @override
  void visitText(Text node) {
    writeTextNodeAsHtml(_str, node);
  }

  @override
  void visitElement(Element node) {
    final tag = node.localName;
    _str.write('&lt;<code class="markup element-name">$tag</code>');
    if (node.attributes.isNotEmpty) {
      node.attributes.forEach((key, v) {
        v = htmlSerializeEscape(v, attributeMode: true);
        _str.write(' <code class="markup attribute-name">$key</code>'
            '=<code class="markup attribute-value">"$v"</code>');
      });
    }
    if (node.nodes.isNotEmpty) {
      _str.write('>');
      visitChildren(node);
    } else if (isVoidElement(tag)) {
      _str.write('>');
      return;
    }
    _str.write('&lt;/<code class="markup element-name">$tag</code>>');
  }

  @override
  void visitComment(Comment node) {
    final data = htmlSerializeEscape(node.data!);
    _str.write('<code class="markup comment">&lt;!--$data--></code>');
  }
}

/// Returns true if this tag name is a void element.
/// This method is useful to a pretty printer, because void elements must not
/// have an end tag.
/// See also: <http://dev.w3.org/html5/markup/syntax.html#void-elements>.
bool isVoidElement(String? tagName) {
  switch (tagName) {
    case 'area':
    case 'base':
    case 'br':
    case 'col':
    case 'command':
    case 'embed':
    case 'hr':
    case 'img':
    case 'input':
    case 'keygen':
    case 'link':
    case 'meta':
    case 'param':
    case 'source':
    case 'track':
    case 'wbr':
      return true;
  }
  return false;
}

/// Serialize text node according to:
/// <http://www.whatwg.org/specs/web-apps/current-work/multipage/the-end.html#html-fragment-serialization-algorithm>
void writeTextNodeAsHtml(StringBuffer str, Text node) {
  // Don't escape text for certain elements, notably <script>.
  final parent = node.parentNode;
  if (parent is Element) {
    final tag = parent.localName;
    if (rcdataElements.contains(tag) || tag == 'plaintext') {
      str.write(node.data);
      return;
    }
  }
  str.write(htmlSerializeEscape(node.data));
}
