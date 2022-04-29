// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for Hero

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

void main() {
  // Slow down time to see Hero flight animation.
  timeDilation = 15.0;
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
      children: <Widget>[
        ListTile(
          leading: Hero(
            tag: 'hero-default-tween',
            child: _box(size: 50.0, color: Colors.red[700]!.withOpacity(0.5)),
          ),
          title: const Text(
            'This red icon will use a default rect tween during the hero flight.',
          ),
        ),
        const SizedBox(height: 10.0),
        ListTile(
          leading: Hero(
            tag: 'hero-custom-tween',
            createRectTween: (Rect? begin, Rect? end) {
              return MaterialRectCenterArcTween(begin: begin, end: end);
            },
            child: _box(size: 50.0, color: Colors.blue[700]!.withOpacity(0.5)),
          ),
          title: const Text(
            'This blue icon will use a custom rect tween during the hero flight.',
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () => _gotoDetailsPage(context),
          child: const Text('Tap to trigger hero flight'),
        ),
      ],
    );
  }

  Widget _box({double? size, Color? color}) {
    return Container(
      color: color,
      child: FlutterLogo(size: size),
    );
  }

  void _gotoDetailsPage(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Second Page'),
        ),
        body: Align(
          alignment: Alignment.bottomRight,
          child: Stack(
            children: <Widget>[
              Hero(
                tag: 'hero-custom-tween',
                createRectTween: (Rect? begin, Rect? end) {
                  return MaterialRectCenterArcTween(begin: begin, end: end);
                },
                child: _box(
                  size: 400.0,
                  color: Colors.blue[700]!.withOpacity(0.5),
                ),
              ),
              Hero(
                tag: 'hero-default-tween',
                child: _box(
                  size: 400.0,
                  color: Colors.red[700]!.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}
