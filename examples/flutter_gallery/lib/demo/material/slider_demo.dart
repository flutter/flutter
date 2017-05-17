// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class SliderDemo extends StatefulWidget {
  static const String routeName = '/material/slider';

  @override
  _SliderDemoState createState() => new _SliderDemoState();
}

class _SliderDemoState extends State<SliderDemo> {
  double _value = 25.0;
  double _discreteValue = 20.0;

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: const Text('Sliders')),
      body: new Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            new Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget> [
                new Slider(
                  value: _value,
                  min: 0.0,
                  max: 100.0,
                  thumbOpenAtMin: true,
                  onChanged: (double value) {
                    setState(() {
                      _value = value;
                    });
                  }
                ),
                const Text('Continuous'),
              ]
            ),
            new Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget> [
                const Slider(value: 0.25, thumbOpenAtMin: true, onChanged: null),
                const Text('Disabled'),
              ]
            ),
            new Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget> [
                new Slider(
                  value: _discreteValue,
                  min: 0.0,
                  max: 100.0,
                  divisions: 5,
                  label: '${_discreteValue.round()}',
                  thumbOpenAtMin: true,
                  onChanged: (double value) {
                    setState(() {
                      _discreteValue = value;
                    });
                  }
                ),
                const Text('Discrete'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
