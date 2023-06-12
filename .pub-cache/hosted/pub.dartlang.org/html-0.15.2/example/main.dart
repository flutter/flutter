import 'package:html/dom.dart';
import 'package:html/dom_parsing.dart';
import 'package:html/parser.dart';

void main(List<String> args) {
  var document = parse('''
<body>
  <h2>Header 1</h2>
  <p>Text.</p>
  <h2>Header 2</h2>
  More text.
  <br/>
</body>''');

  // outerHtml output
  print('outer html:');
  print(document.outerHtml);

  print('');

  // visitor output
  print('html visitor:');
  _Visitor().visit(document);
}

// Note: this example visitor doesn't handle things like printing attributes and
// such.
class _Visitor extends TreeVisitor {
  String indent = '';

  @override
  void visitText(Text node) {
    if (node.data.trim().isNotEmpty) {
      print('$indent${node.data.trim()}');
    }
  }

  @override
  void visitElement(Element node) {
    if (isVoidElement(node.localName)) {
      print('$indent<${node.localName}/>');
    } else {
      print('$indent<${node.localName}>');
      indent += '  ';
      visitChildren(node);
      indent = indent.substring(0, indent.length - 2);
      print('$indent</${node.localName}>');
    }
  }

  @override
  void visitChildren(Node node) {
    for (var child in node.nodes) {
      visit(child);
    }
  }
}
