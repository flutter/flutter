// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'constants.dart';
import 'material.dart';

const int _kToolBarIndex = 1;
const int _kBodyIndex = 0;

// This layout has the same effect as putting the toolbar and body in a column
// and making the body flexible. What's different is that in this case the
// toolbar appears -after- the body in the stacking order, so the toolbar's
// shadow is drawn on top of the body.
class _ToolBarAndBodyLayout extends MultiChildLayoutDelegate {
  void performLayout(Size size, BoxConstraints constraints, int childCount) {
    assert(childCount == 2);
    final BoxConstraints toolBarConstraints = constraints.loosen().tightenWidth(size.width);
    final Size toolBarSize = layoutChild(_kToolBarIndex, toolBarConstraints);
    final double topPadding = ui.window.padding.top;
    final double bodyHeight = size.height - toolBarSize.height - topPadding;
    final BoxConstraints bodyConstraints = toolBarConstraints.tightenHeight(bodyHeight);
    layoutChild(_kBodyIndex, bodyConstraints);
    positionChild(_kToolBarIndex, new Point(0.0, topPadding));
    positionChild(_kBodyIndex, new Point(0.0, topPadding + toolBarSize.height));
  }
}

class Scaffold extends StatelessComponent {
  final _ToolBarAndBodyLayout _toolBarAndBodyLayout = new _ToolBarAndBodyLayout();

  Scaffold({
    Key key,
    this.body,
    this.toolBar,
    this.snackBar,
    this.floatingActionButton
  }) : super(key: key);

  final Widget body;
  final Widget toolBar;
  final Widget snackBar;
  final Widget floatingActionButton;

  Widget build(BuildContext context) {
    final Widget materialBody = body != null ? new Material(child: body) : null;
    Widget toolBarAndBody;
    if (toolBar != null && materialBody != null)
      toolBarAndBody = new CustomMultiChildLayout(<Widget>[materialBody, toolBar],
        delegate: _toolBarAndBodyLayout
      );
    else
      toolBarAndBody = toolBar ?? materialBody;

    final List<Widget> bottomColumnChildren = <Widget>[];

    if (floatingActionButton != null)
      bottomColumnChildren.add(new Padding(
        // TODO(eseidel): These change based on device size!
        padding: const EdgeDims.only(right: 16.0, bottom: 16.0),
        child: floatingActionButton
      ));

    // TODO(jackson): On tablet/desktop, minWidth = 288, maxWidth = 568
    if (snackBar != null) {
      bottomColumnChildren.add(new ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: kSnackBarHeight),
        child: snackBar
      ));
    }

    final List<Widget> stackChildren = <Widget>[toolBarAndBody];

    if (bottomColumnChildren.length > 0) {
      stackChildren.add(new Positioned(
        right: 0.0,
        left: 0.0,
        bottom: 0.0,
        child: new Column(bottomColumnChildren, alignItems: FlexAlignItems.end)
      ));
    }

    return new Stack(stackChildren);
  }
}
