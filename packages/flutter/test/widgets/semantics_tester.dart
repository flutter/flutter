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
  /// Creates an object with some test semantics data.
  ///
  /// The [id] field is required. The root node has an id of zero. Other nodes
  /// are given a unique id when they are created, in a predictable fashion, and
  /// so these values can be hard-coded.
  ///
  /// The [rect] field is required and has no default. Convenient values are
  /// available:
  ///
  ///  * [TestSemantics.rootRect]: 2400x1600, the test screen's size in physical
  ///    pixels, useful for the node with id zero.
  ///
  ///  * [TestSemantics.fullScreen] 800x600, the test screen's size in logical
  ///    pixels, useful for other full-screen widgets.
  TestSemantics({
    @required this.id,
    this.flags: 0,
    this.actions: 0,
    this.label: '',
    @required this.rect,
    this.transform,
    this.children: const <TestSemantics>[],
  }) : assert(id != null),
       assert(flags != null),
       assert(label != null),
       assert(rect != null),
       assert(children != null);

  /// Creates an object with some test semantics data, with the [id] and [rect]
  /// set to the appropriate values for the root node.
  TestSemantics.root({
    this.flags: 0,
    this.actions: 0,
    this.label: '',
    this.transform,
    this.children: const <TestSemantics>[],
  }) : id = 0,
       assert(flags != null),
       assert(label != null),
       rect = TestSemantics.rootRect,
       assert(children != null);

  /// Creates an object with some test semantics data, with the [id] and [rect]
  /// set to the appropriate values for direct children of the root node.
  ///
  /// The [transform] is set to a 3.0 scale (to account for the
  /// [Window.devicePixelRatio] being 3.0 on the test pseudo-device).
  ///
  /// The [rect] field is required and has no default. The
  /// [TestSemantics.fullScreen] property may be useful as a value; it describes
  /// an 800x600 rectangle, which is the test screen's size in logical pixels.
  TestSemantics.rootChild({
    @required this.id,
    this.flags: 0,
    this.actions: 0,
    this.label: '',
    @required this.rect,
    Matrix4 transform,
    this.children: const <TestSemantics>[],
  }) : assert(flags != null),
       assert(label != null),
       transform = _applyRootChildScale(transform),
       assert(children != null);

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
  /// Convenient values are available:
  ///
  ///  * [TestSemantics.rootRect]: 2400x1600, the test screen's size in physical
  ///    pixels, useful for the node with id zero.
  ///
  ///  * [TestSemantics.fullScreen] 800x600, the test screen's size in logical
  ///    pixels, useful for other full-screen widgets.
  final Rect rect;

  /// The test screen's size in physical pixels, typically used as the [rect]
  /// for the node with id zero.
  ///
  /// See also [new TestSemantics.root], which uses this value to describe the
  /// root node.
  static final Rect rootRect = new Rect.fromLTWH(0.0, 0.0, 2400.0, 1800.0);

  /// The test screen's size in logical pixels, useful for the [rect] of
  /// full-screen widgets other than the root node.
  static final Rect fullScreen = new Rect.fromLTWH(0.0, 0.0, 800.0, 600.0);

  /// The transform from this node's coordinate system to its parent's coordinate system.
  ///
  /// By default, the transform is null, which represents the identity
  /// transformation (i.e., that this node has the same coorinate system as its
  /// parent).
  final Matrix4 transform;

  static Matrix4 _applyRootChildScale(Matrix4 transform) {
    final Matrix4 result = new Matrix4.diagonal3Values(3.0, 3.0, 1.0);
    if (transform != null)
      result.multiply(transform);
    return result;
  }

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
  const _HasSemantics(this._semantics) : assert(_semantics != null);

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
    const String help = 'Try dumping the semantics with debugDumpSemanticsTree() from the rendering library to see what the semantics tree looks like.';
    final TestSemantics testNode = matchState[TestSemantics];
    final SemanticsNode node = matchState[SemanticsNode];
    if (node == null)
      return mismatchDescription.add('could not find node with id ${testNode.id}.\n$help');
    if (testNode.id != node.id)
      return mismatchDescription.add('expected node id ${testNode.id} but found id ${node.id}.\n$help');
    final SemanticsData data = node.getSemanticsData();
    if (testNode.flags != data.flags)
      return mismatchDescription.add('expected node id ${testNode.id} to have flags ${testNode.flags} but found flags ${data.flags}.\n$help');
    if (testNode.actions != data.actions)
      return mismatchDescription.add('expected node id ${testNode.id} to have actions ${testNode.actions} but found actions ${data.actions}.\n$help');
    if (testNode.label != data.label)
      return mismatchDescription.add('expected node id ${testNode.id} to have label "${testNode.label}" but found label "${data.label}".\n$help');
    if (testNode.rect != data.rect)
      return mismatchDescription.add('expected node id ${testNode.id} to have rect ${testNode.rect} but found rect ${data.rect}.\n$help');
    if (testNode.transform != data.transform)
      return mismatchDescription.add('expected node id ${testNode.id} to have transform ${testNode.transform} but found transform:.\n${data.transform}.\n$help');
    final int childrenCount = node.mergeAllDescendantsIntoThisNode ? 0 : node.childrenCount;
    if (testNode.children.length != childrenCount)
      return mismatchDescription.add('expected node id ${testNode.id} to have ${testNode.children.length} children but found $childrenCount.\n$help');
    return mismatchDescription;
  }
}

/// Asserts that a [SemanticsTester] has a semantics tree that exactly matches the given semantics.
Matcher hasSemantics(TestSemantics semantics) => new _HasSemantics(semantics);
