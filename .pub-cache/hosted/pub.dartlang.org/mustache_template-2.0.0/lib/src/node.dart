abstract class Node {
  Node(this.start, this.end);

  // The offset of the start of the token in the file. Unless this is a section
  // or inverse section, then this stores the start of the content of the
  // section.
  final int start;
  final int end;

  void accept(Visitor visitor);
  void visitChildren(Visitor visitor) {}
}

abstract class Visitor {
  void visitText(TextNode node);
  void visitVariable(VariableNode node);
  void visitSection(SectionNode node);
  void visitPartial(PartialNode node);
}

class TextNode extends Node {
  TextNode(this.text, int start, int end) : super(start, end);

  final String text;

  @override
  String toString() => '(TextNode "$_debugText" $start $end)';

  String get _debugText {
    var t = text.replaceAll('\n', '\\n');
    return t.length < 50 ? t : t.substring(0, 48) + '...';
  }

  @override
  void accept(Visitor visitor) => visitor.visitText(this);
}

class VariableNode extends Node {
  VariableNode(this.name, int start, int end, {this.escape = true})
      : super(start, end);

  final String name;
  final bool escape;

  @override
  void accept(Visitor visitor) => visitor.visitVariable(this);

  @override
  String toString() => '(VariableNode "$name" escape: $escape $start $end)';
}

class SectionNode extends Node {
  SectionNode(this.name, int start, int end, this.delimiters,
      {this.inverse = false})
      : contentStart = end,
        super(start, end);

  final String name;
  final String delimiters;
  final bool inverse;
  final int contentStart;
  int? contentEnd; // Set in parser when close tag is parsed.
  final List<Node> children = <Node>[];

  @override
  void accept(Visitor visitor) => visitor.visitSection(this);

  @override
  void visitChildren(Visitor visitor) {
    children.forEach((node) => node.accept(visitor));
  }

  @override
  String toString() => '(SectionNode $name inverse: $inverse $start $end)';
}

class PartialNode extends Node {
  PartialNode(this.name, int start, int end, this.indent) : super(start, end);

  final String name;

  // Used to store the preceding whitespace before a partial tag, so that
  // it's content can be correctly indented.
  final String indent;

  @override
  void accept(Visitor visitor) => visitor.visitPartial(this);

  @override
  String toString() => '(PartialNode $name $start $end "$indent")';
}
