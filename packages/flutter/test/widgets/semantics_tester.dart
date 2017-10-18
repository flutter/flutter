// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';

export 'package:flutter/rendering.dart' show SemanticsData;

const String _matcherHelp = 'Try dumping the semantics with debugDumpSemanticsTree(DebugSemanticsDumpOrder.inverseHitTest) from the package:flutter/rendering.dart library to see what the semantics tree looks like.';

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
    this.id,
    this.flags: 0,
    this.actions: 0,
    this.label: '',
    this.textDirection,
    this.rect,
    this.transform,
    this.children: const <TestSemantics>[],
    Iterable<SemanticsTag> tags,
  }) : assert(flags != null),
       assert(label != null),
       assert(children != null),
       tags = tags?.toSet() ?? new Set<SemanticsTag>();

  /// Creates an object with some test semantics data, with the [id] and [rect]
  /// set to the appropriate values for the root node.
  TestSemantics.root({
    this.flags: 0,
    this.actions: 0,
    this.label: '',
    this.textDirection,
    this.transform,
    this.children: const <TestSemantics>[],
    Iterable<SemanticsTag> tags,
  }) : id = 0,
       assert(flags != null),
       assert(label != null),
       rect = TestSemantics.rootRect,
       assert(children != null),
       tags = tags?.toSet() ?? new Set<SemanticsTag>();

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
    this.id,
    this.flags: 0,
    this.actions: 0,
    this.label: '',
    this.textDirection,
    this.rect,
    Matrix4 transform,
    this.children: const <TestSemantics>[],
    Iterable<SemanticsTag> tags,
  }) : assert(flags != null),
       assert(label != null),
       transform = _applyRootChildScale(transform),
       assert(children != null),
       tags = tags?.toSet() ?? new Set<SemanticsTag>();

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

  /// The reading direction of the [label].
  ///
  /// Even if this is not set, the [hasSemantics] matcher will verify that if a
  /// label is present on the [SemanticsNode], a [SemanticsNode.textDirection]
  /// is also set.
  final TextDirection textDirection;

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

  /// The tags of this node.
  final Set<SemanticsTag> tags;

  bool _matches(SemanticsNode node, Map<dynamic, dynamic> matchState, { bool ignoreRect: false, bool ignoreTransform: false, bool ignoreId: false }) {
    final SemanticsData nodeData = node.getSemanticsData();

    bool fail(String message) {
      matchState[TestSemantics] = '$message\n$_matcherHelp';
      return false;
    }

    if (node == null)
      return fail('could not find node with id $id.');
    if (!ignoreId && id != node.id)
      return fail('expected node id $id but found id ${node.id}.');
    if (flags != nodeData.flags)
      return fail('expected node id $id to have flags $flags but found flags ${nodeData.flags}.');
    if (actions != nodeData.actions)
      return fail('expected node id $id to have actions $actions but found actions ${nodeData.actions}.');
    if (label != nodeData.label)
      return fail('expected node id $id to have label "$label" but found label "${nodeData.label}".');
    if (textDirection != null && textDirection != nodeData.textDirection)
      return fail('expected node id $id to have textDirection "$textDirection" but found "${nodeData.textDirection}".');
    if (nodeData.label != '' && nodeData.textDirection == null)
      return fail('expected node id $id, which has a label, to have a textDirection, but it did not.');
    if (!ignoreRect && rect != nodeData.rect)
      return fail('expected node id $id to have rect $rect but found rect ${nodeData.rect}.');
    if (!ignoreTransform && transform != nodeData.transform)
      return fail('expected node id $id to have transform $transform but found transform:\n${nodeData.transform}.');
    final int childrenCount = node.mergeAllDescendantsIntoThisNode ? 0 : node.childrenCount;
    if (children.length != childrenCount)
      return fail('expected node id $id to have ${children.length} child${ children.length == 1 ? "" : "ren" } but found $childrenCount.');

    if (children.isEmpty)
      return true;
    bool result = true;
    final Iterator<TestSemantics> it = children.iterator;
    node.visitChildren((SemanticsNode node) {
      it.moveNext();
      if (!it.current._matches(node, matchState, ignoreRect: ignoreRect, ignoreTransform: ignoreTransform, ignoreId: ignoreId)) {
        result = false;
        return false;
      }
      return true;
    });
    return result;
  }

  @override
  String toString() {
    return 'node $id, flags=$flags, actions=$actions, label="$label", textDirection=$textDirection, rect=$rect, transform=$transform, ${children.length} child${ children.length == 1 ? "" : "ren" }';
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
  String toString() => 'SemanticsTester for ${tester.binding.pipelineOwner.semanticsOwner.rootSemanticsNode}';
}

class _HasSemantics extends Matcher {
  const _HasSemantics(this._semantics, { this.ignoreRect: false, this.ignoreTransform: false, this.ignoreId: false }) : assert(_semantics != null), assert(ignoreRect != null), assert(ignoreId != null), assert(ignoreTransform != null);

  final TestSemantics _semantics;
  final bool ignoreRect;
  final bool ignoreTransform;
  final bool ignoreId;

  @override
  bool matches(covariant SemanticsTester item, Map<dynamic, dynamic> matchState) {
    return _semantics._matches(item.tester.binding.pipelineOwner.semanticsOwner.rootSemanticsNode, matchState, ignoreTransform: ignoreTransform, ignoreRect: ignoreRect, ignoreId: ignoreId);
  }

  @override
  Description describe(Description description) {
    return description.add('semantics node matching: $_semantics');
  }

  @override
  Description describeMismatch(dynamic item, Description mismatchDescription, Map<dynamic, dynamic> matchState, bool verbose) {
    return mismatchDescription.add(matchState[TestSemantics]);
  }
}

/// Asserts that a [SemanticsTester] has a semantics tree that exactly matches the given semantics.
Matcher hasSemantics(TestSemantics semantics, {
  bool ignoreRect: false,
  bool ignoreTransform: false,
  bool ignoreId: false,
}) => new _HasSemantics(semantics, ignoreRect: ignoreRect, ignoreTransform: ignoreTransform, ignoreId: ignoreId);

class _IncludesNodeWith extends Matcher {
  const _IncludesNodeWith({
    this.label,
    this.textDirection,
    this.actions,
}) : assert(label != null || actions != null);

  final String label;
  final TextDirection textDirection;
  final List<SemanticsAction> actions;

  @override
  bool matches(covariant SemanticsTester item, Map<dynamic, dynamic> matchState) {
    bool result = false;
    SemanticsNodeVisitor visitor;
    visitor = (SemanticsNode node) {
      if (checkNode(node)) {
        result = true;
      } else {
        node.visitChildren(visitor);
      }
      return !result;
    };
    final SemanticsNode root = item.tester.binding.pipelineOwner.semanticsOwner.rootSemanticsNode;
    visitor(root);
    return result;
  }

  bool checkNode(SemanticsNode node) {
    if (label != null && node.label != label)
      return false;
    if (textDirection != null && node.textDirection != textDirection)
      return false;
    if (actions != null) {
      final int expectedActions = actions.fold(0, (int value, SemanticsAction action) => value | action.index);
      final int actualActions = node.getSemanticsData().actions;
      if (expectedActions != actualActions)
        return false;
    }
    return true;
  }

  @override
  Description describe(Description description) {
    return description.add('includes node with $_configAsString');
  }

  @override
  Description describeMismatch(dynamic item, Description mismatchDescription, Map<dynamic, dynamic> matchState, bool verbose) {
    return mismatchDescription.add('could not find node with $_configAsString.\n$_matcherHelp');
  }

  String get _configAsString {
    String string = '';
    if (label != null) {
      string += 'label "$label"';
      if (textDirection != null)
        string += ' (${describeEnum(textDirection)})';
      if (actions != null)
        string += ' and ';
    } else if (textDirection != null) {
      string += 'direction ${describeEnum(textDirection)}';
      if (actions != null)
        string += ' and ';
    }
    if (actions != null) {
      string += 'actions "${actions.join(', ')}"';
    }
    return string;
  }
}

/// Asserts that a node in the semantics tree of [SemanticsTester] has `label`,
/// `textDirection`, and `actions`.
///
/// If null is provided for an argument, it will match against any value.
Matcher includesNodeWith({ String label, TextDirection textDirection, List<SemanticsAction> actions }) {
  return new _IncludesNodeWith(
    label: label,
    textDirection: textDirection,
    actions: actions,
  );
}
