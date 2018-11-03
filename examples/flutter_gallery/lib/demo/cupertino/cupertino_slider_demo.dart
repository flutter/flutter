// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../gallery/demo.dart';

class CupertinoSliderDemo extends StatefulWidget {
  static const String routeName = '/cupertino/slider';

  @override
  _CupertinoSliderDemoState createState() => _CupertinoSliderDemoState();
}

class _CupertinoSliderDemoState extends State<CupertinoSliderDemo> {
  double _value = 25.0;
  double _discreteValue = 20.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cupertino Sliders'),
        actions: <Widget>[MaterialDemoDocumentationButton(CupertinoSliderDemo.routeName)],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget> [
                CupertinoSlider(
                  value: _value,
                  min: 0.0,
                  max: 100.0,
                  onChanged: (double value) {
                    setState(() {
                      _value = value;
                    });
                  }
                ),
                Text('Cupertino Continuous: ${_value.toStringAsFixed(1)}'),
              ]
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget> [
                CupertinoSlider(
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
                Text('Cupertino Discrete: $_discreteValue'),
              ]
            ),
          ],
        ),
      ),
    );
  }
}
