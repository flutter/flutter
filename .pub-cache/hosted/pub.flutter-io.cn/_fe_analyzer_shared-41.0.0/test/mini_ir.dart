// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file implements a miniature string-based internal representation ("IR")
// of Dart code suitable for use in unit testing.

import 'package:test/test.dart';

import 'mini_ast.dart';

/// Stack-based builder class allowing construction of a miniature string-based
/// internal representation ("IR") of Dart code suitable for use in unit
/// testing.
class MiniIrBuilder {
  /// Set this to `true` to enable print-based tracing of stack operations.
  static const bool _debug = false;

  /// If [_debug] is enabled, number of outstanding calls to [guard].  This
  /// controls indentation of debug output.
  int _guardDepth = 0;

  /// Number of labels allocated so far.
  int _labelCounter = 0;

  /// Size threshold for [_stack].  [_pop] and [_popList] will cause a test
  /// failure if an attempt is made to reduce the stack size to less than this
  /// amount.  See [guard].
  int _popLimit = 0;

  /// Stack of partially built IR nodes.
  final _stack = <String>[];

  /// Number of temporaries allocated so far.
  int _tmpCounter = 0;

  /// Creates a fresh [MiniIrLabel] representing a label that can be used as a
  /// break target.
  ///
  /// See [labeled].
  MiniIrLabel allocateLabel() => MiniIrLabel._();

  /// Pops the top node from the stack (which should represent an expression)
  /// and creates a fresh [MiniIrTmp] representing a temporary variable whose
  /// initializer is that expression.
  ///
  /// See [let].
  MiniIrTmp allocateTmp() {
    return MiniIrTmp._('t${_tmpCounter++}', _pop());
  }

  /// Pops the top [numArgs] nodes from the stack and pushes a node that
  /// combines them using [name].  For example, if the stack contains `1, 2, 3`,
  /// calling `apply('f', 2)` results in a stack of `1, f(2, 3)`.
  void apply(String name, int numArgs) =>
      _push('$name(${_popList(numArgs).join(', ')})');

  /// Pushes a node on the stack representing a single atomic expression (for
  /// example a literal value or a variable reference).
  void atom(String name) => _push(name);

  /// Verifies that the top node on the stack matches [expectedIr] exactly.
  void check(String expectedIr) {
    expect(_stack.last.toString(), expectedIr);
  }

  /// Pushes a node representing a `for-in` loop onto the stack, using a loop
  /// variable, iterable expression, and loop body obtained from the stack.
  ///
  /// If [tmp] is non-null, it is used as the loop variable instead of obtaining
  /// it from the stack.
  void forIn(MiniIrTmp? tmp, {required bool isAsynchronous}) {
    var name = isAsynchronous ? 'forIn_async' : 'forIn';
    var body = _pop();
    var iterable = _pop();
    var variable = tmp == null ? _pop() : tmp._name;
    _push('$name($variable, $iterable, $body)');
  }

  /// Executes [callback], checking that it leaves all nodes presently on the
  /// stack untouched, and results in exactly one node being added to the stack.
  T guard<T>(Node node, T Function() callback) {
    if (_debug) {
      print('  ' * _guardDepth++ + '$node');
    }
    int previousStackDepth = _stack.length;
    int previousPopLimit = _popLimit;
    _popLimit = previousStackDepth;
    var result = callback();
    var stackDelta = _stack.length - previousStackDepth;
    if (stackDelta != 1) {
      fail('Stack delta of $stackDelta while visiting '
          '${node.runtimeType} $node\n'
          'Stack: $this');
    }
    if (_debug) {
      print('  ' * --_guardDepth + '=> ${_stack.last}');
    }
    _popLimit = previousPopLimit;
    return result;
  }

  /// Pushes a node representing an "if not null" check onto the stack, using
  /// [tmp] and an expression obtained from the stack.  The intended semantics
  /// are `tmp == null ? null : <expression>`.
  ///
  /// This is intended to be used as a building block for null shorting
  /// operations.
  void ifNotNull(MiniIrTmp tmp) {
    _push('if(==(${tmp._name}, null), null, ${_pop()})');
    let(tmp);
  }

  /// Pushes a node representing an "if null" check onto the stack, using [tmp]
  /// and two expressions obtained from the stack.  The intended semantics
  /// are `tmp == null ? <expression 1> : <expression 2>`.
  ///
  /// This is intended to be used as a building block for null `??` and `??=`
  /// operations.
  void ifNull(MiniIrTmp tmp) {
    var ifNull = _pop();
    var ifNotNull = _pop();
    _push('if(==(${tmp._name}, null), $ifNull, $ifNotNull)');
    let(tmp);
  }

  /// Pushes a node representing a call to `operator[]` onto the stack, using
  /// a receiver and an index obtained from the stack.
  void indexGet() => apply('[]', 2);

  /// Pushes a node representing a call to `operator[]=` onto the stack, using
  /// a receiver, index, and value obtained from the stack.
  ///
  /// If [receiverTmp] and/or [indexTmp] is non-null, they are used instead of
  /// obtaining values from the stack.
  void indexSet(MiniIrTmp? receiverTmp, MiniIrTmp? indexTmp) {
    var value = _pop();
    var index = indexTmp == null ? _pop() : indexTmp._name;
    var receiver = receiverTmp == null ? _pop() : receiverTmp._name;
    _push('[]=($receiver, $index, $value)');
  }

  /// Pushes a node representing a labeled statement onto the stack, using an
  /// inner statement obtained from the stack.
  ///
  /// To build up a statement of the form `labeled(L0, stmt)` (where `stmt`
  /// might refer to `L0`), do the following operations:
  /// - Call [allocateLabel] to prepare the label.
  /// - build `stmt` on the stack, using [referToLabel] to refer to label as
  ///   needed.
  /// - Call [labeled] to build the final `labeled` statement.
  void labeled(MiniIrLabel label) {
    var name = label._name;
    if (name != null) {
      _push('labeled($name, ${_pop()})');
    }
  }

  /// Pushes a node representing a `let` expression onto the stack, using a
  /// value obtained from the stack.
  ///
  /// To build up an expression of the form `let(#0, value, expr)` (meaning
  /// "let temporary variable #0 take on value while evaluating expr"), do the
  /// following operations:
  /// - Build `value` on the stack.
  /// - Call [allocateTmp] to pop `value` off the stack and obtain a
  ///   [MiniIrTmp] object.  This will assign the temporary variable a name that
  ///   doesn't conflict with any other outstanding temporary variables.
  /// - Build `expr` on the stack, using [readTmp] to refer to the temporary
  ///   variable as needed.
  /// - Call [let] to build the final `let` expression.
  void let(MiniIrTmp tmp) {
    _push('let(${tmp._name}, ${tmp._value}, ${_pop()})');
  }

  /// Pushes a node representing a property get onto the stack, using a receiver
  /// obtained from the stack.
  void propertyGet(String propertyName) => apply('get_$propertyName', 1);

  /// Pushes a node representing a property set onto the stack, using a receiver
  /// and value obtained from the stack.
  ///
  /// If [receiverTmp] is non-null, it is used as the receiver rather than
  /// obtaining it from the stack.
  void propertySet(MiniIrTmp? receiverTmp, String propertyName) {
    var value = _pop();
    var receiver = receiverTmp == null ? _pop() : receiverTmp._name;
    _push('set_$propertyName($receiver, $value)');
  }

  /// Pushes a node representing a read of [tmp] onto the stack.
  void readTmp(MiniIrTmp tmp) => _push(tmp._name);

  /// Pushes a node representing a reference to [label] onto the stack.
  void referToLabel(MiniIrLabel label) {
    _push(label._name ??= 'L${_labelCounter++}');
  }

  @override
  String toString() => _stack.join(', ');

  /// Pushes a node representing a read of a local variable onto the stack.
  void variableGet(Var v) => atom(v.name);

  /// Pushes a node representing a set of a local variable onto the stack, using
  /// a value obtained from the stack.
  void variableSet(Var v) => apply('${v.name}=', 1);

  /// Pops a single node off the stack.
  String _pop() {
    expect(_stack.length, greaterThan(_popLimit));
    return _stack.removeLast();
  }

  /// Pops a list of nodes off the stack.
  List<String> _popList(int count) {
    var newLength = _stack.length - count;
    expect(newLength, greaterThanOrEqualTo(_popLimit));
    var result = _stack.sublist(newLength);
    _stack.length = newLength;
    return result;
  }

  /// Pushes a node onto the stack.
  void _push(String node) => _stack.add(node);
}

/// Representation of a branch target label used by [MiniIrBuilder] when
/// building up `labeled` statements.
class MiniIrLabel {
  /// The name of the label, or `null` if no name has been assigned yet.
  String? _name;

  MiniIrLabel._();
}

/// Representation of a temporary variable used by [MiniIrBuilder] when building
/// up `let` expressions.
class MiniIrTmp {
  /// The name of the temporary variable.
  final String _name;

  /// The initial value of the temporary variable.
  final String _value;

  MiniIrTmp._(this._name, this._value);
}
