// Copyright (c) 2016, the Flutter project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class ExampleApp extends StatefulComponent {
  ExampleState createState() => new ExampleState();
}

const List<double> _ratios = const <double>[ 1.0, 1.8, 1.3, 2.4, 2.5, 2.6, 3.9 ];

class ExampleState extends State<ExampleApp> {

  int _index = 0;
  double _ratio = _ratios[0];

  final EdgeDims padding = new EdgeDims.TRBL(
    ui.window.padding.top,
    ui.window.padding.right,
    ui.window.padding.bottom,
    ui.window.padding.left
  );

  void _handlePressed() {
    setState(() {
      _index++;
      _index = _index % _ratios.length;
      _ratio = _ratios[_index];
    });
  }

  Widget build(BuildContext context) {
    const double size = 200.0; // 200 logical pixels
    TextStyle style = new TextStyle(color: const Color(0xFF0000000));
    return new MediaQuery(
      data: new MediaQueryData(
        size: ui.window.size,
        devicePixelRatio: _ratio,
        padding: padding
      ),
      child: new AssetVendor(
        bundle: rootBundle,
        devicePixelRatio: _ratio,
        child: new Material(
          child: new Padding(
            padding: const EdgeDims.symmetric(vertical: 48.0),
            child: new Column(
              children: <Widget>[
                new AssetImage(
                  name: 'assets/2.0x/starcircle.png',
                  height: size,
                  width: size,
                  fit: ImageFit.fill
                ),
                new Text('Image designed for pixel ratio 2.0', style: style),
                new AssetImage(
                  name: 'assets/starcircle.png',
                  height: size,
                  width: size,
                  fit: ImageFit.fill
                ),
                new Text(
                  'Image variant for pixel ratio: ' + _ratio.toString(),
                  style: style
                ),
                new RaisedButton(
                  child: new Text('Change pixel ratio', style: style),
                  onPressed: _handlePressed
                )
              ],
              justifyContent: FlexJustifyContent.spaceBetween
            )
          )
        )
      )
    );
  }
}

main() {
  runApp(new ExampleApp());
}
