// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

const String _explanatoryText =
  "When the Scaffold's floating action button positioner changes,"
  'the floating action button animates to its new position';

class FabMotionDemo extends StatefulWidget {
  static String routeName = '/material/fab-motion';

  @override
  State<StatefulWidget> createState() {
    return new _FabMotionDemoState();
  }
}


class _FabMotionDemoState extends State<FabMotionDemo> {
  static const List<FabPositioner> _fabValues = const <FabPositioner>[FabPositioner.endFloat, FabPositioner.centerFloat];

  FabPositioner _fabPositioner = FabPositioner.endFloat;
  bool _slideFab = false;

  void _toggleSlideFab(bool newSlideFabValue) {
    setState(() {
      _slideFab = newSlideFabValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget scaffold = new Scaffold(
      appBar: new AppBar(title: new Text('FAB Positioner')),
      fabPositioner: _fabPositioner,
      floatingActionButton: new Builder(builder: (BuildContext context) {
        // We use a widget builder here so that this inner context can find the Scaffold.
        // This makes it possible to show the snackbar.
        return new FloatingActionButton(
          onPressed: () => _showSnackbar(context),
          child: new Icon(Icons.add_circle_outline), 
        );
      }),
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
                const Text('Slide the FAB'),
                const SizedBox(width: 8.0, height: 24.0),
                new Switch(value: _slideFab, onChanged: _toggleSlideFab),
              ],
            ),
          ],
        ),
      ),
    );
    if (_slideFab) {
      return new _SlidingFabMotionAnimator(child: scaffold);
    }
    return scaffold;
  }

  void _moveFab() {
    setState(() {
      _fabPositioner = _fabValues[(_fabValues.indexOf(_fabPositioner) + 1) % _fabValues.length];
    });
  }

  void _showSnackbar(BuildContext context) {
    Scaffold.of(context).showSnackBar(new SnackBar(content: const Text(_explanatoryText)));
  }
}

class _SlidingFabMotionAnimator extends FabMotionAnimator {
  const _SlidingFabMotionAnimator({Key key, Widget child}): super(key: key, child: child);

  @override
  Animation<Offset> getOffsetAnimation({Offset begin, Offset end, Animation<double> parent}) {
    return new Tween<Offset>(begin: begin, end: end).chain(new CurveTween(curve: Curves.bounceIn)).animate(parent);
  }

  @override
  Animation<double> getRotationAnimation({Animation<double> parent}) {
    return new Tween<double>(begin: 0.0, end: 0.0).animate(parent);
  }

  @override
  Animation<double> getScaleAnimation({Animation<double> parent}) {
    return new Tween<double>(begin: 1.0, end: 1.0).animate(parent);
  }
}
