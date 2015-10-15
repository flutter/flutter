// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'constants.dart';

class Scaffold extends StatelessComponent {
  Scaffold({
    Key key,
    this.body,
    this.statusBar,
    this.toolBar,
    this.snackBar,
    this.floatingActionButton
  }) : super(key: key);

  final Widget body;
  final Widget statusBar;
  final Widget toolBar;
  final Widget snackBar;
  final Widget floatingActionButton;

  Widget build(BuildContext context) {
    double toolBarHeight = 0.0;
    if (toolBar != null)
      toolBarHeight = kToolBarHeight + ui.view.paddingTop;

    double statusBarHeight = 0.0;
    if (statusBar != null)
      statusBarHeight = kStatusBarHeight;

    List<Widget> children = <Widget>[];

    if (body != null) {
      children.add(new Positioned(
        top: toolBarHeight, right: 0.0, bottom: statusBarHeight, left: 0.0,
        child: body
      ));
    }

    if (statusBar != null) {
      children.add(new Positioned(
        right: 0.0, bottom: 0.0, left: 0.0,
        child: new SizedBox(
          height: statusBarHeight,
          child: statusBar
        )
      ));
    }

    if (toolBar != null) {
      children.add(new Positioned(
        top: 0.0, right: 0.0, left: 0.0,
        child: new SizedBox(
          height: toolBarHeight,
          child: toolBar
        )
      ));
    }

    if (snackBar != null || floatingActionButton != null) {
      List<Widget> floatingChildren = <Widget>[];

      if (floatingActionButton != null) {
        floatingChildren.add(new Padding(
          // TODO(eseidel): These change based on device size!
          padding: const EdgeDims.only(right: 16.0, bottom: 16.0),
          child: floatingActionButton
        ));
      }

      // TODO(jackson): On tablet/desktop, minWidth = 288, maxWidth = 568
      if (snackBar != null) {
        floatingChildren.add(new ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: kSnackBarHeight),
          child: snackBar
        ));
      }

      children.add(new Positioned(
        right: 0.0, bottom: statusBarHeight, left: 0.0,
        child: new Column(floatingChildren, alignItems: FlexAlignItems.end)
      ));
    }

    return new Stack(children);
  }
}
