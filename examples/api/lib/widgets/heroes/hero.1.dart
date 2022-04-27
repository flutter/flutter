// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for Hero

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

void main() {
  // Slow down time to see Hero flight animation.
  timeDilation = 10.0;
  runApp(const HeroApp());
}

class HeroApp extends StatelessWidget {
  const HeroApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Hero Sample')),
        body: const Center(
          child: HeroExample(),
        ),
      ),
    );
  }
}

class HeroExample extends StatelessWidget {
  const HeroExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        ListTile(
          leading: Hero(
            tag: 'hero-default-tween',
            child: _blueRectangle(50.0),
          ),
          onTap: () => _gotoDetailsPage(context),
          title:
              const Text('Tap on the icon to view hero flight animation with default rect tween'),
        ),
        const SizedBox(
          height: 20.0,
        ),
        ListTile(
          leading: Hero(
            tag: 'hero-custom-tween',
            createRectTween: (Rect? begin, Rect? end) {
              return MaterialRectCenterArcTween(begin: begin, end: end);
            },
            child: _blueRectangle(50.0),
          ),
          onTap: () => _gotoDetailsPage(context),
          title:
              const Text('Tap on the icon to view hero flight animation with custom rect tween'),
        ),
      ],
    );
  }

  Widget _blueRectangle(double size) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue[100],
      ),
      child: FlutterLogo(size: size),
    );
  }

  void _gotoDetailsPage(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Second Page'),
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Hero(
                  tag: 'hero-default-tween',
                  child: _blueRectangle(200.0),
                ),
                const SizedBox(
                  height: 20.0,
                ),
                Hero(
                  tag: 'hero-custom-tween',
                  createRectTween: (Rect? begin, Rect? end) {
                    return MaterialRectCenterArcTween(begin: begin, end: end);
                  },
                  child: _blueRectangle(200.0),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}
