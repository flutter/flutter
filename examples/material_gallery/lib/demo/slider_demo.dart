// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'widget_demo.dart';

class SliderDemo extends StatefulComponent {
  _SliderDemoState createState() => new _SliderDemoState();
}

class _SliderDemoState extends State<SliderDemo> {
  double _value = 25.0;

  Widget build(BuildContext context) {
    return new Block([
      new Container(
        height: 100.0,
        child: new Center(
          child:  new Row([
            new Slider(
              value: _value,
              min: 0.0,
              max: 100.0,
              onChanged: (double value) {
                setState(() {
                  _value = value;
                });
              }
            ),
            new Container(
              padding: const EdgeDims.symmetric(horizontal: 16.0),
              child: new Text(_value.round().toString().padLeft(3, '0'))
            ),
          ], justifyContent: FlexJustifyContent.collapse)
        )
      ),
      new Container(
        height: 100.0,
        child: new Center(
          child:  new Row([
            // Disabled, but tracking the slider above.
            new Slider(value: _value / 100.0),
            new Container(
              padding: const EdgeDims.symmetric(horizontal: 16.0),
              child: new Text((_value / 100.0).toStringAsFixed(2))
            ),
          ], justifyContent: FlexJustifyContent.collapse)
        )
      )

    ]);
  }
}

final WidgetDemo kSliderDemo = new WidgetDemo(
  title: 'Sliders',
  routeName: '/sliders',
  builder: (_) => new SliderDemo()
);
