// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'promotion_key_store.dart';

/// [AssignedVariables] is a helper class capable of computing the set of
/// variables that are potentially written to, and potentially captured by
/// closures, at various locations inside the code being analyzed.  This class
/// should be used prior to running flow analysis, to compute the sets of
/// variables to pass in to flow analysis.
///
/// This class is intended to be used in two phases.  In the first phase, the
/// client should traverse the source code recursively, making calls to
/// [beginNode] and [endNode] to indicate the constructs in which writes should
/// be tracked, and calls to [write] to indicate when a write is encountered.
/// The order of visiting is not important provided that nesting is respected.
/// This phase is called the "pre-traversal" because it should happen prior to
/// flow analysis.
///
/// Then, in the second phase, the client may make queries using
/// [capturedAnywhere], [writtenInNode], and [capturedInNode].
///
/// We use the term "node" to refer generally to a loop statement, switch
/// statement, try statement, loop collection element, local function, or
/// closure.
class AssignedVariables<Node extends Object, Variable extends Object> {
  /// Mapping from a node to the info for that node.
  final Map<Node, AssignedVariablesNodeInfo> _info =
      new Map<Node, AssignedVariablesNodeInfo>.identity();

  /// Info for the variables written or captured anywhere in the code being
  /// analyzed.
  final AssignedVariablesNodeInfo anywhere = new AssignedVariablesNodeInfo();

  /// Stack of info for nodes that have been entered but not yet left.
  final List<AssignedVariablesNodeInfo> _stack = [
    new AssignedVariablesNodeInfo()
  ];

  /// When assertions are enabled, the set of info objects that have been
  /// retrieved by [deferNode] but not yet sent to [storeNode].
  final Set<AssignedVariablesNodeInfo> _deferredInfos =
      new Set<AssignedVariablesNodeInfo>.identity();

  /// Keeps track of whether [finish] has been called.
  bool _isFinished = false;

  /// The [PromotionKeyStore], which tracks the unique integer assigned to
  /// everything in the control flow that might be promotable.
  final PromotionKeyStore<Variable> promotionKeyStore =
      new PromotionKeyStore<Variable>();

  /// Indicates whether [finish] has been called.
  bool get isFinished => _isFinished;

  /// This method should be called during pre-traversal, to mark the start of a
  /// loop statement, switch statement, try statement, loop collection element,
  /// local function, closure, or late variable initializer which might need to
  /// be queried later.
  ///
  /// The span between the call to [beginNode] and [endNode] should cover any
  /// statements and expressions that might be crossed by a backwards jump.  So
  /// for instance, in a "for" loop, the condition, updaters, and body should be
  /// covered, but the initializers should not.  Similarly, in a switch
  /// statement, the body of the switch statement should be covered, but the
  /// switch expression should not.
  void beginNode() {
    assert(!_isFinished);
    _stack.add(new AssignedVariablesNodeInfo());
  }

  /// This method should be called during pre-traversal, to indicate that the
  /// declaration of a variable has been found.
  ///
  /// It is not required for the declaration to be seen prior to its use (this
  /// is to allow for error recovery in the analyzer).
  ///
  /// By default, this method contains assertions to make sure the client
  /// doesn't call [declare] more than once on the same variable.  However,
  /// there are some situations where it is difficult for the client to avoid
  /// this, so the check can be disabled by passing `true` for
  /// [ignoreDuplicates].
  void declare(Variable variable, {bool ignoreDuplicates = false}) {
    assert(!_isFinished);
    int variableKey = promotionKeyStore.keyForVariable(variable);
    bool newlyDeclared = _stack.last.declared.add(variableKey);
    assert(ignoreDuplicates || newlyDeclared);
    newlyDeclared = anywhere.declared.add(variableKey);
    assert(ignoreDuplicates || newlyDeclared);
  }

  /// This method may be called during pre-traversal, to mark the end of a
  /// loop statement, switch statement, try statement, loop collection element,
  /// local function, closure, or late variable initializer which might need to
  /// be queried later.
  ///
  /// [isClosureOrLateVariableInitializer] should be true if the node is a local
  /// function or closure, or a late variable initializer.
  ///
  /// In contrast to [endNode], this method doesn't store the data gathered for
  /// the node for later use; instead it returns it to the caller.  At a later
  /// time, the caller should pass the returned data to [storeNodeInfo].
  ///
  /// See [beginNode] for more details.
  AssignedVariablesNodeInfo deferNode(
      {bool isClosureOrLateVariableInitializer = false}) {
    assert(!_isFinished);
    AssignedVariablesNodeInfo info = _stack.removeLast();
    info.read.removeAll(info.declared);
    info.written.removeAll(info.declared);
    info.readCaptured.removeAll(info.declared);
    info.captured.removeAll(info.declared);
    AssignedVariablesNodeInfo last = _stack.last;
    last.read.addAll(info.read);
    last.written.addAll(info.written);
    last.readCaptured.addAll(info.readCaptured);
    last.captured.addAll(info.captured);
    if (isClosureOrLateVariableInitializer) {
      last.readCaptured.addAll(info.read);
      anywhere.readCaptured.addAll(info.read);
      last.captured.addAll(info.written);
      anywhere.captured.addAll(info.written);
    }
    // If we have already deferred this info, something has gone horribly wrong.
    assert(_deferredInfos.add(info));
    return info;
  }

  /// This method may be called during pre-traversal, to discard the effects of
  /// the most recent unmatched call to [beginNode].
  ///
  /// This is necessary because try/catch/finally needs to be desugared into
  /// a try/catch nested inside a try/finally, however the pre-traversal phase
  /// of the front end happens during parsing, so when a `try` is encountered,
  /// it is not known whether it will need to be desugared into two nested
  /// `try`s.  To cope with this, the front end may call [beginNode] twice upon
  /// seeing the two `try`s, and later if it turns out that no desugaring was
  /// needed, use [discardNode] to discard the effects of one of the [beginNode]
  /// calls.
  void discardNode() {
    assert(!_isFinished);
    AssignedVariablesNodeInfo discarded = _stack.removeLast();
    AssignedVariablesNodeInfo last = _stack.last;
    last.declared.addAll(discarded.declared);
    last.read.addAll(discarded.read);
    last.written.addAll(discarded.written);
    last.readCaptured.addAll(discarded.readCaptured);
    last.captured.addAll(discarded.captured);
  }

  /// This method should be called during pre-traversal, to mark the end of a
  /// loop statement, switch statement, try statement, loop collection element,
  /// local function, closure, or late variable initializer which might need to
  /// be queried later.
  ///
  /// [isClosureOrLateVariableInitializer] should be true if the node is a local
  /// function or closure, or a late variable initializer.
  ///
  /// This is equivalent to a call to [deferNode] followed immediately by a call
  /// to [storeInfo].
  ///
  /// See [beginNode] for more details.
  void endNode(Node node, {bool isClosureOrLateVariableInitializer = false}) {
    assert(!_isFinished);
    storeInfo(
        node,
        deferNode(
            isClosureOrLateVariableInitializer:
                isClosureOrLateVariableInitializer));
  }

  /// Call this after visiting the code to be analyzed, to check invariants.
  void finish() {
    assert(() {
      assert(!_isFinished);
      assert(
          _deferredInfos.isEmpty, "Deferred infos not stored: $_deferredInfos");
      assert(_stack.length == 1, "Unexpected stack: $_stack");
      AssignedVariablesNodeInfo last = _stack.last;
      Set<int> undeclaredReads = last.read.difference(last.declared);
      List<Variable?> undeclaredReadVars = [
        for (int key in undeclaredReads) promotionKeyStore.variableForKey(key)
      ];
      assert(undeclaredReadVars.isEmpty,
          'Variables read from but not declared: $undeclaredReadVars');
      Set<int> undeclaredWrites = last.written.difference(last.declared);
      assert(undeclaredWrites.isEmpty,
          'Variables written to but not declared: $undeclaredWrites');
      Set<int> undeclaredCaptures = last.captured.difference(last.declared);
      assert(undeclaredCaptures.isEmpty,
          'Variables captured but not declared: $undeclaredCaptures');
      return true;
    }());
    _isFinished = true;
  }

  /// Queries the information stored for the given [node].
  AssignedVariablesNodeInfo getInfoForNode(Node node) {
    return _info[node] ??
        (throw new StateError('No information for $node (${node.hashCode}) in '
            '{${_info.keys.map((k) => '$k (${k.hashCode})').join(',')}}'));
  }

  /// Call this method between calls to [beginNode] and [endNode]/[deferNode],
  /// if it is necessary to temporarily process some code outside the current
  /// node.  Returns a data structure that should be passed to [pushNode].
  ///
  /// This is used by the front end when building for-elements in lists, maps,
  /// and sets; their initializers are partially built after building their
  /// loop conditions but before completely building their bodies.
  AssignedVariablesNodeInfo popNode() {
    assert(!_isFinished);
    return _stack.removeLast();
  }

  /// Call this method to un-do the effect of [popNode].
  void pushNode(AssignedVariablesNodeInfo node) {
    assert(!_isFinished);
    _stack.add(node);
  }

  void read(Variable variable) {
    assert(!_isFinished);
    int variableKey = promotionKeyStore.keyForVariable(variable);
    _stack.last.read.add(variableKey);
    anywhere.read.add(variableKey);
  }

  /// Call this method to register that the node [from] for which information
  /// has been stored is replaced by the node [to].
  // TODO(johnniwinther): Remove this when unified collections are encoded as
  // general elements in the front-end.
  void reassignInfo(Node from, Node to) {
    assert(!_info.containsKey(to), "Node $to already has info: ${_info[to]}");
    AssignedVariablesNodeInfo? info = _info.remove(from);
    assert(
        info != null,
        'No information for $from (${from.hashCode}) in '
        '{${_info.keys.map((k) => '$k (${k.hashCode})').join(',')}}');

    _info[to] = info!;
  }

  /// This method may be called at any time between a call to [deferNode] and
  /// the call to [finish], to store assigned variable info for the node.
  void storeInfo(Node node, AssignedVariablesNodeInfo info) {
    assert(!_isFinished);
    // Caller should not try to store the same piece of info more than once.
    assert(_deferredInfos.remove(info));
    _info[node] = info;
  }

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('AssignedVariables(');
    _printOn(sb);
    sb.write(')');
    return sb.toString();
  }

  /// This method should be called during pre-traversal, to mark a write to a
  /// variable.
  void write(Variable variable) {
    assert(!_isFinished);
    int variableKey = promotionKeyStore.keyForVariable(variable);
    _stack.last.written.add(variableKey);
    anywhere.written.add(variableKey);
  }

  void _printOn(StringBuffer sb) {
    sb.write('_info=$_info,');
    sb.write('_stack=$_stack,');
    sb.write('_anywhere=$anywhere');
  }
}

/// Extension of [AssignedVariables] intended for use in tests.  This class
/// exposes the results of the analysis so that they can be tested directly.
/// Not intended to be used by clients of flow analysis.
class AssignedVariablesForTesting<Node extends Object, Variable extends Object>
    extends AssignedVariables<Node, Variable> {
  Set<int> get capturedAnywhere => anywhere.captured;

  Set<int> get declaredAtTopLevel => _stack.first.declared;

  Set<int> get readAnywhere => anywhere.read;

  Set<int> get readCapturedAnywhere => anywhere.readCaptured;

  Set<int> get writtenAnywhere => anywhere.written;

  Set<int> capturedInNode(Node node) => getInfoForNode(node).captured;

  Set<int> declaredInNode(Node node) => getInfoForNode(node).declared;

  bool isTracked(Node node) => _info.containsKey(node);

  int keyForVariable(Variable variable) =>
      promotionKeyStore.keyForVariable(variable);

  Set<int> readCapturedInNode(Node node) => getInfoForNode(node).readCaptured;

  Set<int> readInNode(Node node) => getInfoForNode(node).read;

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('AssignedVariablesForTesting(');
    _printOn(sb);
    sb.write(')');
    return sb.toString();
  }

  Variable variableForKey(int key) => promotionKeyStore.variableForKey(key)!;

  Set<int> writtenInNode(Node node) => getInfoForNode(node).written;
}

/// Information tracked by [AssignedVariables] for a single node.
class AssignedVariablesNodeInfo {
  /// The set of local variables that are potentially read in the node.
  final Set<int> read = {};

  /// The set of local variables that are potentially written in the node.
  final Set<int> written = {};

  /// The set of local variables for which a potential read is captured by a
  /// local function or closure inside the node.
  final Set<int> readCaptured = {};

  /// The set of local variables for which a potential write is captured by a
  /// local function or closure inside the node.
  final Set<int> captured = {};

  /// The set of local variables that are declared in the node.
  final Set<int> declared = {};

  @override
  String toString() =>
      'AssignedVariablesNodeInfo(written=$written, captured=$captured, '
      'declared=$declared)';
}
