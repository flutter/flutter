// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

const double kColorItemHeight = 48.0;

class ColorSwatch {
  const ColorSwatch({ this.name, this.colors, this.accentColors, this.threshold: 900});

  final String name;
  final Map<int, Color> colors;
  final Map<int, Color> accentColors;
  final int threshold; // titles for indices > threshold are white, otherwise black

  bool get isValid => this.name != null && this.colors != null && threshold != null;
}

const List<ColorSwatch> colorSwatches = const <ColorSwatch>[
  const ColorSwatch(name: 'RED', colors: Colors.red, accentColors: Colors.redAccent, threshold: 300),
  const ColorSwatch(name: 'PINK', colors: Colors.pink, accentColors: Colors.pinkAccent, threshold: 200),
  const ColorSwatch(name: 'PURPLE', colors: Colors.purple, accentColors: Colors.purpleAccent, threshold: 200),
  const ColorSwatch(name: 'DEEP PURPLE', colors: Colors.deepPurple, accentColors: Colors.deepPurpleAccent, threshold: 200),
  const ColorSwatch(name: 'INDIGO', colors: Colors.indigo, accentColors: Colors.indigoAccent, threshold: 200),
  const ColorSwatch(name: 'BLUE', colors: Colors.blue, accentColors: Colors.blueAccent, threshold: 400),
  const ColorSwatch(name: 'LIGHT BLUE', colors: Colors.lightBlue, accentColors: Colors.lightBlueAccent, threshold: 500),
  const ColorSwatch(name: 'CYAN', colors: Colors.cyan, accentColors: Colors.cyanAccent, threshold: 600),
  const ColorSwatch(name: 'TEAL', colors: Colors.teal, accentColors: Colors.tealAccent, threshold: 400),
  const ColorSwatch(name: 'GREEN', colors: Colors.green, accentColors: Colors.greenAccent, threshold: 500),
  const ColorSwatch(name: 'LIGHT GREEN', colors: Colors.lightGreen, accentColors: Colors.lightGreenAccent, threshold: 600),
  const ColorSwatch(name: 'LIME', colors: Colors.lime, accentColors: Colors.limeAccent, threshold: 800),
  const ColorSwatch(name: 'YELLOW', colors: Colors.yellow, accentColors: Colors.yellowAccent),
  const ColorSwatch(name: 'AMBER', colors: Colors.amber, accentColors: Colors.amberAccent),
  const ColorSwatch(name: 'ORANGE', colors: Colors.orange, accentColors: Colors.orangeAccent, threshold: 700),
  const ColorSwatch(name: 'DEEP ORANGE', colors: Colors.deepOrange, accentColors: Colors.deepOrangeAccent, threshold: 400),
  const ColorSwatch(name: 'BROWN', colors: Colors.brown, threshold: 200),
  const ColorSwatch(name: 'GREY', colors: Colors.grey, threshold: 500),
  const ColorSwatch(name: 'BLUE GREY', colors: Colors.blueGrey, threshold: 500)
];


class ColorItem extends StatelessWidget {
  ColorItem({ Key key, this.index, this.color, this.prefix: '' }) : super(key: key) {
    assert(index != null);
    assert(color != null);
    assert(prefix != null);
  }

  final int index;
  final Color color;
  final String prefix;

  String colorString() => "#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}";

  @override
  Widget build(BuildContext context) {
    return new Container(
      height: kColorItemHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: new BoxDecoration(backgroundColor: color),
      child: new Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          new Text('$prefix$index'),
          new Text(colorString())
        ]
      )
    );
  }
}

class ColorSwatchTabView extends StatelessWidget {
  ColorSwatchTabView({ Key key, this.swatch }) : super(key: key) {
    assert(swatch != null && swatch.isValid);
  }

  final ColorSwatch swatch;
  final TextStyle blackTextStyle = Typography.black.body1;
  final TextStyle whiteTextStyle = Typography.white.body1;

  @override
  Widget build(BuildContext context) {
    List<Widget> colorItems =  swatch.colors.keys.map((int index) {
      return new DefaultTextStyle.explicit(
        style: index > swatch.threshold ? whiteTextStyle : blackTextStyle,
        child: new ColorItem(index: index, color: swatch.colors[index])
      );
    })
    .toList();

    if (swatch.accentColors != null) {
      colorItems.addAll(swatch.accentColors.keys.map((int index) {
        return new DefaultTextStyle.explicit(
          style: index > swatch.threshold ? whiteTextStyle : blackTextStyle,
          child: new ColorItem(index: index, color: swatch.accentColors[index], prefix: 'A')
        );
      })
      .toList());
    }

    return new ScrollableList(
      itemExtent: kColorItemHeight,
      children: colorItems
    );
  }
}

class ColorsDemo extends StatelessWidget {
  static const String routeName = '/colors';

  @override
  Widget build(BuildContext context) {
    return new TabBarSelection<ColorSwatch>(
      values: colorSwatches,
      child: new Scaffold(
        appBar: new AppBar(
          elevation: 0,
          title: new Text('Colors'),
          tabBar: new TabBar<ColorSwatch>(
            isScrollable: true,
            labels: new Map<ColorSwatch, TabLabel>.fromIterable(colorSwatches, value: (ColorSwatch swatch) {
              return new TabLabel(text: swatch.name);
            })
          )
        ),
        body: new TabBarView<ColorSwatch>(
          children: colorSwatches.map((ColorSwatch swatch) {
            return new ColorSwatchTabView(swatch: swatch);
          })
          .toList()
        )
      )
    );
  }
}
