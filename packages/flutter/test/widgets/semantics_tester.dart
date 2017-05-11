// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';

export 'package:flutter/rendering.dart' show SemanticsData;

/// Test semantics data that is compared against real semantics tree.
///
/// Useful with [hasSemantics] and [SemanticsTester] to test the contents of the
/// semantics tree.
class TestSemantics {
  /// Creates an object witht some test semantics data.
  ///
  /// If [rect] argument is null, the [rect] field with ve initialized with
  /// `new Rect.fromLTRB(0.0, 0.0, 800.0, 600.0)`, which is the default size of
  /// the screen during unit testing.
  TestSemantics({
    this.id,
    this.flags: 0,
    this.actions: 0,
    this.label: '',
    Rect rect,
    this.transform,
    this.children: const <TestSemantics>[],
  }) : rect = rect ?? new Rect.fromLTRB(0.0, 0.0, 800.0, 600.0);

  /// The unique identifier for this node.
  ///
  /// The root node has an id of zero. Other nodes are given a unique id when
  /// they are created.
  final int id;

  /// A bit field of [SemanticsFlags] that apply to this node.
  final int flags;

  /// A bit field of [SemanticsActions] that apply to this node.
  final int actions;

  /// A textual description of this node.
  final String label;

  /// The bounding box for this node in its coordinate system.
  ///
  /// Defaults to filling the screen.
  final Rect rect;

  /// The transform from this node's coordinate system to its parent's coordinate system.
  ///
  /// By default, the transform is null, which represents the identity
  /// transformation (i.e., that this node has the same coorinate system as its
  /// parent).
  final Matrix4 transform;

  /// The children of this node.
  final List<TestSemantics> children;

  SemanticsData _getSemanticsData() {
    return new SemanticsData(
      flags: flags,
      actions: actions,
      label: label,
      rect: rect,
      transform: transform,
    );
  }

  bool _matches(SemanticsNode node, Map<dynamic, dynamic> matchState) {
    if (node == null || id != node.id
        || _getSemanticsData() != node.getSemanticsData()
        || children.length != (node.mergeAllDescendantsIntoThisNode ? 0 : node.childrenCount)) {
      matchState[TestSemantics] = this;
      matchState[SemanticsNode] = node;
      return false;
    }
    if (children.isEmpty)
      return true;
    bool result = true;
    final Iterator<TestSemantics> it = children.iterator;
    node.visitChildren((SemanticsNode node) {
      it.moveNext();
      if (!it.current._matches(node, matchState)) {
        result = false;
        return false;
      }
      return true;
    });
    return result;
  }
}

/// Ensures that the given widget tester has a semantics tree to test.
///
/// Useful with [hasSemantics] to test the contents of the semantics tree.
class SemanticsTester {
  /// Creates a semantics tester for the given widget tester.
  ///
  /// You should call [dispose] at the end of a test that creates a semantics
  /// tester.
  SemanticsTester(this.tester) {
    _semanticsHandle = tester.binding.pipelineOwner.ensureSemantics();
  }

  /// The widget tester that this object is testing the semantics of.
  final WidgetTester tester;
  SemanticsHandle _semanticsHandle;

  /// Release resources held by this semantics tester.
  ///
  /// Call this function at the end of any test that uses a semantics tester.
  @mustCallSuper
  void dispose() {
    _semanticsHandle.dispose();
    _semanticsHandle = null;
  }

  @override
  String toString() => 'SemanticsTester';
}

class _HasSemantics extends Matcher {
  const _HasSemantics(this._semantics);

  final TestSemantics _semantics;

  @override
  bool matches(covariant SemanticsTester item, Map<dynamic, dynamic> matchState) {
    return _semantics._matches(item.tester.binding.pipelineOwner.semanticsOwner.rootSemanticsNode, matchState);
  }

  @override
  Description describe(Description description) {
    return description.add('semantics node id ${_semantics.id}');
  }

  @override
  Description describeMismatch(dynamic item, Description mismatchDescription, Map<dynamic, dynamic> matchState, bool verbose) {
    final TestSemantics testNode = matchState[TestSemantics];
    final SemanticsNode node = matchState[SemanticsNode];
    if (node == null)
      return mismatchDescription.add('could not find node with id ${testNode.id}');
    if (testNode.id != node.id)
      return mismatchDescription.add('expected node id ${testNode.id} but found id ${node.id}');
    final SemanticsData data = node.getSemanticsData();
    if (testNode.flags != data.flags)
      return mismatchDescription.add('expected node id ${testNode.id} to have flags ${testNode.flags} but found flags ${data.flags}');
    if (testNode.actions != data.actions)
      return mismatchDescription.add('expected node id ${testNode.id} to have actions ${testNode.actions} but found actions ${data.actions}');
    if (testNode.label != data.label)
      return mismatchDescription.add('expected node id ${testNode.id} to have label "${testNode.label}" but found label "${data.label}"');
    if (testNode.rect != data.rect)
      return mismatchDescription.add('expected node id ${testNode.id} to have rect ${testNode.rect} but found rect ${data.rect}');
    if (testNode.transform != data.transform)
      return mismatchDescription.add('expected node id ${testNode.id} to have transform ${testNode.transform} but found transform ${data.transform}');
    final int childrenCount = node.mergeAllDescendantsIntoThisNode ? 0 : node.childrenCount;
    if (testNode.children.length != childrenCount)
      return mismatchDescription.add('expected node id ${testNode.id} to have ${testNode.children.length} but found $childrenCount children');
    return mismatchDescription;
  }
}

/// Asserts that a [SemanticsTester] has a semantics tree that exactly matches the given semantics.
Matcher hasSemantics(TestSemantics semantics) => new _HasSemantics(semantics);
