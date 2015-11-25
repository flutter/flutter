// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'widget_demo.dart';

class SliderDemo extends StatefulComponent {
  _SliderDemoState createState() => new _SliderDemoState();
}

class _SliderDemoState extends State<SliderDemo> {
  double _value = 0.25;

  Widget build(BuildContext context) {
    Widget label = new Container(
      padding: const EdgeDims.symmetric(horizontal: 16.0),
      child: new Text(_value.toStringAsFixed(2))
    );
    return new Block([
      new Container(
        height: 100.0,
        child: new Center(
          child:  new Row([
            new Slider(
              value: _value,
              onChanged: (double value) {
                setState(() {
                  _value = value;
                });
              }
            ),
            label,
          ], justifyContent: FlexJustifyContent.collapse)
        )
      ),
      new Container(
        height: 100.0,
        child: new Center(
          child:  new Row([
            // Disabled, but tracking the slider above.
            new Slider(value: _value),
            label,
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
