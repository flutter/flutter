// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';

const double _kHeight = 150.0;
const Duration _kEffectDuration = const Duration(seconds: 1);

class MimicDemo extends StatefulComponent {
  _MimicDemoState createState() => new _MimicDemoState();
}

class _MimicDemoState extends State<MimicDemo> {
  GlobalKey<MimicableState> _orange = new GlobalKey<MimicableState>();
  GlobalKey _targetContainer = new GlobalKey();

  bool _slotForOrangeOnTop = false;
  bool _orangeOnTop = false;

  void _handleTap() {
    if (_slotForOrangeOnTop)
      return;
    setState(() {
      _slotForOrangeOnTop = true;
    });
    MimicOverlayEntry entry = _orange.currentState.liftToOverlay();
    entry.animateTo(targetKey: _targetContainer, duration: _kEffectDuration, curve: Curves.ease).then((_) {
      setState(() {
        _orangeOnTop = true;
      });
      entry.dispose();
    });
  }

  void _reset() {
    setState(() {
      _slotForOrangeOnTop = false;
      _orangeOnTop = false;
    });
  }

  Widget _buildOrange() {
    return new Mimicable(
      key: _orange,
      child: new Container(
        height: _kHeight,
        decoration: new BoxDecoration(
          backgroundColor: Colors.deepOrange[500]
        )
      )
    );
  }

  Widget build(BuildContext context) {
    List<Widget> children = <Widget>[
      new Container(
        height: _kHeight,
        decoration: new BoxDecoration(
          backgroundColor: Colors.amber[500]
        )
      ),
      new AnimatedContainer(
        key: _targetContainer,
        height: _slotForOrangeOnTop ? _kHeight : 0.0,
        duration: _kEffectDuration,
        curve: Curves.ease,
        child: _orangeOnTop ? _buildOrange() : null
      ),
      new Container(
        height: _kHeight,
        decoration: new BoxDecoration(
          backgroundColor: Colors.green[500]
        )
      ),
      new Container(
        height: _kHeight,
        decoration: new BoxDecoration(
          backgroundColor: Colors.blue[500]
        )
      ),
    ];

    if (!_orangeOnTop)
      children.add(_buildOrange());

    return new GestureDetector(
      onTap: _handleTap,
      onLongPress: _reset,
      child: new Block(children)
    );
  }
}

void main() {
  runApp(new MaterialApp(
    title: 'Mimic Demo',
    routes: {
      '/': (_) => new MimicDemo()
    }
  ));
}
