// ignore_for_file: specify_nonobvious_local_variable_types, omit_obvious_local_variable_types, always_put_control_body_on_new_line, sort_constructors_first, inference_failure_on_function_return_type, directives_ordering
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

void main() {
  final result = parseString(content: '''
void test(String name, void Function() body, {bool skip = false}) {}
void main() {
  test('a test', () {}, skip: true); // ERROR
}
''');

  final lineInfo = result.lineInfo;
  final content = result.content;
  var found = false;

  result.unit.visitChildren(_Visitor((node) {
    found = true;
    final int offset = node.offset;
    final String textAfterNode = content.substring(
      offset,
      lineInfo.getOffsetOfLineAfter(offset) - 1,
    );
    print('textAfterNode: "$textAfterNode"');

    final pattern = RegExp(r'// .*\[intended\]');
    print('Matched? ${textAfterNode.contains(pattern)}');
  }));
  print('found visits: $found');
}

class _Visitor extends RecursiveAstVisitor<void> {
  final Function(AstNode) onSkip;
  _Visitor(this.onSkip);
  @override
  void visitNamedExpression(NamedExpression node) {
    if (node.name.label.name == 'skip') onSkip(node.name.label);
    super.visitNamedExpression(node);
  }
}
