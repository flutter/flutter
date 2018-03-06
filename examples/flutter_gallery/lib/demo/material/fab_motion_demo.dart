// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

const String _explanatoryText =
  "When the Scaffold's floating action button positioner changes, "
  'the floating action button animates to its new position';

class FabMotionDemo extends StatefulWidget {
  static String routeName = '/material/fab-motion';

  @override
  State<StatefulWidget> createState() {
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

class _TopStartFloatingActionButtonPositioner extends FloatingActionButtonPositioner {
  const _TopStartFloatingActionButtonPositioner();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    double fabX;
    assert(scaffoldGeometry.textDirection != null);
    switch (scaffoldGeometry.textDirection) {
      case TextDirection.rtl:
        fabX = scaffoldGeometry.scaffoldSize.width - scaffoldGeometry.floatingActionButtonSize.width - 16.0 - scaffoldGeometry.horizontalFloatingActionButtonPadding;
        break;
      case TextDirection.ltr:
        fabX = 16.0 + scaffoldGeometry.horizontalFloatingActionButtonPadding;
        break;
    }
    final double fabY = scaffoldGeometry.contentTop - (scaffoldGeometry.floatingActionButtonSize.height / 2.0);
    return new Offset(fabX, fabY);
  }
}
