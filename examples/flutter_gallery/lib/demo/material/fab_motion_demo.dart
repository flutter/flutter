// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

const String _explanatoryText =
  "When the Scaffold's floating action button positioner changes, "
  'the floating action button animates to its new position';

class FabMotionDemo extends StatefulWidget {
  static const String routeName = '/material/fab-motion';

  @override
  _FabMotionDemoState createState() {
    return new _FabMotionDemoState();
  }
}


class _FabMotionDemoState extends State<FabMotionDemo> {
  static const List<FloatingActionButtonPositioner> _floatingActionButtonPositioners = const <FloatingActionButtonPositioner>[
    FloatingActionButtonPositioner.endFloat, 
    FloatingActionButtonPositioner.centerFloat,
    const _TopStartFloatingActionButtonPositioner(),
  ];

  bool _showFab = true;
  FloatingActionButtonPositioner _floatingActionButtonPositioner = FloatingActionButtonPositioner.endFloat;

  @override
  Widget build(BuildContext context) {
    final Widget floatingActionButton = _showFab 
      ? new Builder(builder: (BuildContext context) {
        // We use a widget builder here so that this inner context can find the Scaffold.
        // This makes it possible to show the snackbar.
        return new FloatingActionButton(
          backgroundColor: Colors.yellow.shade900,
          onPressed: () => _showSnackbar(context),
          child: const Icon(Icons.add), 
        );
      }) 
      : null;
    final Widget scaffold = new Scaffold(
      appBar: new AppBar(
        title: const Text('FAB Positioner'), 
        // Add 48dp of space onto the bottom of the appbar.
        // This gives space for the top-start positioner to attach to without
        // blocking the 'back' button.
        bottom: const PreferredSize(
          preferredSize: const Size.fromHeight(48.0), 
          child: const SizedBox(),
        ),
      ),
      floatingActionButtonPositioner: _floatingActionButtonPositioner,
      floatingActionButton: floatingActionButton,
      body: new Center(
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            new RaisedButton(
              onPressed: _moveFab,
              child: const Text('MOVE FAB'),
            ),
            new Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text('Toggle FAB'),
                new Switch(value: _showFab, onChanged: _toggleFab),
              ],
            ),
          ],
        ),
      ),
    );
    return scaffold;
  }

  void _moveFab() {
    setState(() {
      _floatingActionButtonPositioner = _floatingActionButtonPositioners[(_floatingActionButtonPositioners.indexOf(_floatingActionButtonPositioner) + 1) % _floatingActionButtonPositioners.length];
    });
  }

  void _toggleFab(bool showFab) {
    setState(() {
      _showFab = showFab;
    });
  }

  void _showSnackbar(BuildContext context) {
    Scaffold.of(context).showSnackBar(const SnackBar(content: const Text(_explanatoryText)));
  }
}

// Places the Floating Action Button at the top of the content area of the
// app, on the border between the body and the app bar.
class _TopStartFloatingActionButtonPositioner extends FloatingActionButtonPositioner {
  const _TopStartFloatingActionButtonPositioner();

  // An additional inset we apply to the side of the Floating Action Button.
  static const double _horizontalInset = 16.0;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // First, we'll place the X coordinate for the Floating Action Button
    // at the start of the screen, based on the text direction.
    double fabX;
    assert(scaffoldGeometry.textDirection != null);
    final double padding = _horizontalInset + scaffoldGeometry.horizontalFloatingActionButtonPadding;
    switch (scaffoldGeometry.textDirection) {
      case TextDirection.rtl:
        // In RTL layouts, the start of the screen is on the right side,
        // and the end of the screen is on the left.
        //
        // We need to align the right edge of the floating action button with
        // the right edge of the screen, then move it inwards by the designated padding.
        //
        // The Scaffold's origin is at its top-left, so we need to offset fabX
        // by the Scaffold's width to get the right edge of the screen.
        //
        // The Floating Action Button's origin is at its top-left, so need
        // to subtract the Floating Action Button's width
        // to align the right edge of the Floating Action Button instead of the left edge.
        fabX = scaffoldGeometry.scaffoldSize.width - scaffoldGeometry.floatingActionButtonSize.width - padding;
        break;
      case TextDirection.ltr:
        // In LTR layouts, the start of the screen is on the left side,
        // and the end of the screen is on the right.
        //
        // Placing the fabX at 0.0 will align the left edge of the
        // Floating Action Button with the left edge of the screen, so all
        // we need to do is offset fabX by the designated padding.
        fabX = padding;
        break;
    }
    // Finally, we'll place the Y coordinate for the Floating Action Button 
    // at the top of the content body.
    //
    // We want to place the middle of the Floating Action Button on the
    // border between the Scaffold's app bar and its body. To do this,
    // we place fabY at the scaffold geometry's contentTop, then subtract
    // half of the Floating Action Button's height to place the center
    // over the contentTop.
    //
    // We don't have to worry about which way is the top like we did
    // for left and right, so we place fabY in this one-liner.
    final double fabY = scaffoldGeometry.contentTop - (scaffoldGeometry.floatingActionButtonSize.height / 2.0);
    return new Offset(fabX, fabY);
  }
}
