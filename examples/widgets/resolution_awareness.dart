// Copyright (c) 2016, the Flutter project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class ExampleApp extends StatefulComponent {
  ExampleState createState() => new ExampleState();
}

List<double> ratios = <double>[ 1.0, 1.8, 1.3, 2.4, 2.5, 2.6, 3.9 ];

class ExampleState extends State<ExampleApp> {

  int index = 0;
  double ratio = ratios[0];

  final EdgeDims padding = new EdgeDims.TRBL(
    ui.window.padding.top,
    ui.window.padding.right,
    ui.window.padding.bottom,
    ui.window.padding.left
  );

  void advance() {
    setState(() {
      index++;
      index = index % ratios.length;
      ratio = ratios[index];
    });
  }

  Widget build(BuildContext context) {
    return new MediaQuery(
      data: new MediaQueryData(
        size: ui.window.size,
        devicePixelRatio: ratio,
        padding: padding
      ),
      child: new DefaultAssetBundle(
        bundle: rootBundle,
        child: new Container(
          margin: const EdgeDims.symmetric(vertical: 48.0),
          decoration: new BoxDecoration(backgroundColor: const Color(0xFF66AABB)),
          child: new Column(
            children: <Widget>[
              new AssetImage(
                name: 'assets/2.0x/world.png',
                height: 192.0,
                width: 192.0,
                fit: ImageFit.fill
              ),
              new Text('Image designed for pixel ratio 2.0'),
              new GestureDetector(
                child: new ResolutionAwareAssetImage(
                  name: 'assets/world',
                  height: 192.0,
                  width: 192.0,
                  fit: ImageFit.fill
                ),
                onTap: this.advance
              ),
              new Text('Declared pixel ratio: ' + ratio.toString()),
              new Text('(tap lower image to change)')
            ],
            justifyContent: FlexJustifyContent.spaceAround
          )
        )
      )
    );
  }
}

main() {
  runApp(new ExampleApp());
}
