// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../common.dart';

// Various tests to verify that the Opacity layer propagates the opacity to various
// combinations of children that can apply it themselves.
// See https://github.com/flutter/flutter/issues/75697
class OpacityPeepholePage extends StatelessWidget {
  const OpacityPeepholePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Opacity Peephole tests')),
      body: ListView(
        key: const Key('${kOpacityPeepholeRouteName}_listview'),
        children: <Widget>[
          for (OpacityPeepholeCase variant in allOpacityPeepholeCases)
            ElevatedButton(
              key: Key(variant.route),
              child: Text(variant.name),
              onPressed: () {
                Navigator.pushNamed(context, variant.route);
              },
            )
        ],
      ),
    );
  }
}

typedef ValueBuilder = Widget Function(double v);
typedef AnimationBuilder = Widget Function(Animation<double> animation);

double _opacity(double v) => v * 0.5 + 0.25;
int _red(double v) => (v * 255).round();
int _green(double v) => _red(1 - v);
int _blue(double v) => 0;

class OpacityPeepholeCase {
  OpacityPeepholeCase.forValue({required String route, required String name, required ValueBuilder builder})
      : this.forAnimation(
    route: route,
    name: name,
    builder: (Animation<double> animation) => AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) => builder(animation.value),
    ),
  );

  OpacityPeepholeCase.forAnimation({required this.route, required this.name, required AnimationBuilder builder})
      : animationBuilder = builder;

  final String route;
  final String name;
  final AnimationBuilder animationBuilder;

  Widget buildPage(BuildContext context) {
    return VariantPage(variant: this);
  }
}

List<OpacityPeepholeCase> allOpacityPeepholeCases = <OpacityPeepholeCase>[
  // Tests that Opacity can hand down value to a simple child
  OpacityPeepholeCase.forValue(
    route: kOpacityPeepholeOneRectRouteName,
    name: 'One Big Rectangle',
    builder: (double v) {
      return Opacity(
        opacity: _opacity(v),
        child: Container(
          width: 300,
          height: 400,
          color: Color.fromARGB(255, _red(v), _green(v), _blue(v)),
        ),
      );
    }
  ),
  // Tests that a column of Opacity widgets can individually hand their values down to simple children
  OpacityPeepholeCase.forValue(
    route: kOpacityPeepholeColumnOfOpacityRouteName,
    name: 'Column of Opacity',
    builder: (double v) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          for (int i = 0; i < 10; i++, v = 1 - v)
            Opacity(
              opacity: _opacity(v),
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: Container(
                  width: 300,
                  height: 30,
                  color: Color.fromARGB(255, _red(v), _green(v), _blue(v)),
                ),
              ),
            ),
        ],
      );
    },
  ),
  // Tests that an Opacity can hand value down to a cached child
  OpacityPeepholeCase.forValue(
      route: kOpacityPeepholeOpacityOfCachedChildRouteName,
      name: 'Opacity of Cached Child',
      builder: (double v) {
        // ChildV starts as a constant so the same color pattern always appears and the child will be cached
        double childV = 0;
        return Opacity(
          opacity: _opacity(v),
          child: RepaintBoundary(
            child: SizedBox(
              width: 300,
              height: 400,
              child: Stack(
                children: <Widget>[
                  for (double i = 0; i < 100; i += 10, childV = 1 - childV)
                    Positioned.fromRelativeRect(
                      rect: RelativeRect.fromLTRB(i, i, i, i),
                      child: Container(
                        color: Color.fromARGB(255, _red(childV), _green(childV), _blue(childV)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }
  ),
  // Tests that an Opacity can hand a value down to a Column of simple non-overlapping children
  OpacityPeepholeCase.forValue(
    route: kOpacityPeepholeOpacityOfColumnRouteName,
    name: 'Opacity of Column',
    builder: (double v) {
      return Opacity(
        opacity: _opacity(v),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            for (int i = 0; i < 10; i++, v = 1 - v)
              Padding(
                padding: const EdgeInsets.all(5),
                // RepaintBoundary here to avoid combining children into 1 big Picture
                child: RepaintBoundary(
                  child: Container(
                    width: 300,
                    height: 30,
                    color: Color.fromARGB(255, _red(v), _green(v), _blue(v)),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  ),
  // Tests that an entire grid of Opacity objects can hand their values down to their simple children
  OpacityPeepholeCase.forValue(
    route: kOpacityPeepholeGridOfOpacityRouteName,
    name: 'Grid of Opacity',
    builder: (double v) {
      double rowV = v;
      double colV = rowV;
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          for (int i = 0; i < 10; i++, rowV = 1 - rowV, colV = rowV)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                for (int j = 0; j < 7; j++, colV = 1 - colV)
                  Opacity(
                    opacity: _opacity(colV),
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Container(
                        width: 30,
                        height: 30,
                        color: Color.fromARGB(255, _red(colV), _green(colV), _blue(colV)),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      );
    },
  ),
  // tests if an Opacity can hand its value down to a 2D grid of simple non-overlapping children.
  // The success of this case would depend on the sophistication of the non-overlapping tests.
  OpacityPeepholeCase.forValue(
    route: kOpacityPeepholeOpacityOfGridRouteName,
    name: 'Opacity of Grid',
    builder: (double v) {
      double rowV = v;
      double colV = rowV;
      return Opacity(
        opacity: _opacity(v),
        child: SizedBox(
          width: 300,
          height: 400,
          child: Stack(
            children: <Widget>[
              for (int i = 0; i < 10; i++, rowV = 1 - rowV, colV = rowV)
                for (int j = 0; j < 7; j++, colV = 1 - colV)
                  Positioned.fromRect(
                    rect: Rect.fromLTWH(j * 40 + 5, i * 40 + 5, 30, 30),
                    // RepaintBoundary here to avoid combining the 70 children into a single Picture
                    child: RepaintBoundary(
                      child: Container(
                        color: Color.fromARGB(255, _red(colV), _green(colV), _blue(colV)),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      );
    },
  ),
  // tests if an Opacity can hand its value down to a Column of non-overlapping rows of non-overlapping simple children.
  // This test only requires linear non-overlapping tests to succeed.
  OpacityPeepholeCase.forValue(
    route: kOpacityPeepholeOpacityOfColOfRowsRouteName,
    name: 'Opacity of Column of Rows',
    builder: (double v) {
      double rowV = v;
      double colV = v;
      return Opacity(
        opacity: _opacity(v),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            for (int i = 0; i < 10; i++, rowV = 1 - rowV, colV = rowV)
              Padding(
                padding: const EdgeInsets.only(top: 5, bottom: 5),
                // RepaintBoundary here to separate each row into a separate layer child
                child: RepaintBoundary(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      for (int j = 0; j < 7; j++, colV = 1 - colV)
                        Padding(
                          padding: const EdgeInsets.only(left: 5, right: 5),
                          // RepaintBoundary here to prevent the row children combining into a single Picture
                          child: RepaintBoundary(
                            child: Container(
                              width: 30,
                              height: 30,
                              color: Color.fromARGB(255, _red(colV), _green(colV), _blue(colV)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    },
  ),
  OpacityPeepholeCase.forAnimation(
    route: kOpacityPeepholeFadeTransitionTextRouteName,
    name: 'FadeTransition text',
    builder: (Animation<double> animation) {
      return FadeTransition(
        opacity: Tween<double>(begin: 0.25, end: 0.75).animate(animation),
        child: const SizedBox(
          width: 300,
          height: 400,
          child: Center(
            child: Text('Hello, World',
              style: TextStyle(fontSize: 48),
            ),
          ),
        ),
      );
    },
  ),
];

Map<String, WidgetBuilder> opacityPeepholeRoutes = <String, WidgetBuilder>{
  for (OpacityPeepholeCase variant in allOpacityPeepholeCases)
    variant.route: variant.buildPage,
};

class VariantPage extends StatefulWidget {
  const VariantPage({Key? key, required this.variant}) : super(key: key);

  final OpacityPeepholeCase variant;

  @override
  State<VariantPage> createState() => VariantPageState();
}

class VariantPageState extends State<VariantPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.variant.name),
      ),
      body: Center(
        child: widget.variant.animationBuilder(_controller),
      ),
    );
  }
}
