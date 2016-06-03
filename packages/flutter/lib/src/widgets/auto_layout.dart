// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';

import 'framework.dart';

export 'package:flutter/rendering.dart' show
    AutoLayoutRect,
    AutoLayoutDelegate;

/// A widget that uses the cassowary constraint solver to automatically size and position children.
class AutoLayout extends MultiChildRenderObjectWidget {
  /// Creates a widget that uses the cassowary constraint solver to automatically size and position children.
  AutoLayout({
    Key key,
    this.delegate,
    List<Widget> children: const <Widget>[]
  }) : super(key: key, children: children);

  /// The delegate that generates constraints for the layout.
  ///
  /// If the delgate is null, the layout is unconstrained.
  final AutoLayoutDelegate delegate;

  @override
  RenderAutoLayout createRenderObject(BuildContext context) => new RenderAutoLayout(delegate: delegate);

  @override
  void updateRenderObject(BuildContext context, RenderAutoLayout renderObject) {
    renderObject.delegate = delegate;
  }
}

/// A widget that provides constraints for a child of an [AutoLayout] widget.
///
/// An [AutoLayoutChild] widget must be a descendant of an [AutoLayout], and
/// the path from the [AutoLayoutChild] widget to its enclosing [AutoLayout]
/// must contain only [StatelessWidget]s or [StatefulWidget]s (not other kinds
/// of widgets, like [RenderObjectWidget]s).
class AutoLayoutChild extends ParentDataWidget<AutoLayout> {
  /// Creates a widget that provides constraints for a child of an [AutoLayout] widget.
  ///
  /// The object identity of the [rect] argument must be unique among children
  /// of a given [AutoLayout] widget.
  AutoLayoutChild({
    AutoLayoutRect rect,
    @required Widget child
  }) : rect = rect,
       super(key: rect != null ? new ObjectKey(rect) : null, child: child);

  /// The constraints to use for this child.
  ///
  /// The object identity of the [rect] object must be unique among children of
  /// a given [AutoLayout] widget.
  ///
  /// If null, the child's size and position are unconstrained.
  final AutoLayoutRect rect;

  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is AutoLayoutParentData);
    final AutoLayoutParentData parentData = renderObject.parentData;
    // AutoLayoutParentData filters out redundant writes and marks needs layout
    // as appropriate.
    parentData.rect = rect;
  }
}
