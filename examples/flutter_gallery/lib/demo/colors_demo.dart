// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const double kColorItemHeight = 48.0;

class Palette {
  Palette({ this.name, this.primary, this.accent, this.threshold: 900});

  final String name;
  final MaterialColor primary;
  final MaterialAccentColor accent;
  final int threshold; // titles for indices > threshold are white, otherwise black

  bool get isValid => name != null && primary != null && threshold != null;
}

final List<Palette> allPalettes = <Palette>[
  new Palette(name: 'RED', primary: Colors.red, accent: Colors.redAccent, threshold: 300),
  new Palette(name: 'PINK', primary: Colors.pink, accent: Colors.pinkAccent, threshold: 200),
  new Palette(name: 'PURPLE', primary: Colors.purple, accent: Colors.purpleAccent, threshold: 200),
  new Palette(name: 'DEEP PURPLE', primary: Colors.deepPurple, accent: Colors.deepPurpleAccent, threshold: 200),
  new Palette(name: 'INDIGO', primary: Colors.indigo, accent: Colors.indigoAccent, threshold: 200),
  new Palette(name: 'BLUE', primary: Colors.blue, accent: Colors.blueAccent, threshold: 400),
  new Palette(name: 'LIGHT BLUE', primary: Colors.lightBlue, accent: Colors.lightBlueAccent, threshold: 500),
  new Palette(name: 'CYAN', primary: Colors.cyan, accent: Colors.cyanAccent, threshold: 600),
  new Palette(name: 'TEAL', primary: Colors.teal, accent: Colors.tealAccent, threshold: 400),
  new Palette(name: 'GREEN', primary: Colors.green, accent: Colors.greenAccent, threshold: 500),
  new Palette(name: 'LIGHT GREEN', primary: Colors.lightGreen, accent: Colors.lightGreenAccent, threshold: 600),
  new Palette(name: 'LIME', primary: Colors.lime, accent: Colors.limeAccent, threshold: 800),
  new Palette(name: 'YELLOW', primary: Colors.yellow, accent: Colors.yellowAccent),
  new Palette(name: 'AMBER', primary: Colors.amber, accent: Colors.amberAccent),
  new Palette(name: 'ORANGE', primary: Colors.orange, accent: Colors.orangeAccent, threshold: 700),
  new Palette(name: 'DEEP ORANGE', primary: Colors.deepOrange, accent: Colors.deepOrangeAccent, threshold: 400),
  new Palette(name: 'BROWN', primary: Colors.brown, threshold: 200),
  new Palette(name: 'GREY', primary: Colors.grey, threshold: 500),
  new Palette(name: 'BLUE GREY', primary: Colors.blueGrey, threshold: 500),
];


class ColorItem extends StatelessWidget {
  ColorItem({
    Key key,
    @required this.index,
    @required this.color,
    this.prefix: '',
  }) : assert(index != null),
       assert(color != null),
       assert(prefix != null),
       super(key: key);

  final int index;
  final Color color;
  final String prefix;

  String colorString() => "#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}";

  @override
  Widget build(BuildContext context) {
    return new Container(
      height: kColorItemHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      color: color,
      child: new Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          new Text('$prefix$index'),
          new Text(colorString()),
        ],
      ),
    );
  }
}

class PaletteTabView extends StatelessWidget {
  static const List<int> primaryKeys = const <int>[50, 100, 200, 300, 400, 500, 600, 700, 800, 900];
  static const List<int> accentKeys = const <int>[100, 200, 400, 700];

  PaletteTabView({
    Key key,
    @required this.colors,
  }) : assert(colors != null && colors.isValid),
       super(key: key);

  final Palette colors;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TextStyle whiteTextStyle = textTheme.body1.copyWith(color: Colors.white);
    final TextStyle blackTextStyle = textTheme.body1.copyWith(color: Colors.black);
    final List<Widget> colorItems =  primaryKeys.map((int index) {
      return new DefaultTextStyle(
        style: index > colors.threshold ? whiteTextStyle : blackTextStyle,
        child: new ColorItem(index: index, color: colors.primary[index]),
      );
    }).toList();

    if (colors.accent != null) {
      colorItems.addAll(accentKeys.map((int index) {
        return new DefaultTextStyle(
          style: index > colors.threshold ? whiteTextStyle : blackTextStyle,
          child: new ColorItem(index: index, color: colors.accent[index], prefix: 'A'),
        );
      }).toList());
    }

    return new ListView(
      itemExtent: kColorItemHeight,
      children: colorItems,
    );
  }
}

class ColorsDemo extends StatelessWidget {
  static const String routeName = '/colors';

  @override
  Widget build(BuildContext context) {
    return new DefaultTabController(
      length: allPalettes.length,
      child: new Scaffold(
        appBar: new AppBar(
          elevation: 0.0,
          title: const Text('Colors'),
          bottom: new TabBar(
            isScrollable: true,
            tabs: allPalettes.map((Palette swatch) => new Tab(text: swatch.name)).toList(),
          ),
        ),
        body: new TabBarView(
          children: allPalettes.map((Palette colors) {
            return new PaletteTabView(colors: colors);
          }).toList(),
        ),
      ),
    );
  }
}
