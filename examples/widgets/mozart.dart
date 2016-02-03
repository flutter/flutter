// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

const List<String> _kKnownApps = const <String>[
  'mojo:noodles_view',
  'mojo:shapes_view',
];

const Size _kSmallWindowSize = const Size(400.0, 400.0);
const Size _kBigWindowSize = const Size(600.0, 600.0);

class Window extends StatefulComponent {
  Window({ Key key, this.child }) : super(key: key);

  final ChildViewConnection child;

  _WindowState createState() => new _WindowState();
}

class _WindowState extends State<Window> {
  Offset _offset = Offset.zero;
  bool _isSmall = true;

  void _handlePanUpdate(Offset delta) {
    setState(() {
      _offset += delta;
    });
  }

  void _handleTap() {
    setState(() {
      _isSmall = !_isSmall;
    });
  }

  Widget build(BuildContext context) {
    Size size = _isSmall ? _kSmallWindowSize : _kBigWindowSize;
    return new Positioned(
      left: _offset.dx,
      top: _offset.dy,
      width: size.width,
      height: size.height,
      child: new GestureDetector(
        onPanUpdate: _handlePanUpdate,
        onTap: _handleTap,
        child: new ChildView(child: config.child)
      )
    );
  }
}

class WindowManager extends StatefulComponent {
  _WindowManagerState createState() => new _WindowManagerState();
}

class _WindowManagerState extends State<WindowManager> {
  List<ChildViewConnection> _windows = <ChildViewConnection>[];

  void _handleTap() {
    setState(() {
      _windows.add(new ChildViewConnection(url: _kKnownApps[_windows.length % _kKnownApps.length]));
    });
  }

  Widget build(BuildContext context) {
    return new GestureDetector(
      onTap: _handleTap,
      child: new Container(
        decoration: new BoxDecoration(
          backgroundColor: Colors.blue[500]
        ),
        child: new Stack(
          children: _windows.map((ChildViewConnection child) {
            return new Window(
              key: new ObjectKey(child),
              child: child
            );
          }).toList()
        )
      )
    );
  }
}

void main() {
  runApp(new MaterialApp(
    title: 'Mozart',
    routes: <String, RouteBuilder>{ '/': (_) => new WindowManager() }
  ));
}
