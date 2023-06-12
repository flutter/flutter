// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../visitor.dart';

/// The base type for all nodes in a CSS abstract syntax tree.
abstract class TreeNode {
  /// The source code this [TreeNode] represents.
  final SourceSpan? span;

  TreeNode(this.span);

  TreeNode clone();

  /// Classic double-dispatch visitor for implementing passes.
  dynamic visit(VisitorBase visitor);

  /// A multiline string showing the node and its children.
  String toDebugString() {
    var to = TreeOutput();
    var tp = _TreePrinter(to, true);
    visit(tp);
    return to.buf.toString();
  }
}

/// The base type for expressions.
abstract class Expression extends TreeNode {
  Expression(SourceSpan? span) : super(span);
  @override
  Expression clone();
}

/// Simple class to provide a textual dump of trees for debugging.
class TreeOutput {
  int depth = 0;
  final StringBuffer buf = StringBuffer();
  VisitorBase? printer;

  void write(String s) {
    for (var i = 0; i < depth; i++) {
      buf.write(' ');
    }
    buf.write(s);
  }

  void writeln(String s) {
    write(s);
    buf.write('\n');
  }

  void heading(String name, [SourceSpan? span]) {
    write(name);
    if (span != null) {
      buf.write('  (${span.message('')})');
    }
    buf.write('\n');
  }

  String toValue(value) {
    if (value == null) {
      return 'null';
    } else if (value is Identifier) {
      return value.name;
    } else {
      return value.toString();
    }
  }

  void writeNode(String label, TreeNode? node) {
    write('$label: ');
    depth += 1;
    if (node != null) {
      node.visit(printer!);
    } else {
      writeln('null');
    }
    depth -= 1;
  }

  void writeValue(String label, value) {
    var v = toValue(value);
    writeln('$label: $v');
  }

  void writeNodeList(String label, List<TreeNode>? list) {
    writeln('$label [');
    if (list != null) {
      depth += 1;
      for (var node in list) {
        node.visit(printer!);
      }
      depth -= 1;
      writeln(']');
    }
  }

  @override
  String toString() => buf.toString();
}
