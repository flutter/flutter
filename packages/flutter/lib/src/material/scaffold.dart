// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'constants.dart';
import 'material.dart';
import 'tool_bar.dart';

const double _kFloatingActionButtonMargin = 16.0; // TODO(hmuller): should be device dependent

const int _kBodyIndex = 0;
const int _kToolBarIndex = 1;
const int _kBottomSheetIndex = 2;
const int _kSnackBarIndex = 3;
const int _kFloatingActionButtonIndex = 4;

class _ScaffoldLayout extends MultiChildLayoutDelegate {
  void performLayout(Size size, BoxConstraints constraints, int childCount) {
    assert(childCount == 5);

    // This part of the layout has the same effect as putting the toolbar and
    // body in a column and making the body flexible. What's different is that
    // in this case the toolbar appears -after- the body in the stacking order,
    // so the toolbar's shadow is drawn on top of the body.

    final BoxConstraints toolBarConstraints = constraints.loosen().tightenWidth(size.width);
    final Size toolBarSize = layoutChild(_kToolBarIndex, toolBarConstraints);
    final double bodyHeight = size.height - toolBarSize.height;
    final BoxConstraints bodyConstraints = toolBarConstraints.tightenHeight(bodyHeight);
    layoutChild(_kBodyIndex, bodyConstraints);
    positionChild(_kToolBarIndex, Point.origin);
    positionChild(_kBodyIndex, new Point(0.0, toolBarSize.height));

    // The BottomSheet and the SnackBar are anchored to the bottom of the parent,
    // they're as wide as the parent and are given their intrinsic height.
    // If all three elements are present then either the center of the FAB straddles
    // the top edge of the BottomSheet or the bottom of the FAB is
    // _kFloatingActionButtonMargin above the SnackBar, whichever puts the FAB
    // the farthest above the bottom of the parent. If only the FAB is has a
    // non-zero height then it's inset from the parent's right and bottom edges
    // by _kFloatingActionButtonMargin.

    final BoxConstraints fullWidthConstraints = constraints.loosen().tightenWidth(size.width);
    final Size bottomSheetSize = layoutChild(_kBottomSheetIndex, fullWidthConstraints);
    final Size snackBarSize = layoutChild(_kSnackBarIndex, fullWidthConstraints);
    final Size fabSize = layoutChild(_kFloatingActionButtonIndex, constraints.loosen());
    positionChild(_kBottomSheetIndex, new Point(0.0, size.height - bottomSheetSize.height));
    positionChild(_kSnackBarIndex, new Point(0.0, size.height - snackBarSize.height));

    final double fabX = size.width - fabSize.width - _kFloatingActionButtonMargin;
    double fabY = size.height - fabSize.height - _kFloatingActionButtonMargin;
    if (snackBarSize.height > 0.0)
      fabY = math.min(fabY, size.height - snackBarSize.height - fabSize.height - _kFloatingActionButtonMargin);
    if (bottomSheetSize.height > 0.0)
      fabY = math.min(fabY, size.height - bottomSheetSize.height - fabSize.height / 2.0);
    positionChild(_kFloatingActionButtonIndex, new Point(fabX, fabY));
  }
}

final _ScaffoldLayout _scaffoldLayout = new _ScaffoldLayout();

class Scaffold extends StatelessComponent {
  Scaffold({
    Key key,
    this.body,
    this.toolBar,
    this.snackBar,
    this.floatingActionButton,
    this.bottomSheet
  }) : super(key: key);

  final Widget body;
  final ToolBar toolBar;
  final Widget snackBar;
  final Widget floatingActionButton;
  final Widget bottomSheet;

  Widget build(BuildContext context) {
    final Widget paddedToolBar = toolBar?.withPadding(new EdgeDims.only(top: ui.window.padding.top));
    final Widget materialBody = body != null ? new Material(child: body) : null;
    Widget constrainedSnackBar;
    if (snackBar != null) {
      // TODO(jackson): On tablet/desktop, minWidth = 288, maxWidth = 568
      constrainedSnackBar = new ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: kSnackBarHeight),
        child: snackBar
      );
    }
    return new CustomMultiChildLayout(<Widget>[
      materialBody ?? new Container(height: 0.0),
      paddedToolBar ?? new Container(height: 0.0),
      bottomSheet ?? new Container(height: 0.0),
      constrainedSnackBar ?? new Container(height: 0.0),
      floatingActionButton ?? new Container(height: 0.0)
    ],
      delegate: _scaffoldLayout
    );
  }
}
