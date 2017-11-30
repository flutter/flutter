// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CupertinoSliderDemo extends StatefulWidget {
  static const String routeName = '/cupertino/slider';

  @override
  _CupertinoSliderDemoState createState() => new _CupertinoSliderDemoState();
}

class _CupertinoSliderDemoState extends State<CupertinoSliderDemo> {
  double _value = 25.0;
  double _discreteValue = 20.0;

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: const Text('Cupertino Sliders'),
      ),
      body: new Center(
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            new Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget> [
                new CupertinoSlider(
                  value: _value,
                  min: 0.0,
                  max: 100.0,
                  onChanged: (double value) {
                    setState(() {
                      _value = value;
                    });
                  }
                ),
                new Text('Cupertino Continuous: ${_value.toStringAsFixed(1)}'),
              ]
            ),
            new Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget> [
                new CupertinoSlider(
                  value: _discreteValue,
                  min: 0.0,
                  max: 100.0,
                  divisions: 5,
                  onChanged: (double value) {
                    setState(() {
                      _discreteValue = value;
                    });
                  }
                ),
                new Text('Cupertino Discrete: $_discreteValue'),
              ]
            ),
          ],
        ),
      ),
    );
  }
}
