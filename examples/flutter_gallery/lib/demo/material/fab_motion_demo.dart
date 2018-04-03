// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

const String _explanatoryText =
  "When the Scaffold's floating action button location changes, "
  'the floating action button animates to its new position';

class FabMotionDemo extends StatefulWidget {
  static const String routeName = '/material/fab-motion';

  @override
  _FabMotionDemoState createState() {
    return new _FabMotionDemoState();
  }
}

class _FabMotionDemoState extends State<FabMotionDemo> {
  static const List<FloatingActionButtonLocation> _floatingActionButtonLocations = const <FloatingActionButtonLocation>[
    FloatingActionButtonLocation.endFloat,
    FloatingActionButtonLocation.centerFloat,
    FloatingActionButtonLocation.startTop,
  ];

  bool _showFab = true;
  FloatingActionButtonLocation _floatingActionButtonLocation = FloatingActionButtonLocation.endFloat;

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
    return new Scaffold(
      appBar: new AppBar(
        title: const Text('FAB Location'),
        // Add 48dp of space onto the bottom of the appbar.
        // This gives space for the top-start location to attach to without
        // blocking the 'back' button.
        bottom: const PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: const SizedBox(),
        ),
      ),
      floatingActionButtonLocation: _floatingActionButtonLocation,
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
  }

  void _moveFab() {
    setState(() {
      _floatingActionButtonLocation = _floatingActionButtonLocations[(_floatingActionButtonLocations.indexOf(_floatingActionButtonLocation) + 1) % _floatingActionButtonLocations.length];
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
