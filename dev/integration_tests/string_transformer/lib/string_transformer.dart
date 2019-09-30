
import 'package:kernel/ast.dart';

class KernelTransformer extends Transformer {
  @override
  TreeNode visitStringLiteral(StringLiteral node) {
    node.value = '${node.value}-HEELO';
    return node;
  }
}

