// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file implements a miniature string-based internal representation ("IR")
// of Dart code suitable for use in unit testing.

import 'package:test/test.dart';

import 'mini_ast.dart';

/// A single stack entry representing an intermediate representation of some
/// Dart code produced using the facilities of `mini_ast.dart`.
class IrNode {
  /// The intermediate representation itself, expressed as a string.
  final String ir;

  /// The location of the Dart code that led to this [IrNode].
  final String location;

  /// The kind of entity represented by this [IrNode].
  final Kind kind;

  IrNode({required this.ir, required this.location, required this.kind});

  @override
  String toString() => '$kind $ir ($location)';
}

/// Kinds of entities that can be represented by an [IrNode].
enum Kind {
  /// A single `case` or `default` clause in a switch statement or switch
  /// expression.
  caseHead,

  /// A set of `case` or `default` clauses in a switch statement, which all
  /// share the same body.
  caseHeads,

  /// A collection element.
  collectionElement,

  /// An expression.
  expression,

  /// A single case from a switch expression, consisting of a [caseHead] and a
  /// body [expression].
  expressionCase,

  /// A label for `break` or `continue` to branch to.
  label,

  /// A map pattern element.
  mapPatternElement,

  /// A pattern.
  pattern,

  /// A statement.
  statement,

  /// A single case from a switch statement, consisting of [caseHeads] and body
  /// [statement]s.
  statementCase,

  /// A type in the type system.
  type,

  /// A local variable.
  variable,

  /// A set of pattern variables.
  variables,
}

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
  final _stack = <IrNode>[];

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
    return MiniIrTmp._('t${_tmpCounter++}', _pop(Kind.expression).ir);
  }

  /// Pops the top [numArgs] nodes from the stack and pushes a node that
  /// combines them using [name].  For example, if the stack contains `1, 2, 3`,
  /// calling `apply('f', 2)` results in a stack of `1, f(2, 3)`.
  ///
  /// Optional argument [names] allows applying names to the last n arguments.
  /// For example, if the stack contains `1, 2, 3`, calling
  /// `apply('f', 3, names: ['a', 'b'])` results in a stack of
  /// `f(1, a: 2, b: 3)`.
  void apply(String name, List<Kind> inputKinds, Kind outputKind,
      {required String location, List<String> names = const []}) {
    var args = [
      for (var irNode in _popList(inputKinds.length, inputKinds)) irNode.ir
    ];
    for (int i = 1; i <= names.length; i++) {
      args[args.length - i] =
          '${names[names.length - i]}: ${args[args.length - i]}';
    }
    _push(IrNode(
        ir: '$name(${args.join(', ')})', kind: outputKind, location: location));
  }

  /// Pushes a node on the stack representing a single atomic expression (for
  /// example a literal value or a variable reference).
  void atom(String name, Kind kind, {required String location}) =>
      _push(IrNode(ir: name, kind: kind, location: location));

  /// Verifies that the top node on the stack matches [expectedIr] exactly.
  void check(String expectedIr, Kind expectedKind, {required String location}) {
    expect(_stack.last, _nodeWithKind(expectedKind), reason: 'at $location');
    expect(_stack.last.ir, expectedIr, reason: 'at $location');
  }

  /// Pushes a node representing a `for-in` loop onto the stack, using a loop
  /// variable, iterable expression, and loop body obtained from the stack.
  ///
  /// If [tmp] is non-null, it is used as the loop variable instead of obtaining
  /// it from the stack.
  void forIn(MiniIrTmp? tmp,
      {required String location, required bool isAsynchronous}) {
    var name = isAsynchronous ? 'forIn_async' : 'forIn';
    var body = _pop(Kind.statement);
    var iterable = _pop(Kind.expression);
    var variable = tmp == null ? _pop(Kind.variable) : tmp._name;
    _push(IrNode(
        ir: '$name($variable, $iterable, $body)',
        kind: Kind.statement,
        location: location));
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
  void ifNotNull(MiniIrTmp tmp, {required String location}) {
    _push(IrNode(
        ir: 'if(==(${tmp._name}, null), null, ${_pop(Kind.expression)})',
        kind: Kind.expression,
        location: location));
    let(tmp, location: location);
  }

  /// Pushes a node representing an "if null" check onto the stack, using [tmp]
  /// and two expressions obtained from the stack.  The intended semantics
  /// are `tmp == null ? <expression 1> : <expression 2>`.
  ///
  /// This is intended to be used as a building block for null `??` and `??=`
  /// operations.
  void ifNull(MiniIrTmp tmp, {required String location}) {
    var ifNull = _pop(Kind.expression);
    var ifNotNull = _pop(Kind.expression);
    _push(IrNode(
        ir: 'if(==(${tmp._name}, null), $ifNull, $ifNotNull)',
        kind: Kind.expression,
        location: location));
    let(tmp, location: location);
  }

  /// Pushes a node representing a call to `operator[]` onto the stack, using
  /// a receiver and an index obtained from the stack.
  void indexGet({required String location}) =>
      apply('[]', [Kind.expression, Kind.expression], Kind.expression,
          location: location);

  /// Pushes a node representing a call to `operator[]=` onto the stack, using
  /// a receiver, index, and value obtained from the stack.
  ///
  /// If [receiverTmp] and/or [indexTmp] is non-null, they are used instead of
  /// obtaining values from the stack.
  void indexSet(MiniIrTmp? receiverTmp, MiniIrTmp? indexTmp,
      {required String location}) {
    var value = _pop(Kind.expression);
    var index = indexTmp == null ? _pop(Kind.expression) : indexTmp._name;
    var receiver =
        receiverTmp == null ? _pop(Kind.expression) : receiverTmp._name;
    _push(IrNode(
        ir: '[]=($receiver, $index, $value)',
        kind: Kind.expression,
        location: location));
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
  void labeled(MiniIrLabel label, {required String location}) {
    var name = label._name;
    if (name != null) {
      _push(IrNode(
          ir: 'labeled($name, ${_pop(Kind.statement)})',
          kind: Kind.statement,
          location: location));
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
  void let(MiniIrTmp tmp, {required String location}) {
    _push(IrNode(
        ir: 'let(${tmp._name}, ${tmp._value}, ${_pop(Kind.expression)})',
        kind: Kind.expression,
        location: location));
  }

  /// Pushes a node representing a property get onto the stack, using a receiver
  /// obtained from the stack.
  void propertyGet(String propertyName, {required String location}) =>
      apply('get_$propertyName', [Kind.expression], Kind.expression,
          location: location);

  /// Pushes a node representing a property set onto the stack, using a receiver
  /// and value obtained from the stack.
  ///
  /// If [receiverTmp] is non-null, it is used as the receiver rather than
  /// obtaining it from the stack.
  void propertySet(MiniIrTmp? receiverTmp, String propertyName,
      {required String location}) {
    var value = _pop(Kind.expression);
    var receiver =
        receiverTmp == null ? _pop(Kind.expression) : receiverTmp._name;
    _push(IrNode(
        ir: 'set_$propertyName($receiver, $value)',
        kind: Kind.expression,
        location: location));
  }

  /// Pushes a node representing a read of [tmp] onto the stack.
  void readTmp(MiniIrTmp tmp, {required String location}) =>
      _push(IrNode(ir: tmp._name, kind: Kind.expression, location: location));

  /// Pushes a node representing a reference to [label] onto the stack.
  void referToLabel(MiniIrLabel label, {required String location}) {
    _push(IrNode(
        ir: label._name ??= 'L${_labelCounter++}',
        kind: Kind.label,
        location: location));
  }

  @override
  String toString() => [for (var irNode in _stack) irNode.ir].join(', ');

  /// Pushes a node representing a read of a local variable onto the stack.
  void variableGet(Var v, {required String location}) =>
      atom(v.name, Kind.expression, location: location);

  /// Pushes a node representing a set of a local variable onto the stack, using
  /// a value obtained from the stack.
  void variableSet(Var v, {required String location}) =>
      apply('${v.name}=', [Kind.expression], Kind.expression,
          location: location);

  TypeMatcher<IrNode> _nodeWithKind(Kind expectedKind) =>
      TypeMatcher<IrNode>().having((node) => node.kind, 'kind', expectedKind);

  /// Pops a single node off the stack.
  IrNode _pop(Kind expectedKind) {
    expect(_stack.length, greaterThan(_popLimit));
    var irNode = _stack.removeLast();
    expect(irNode, _nodeWithKind(expectedKind));
    return irNode;
  }

  /// Pops a list of nodes off the stack.
  List<IrNode> _popList(int count, List<Kind> expectedKinds) {
    var newLength = _stack.length - count;
    expect(newLength, greaterThanOrEqualTo(_popLimit));
    var result = _stack.sublist(newLength);
    _stack.length = newLength;
    expect(result,
        [for (var expectedKind in expectedKinds) _nodeWithKind(expectedKind)]);
    return result;
  }

  /// Pushes a node onto the stack.
  void _push(IrNode node) {
    _stack.add(node);
  }
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
