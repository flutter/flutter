// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as sky;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';
import 'title.dart';

const TextStyle _errorTextStyle = const TextStyle(
  color: const Color(0xD0FF0000),
  fontFamily: 'monospace',
  fontSize: 48.0,
  fontWeight: FontWeight.w900,
  textAlign: TextAlign.right,
  decoration: underline,
  decorationColor: const Color(0xFFFF00),
  decorationStyle: TextDecorationStyle.double
);

class MaterialApp extends StatefulComponent {
  MaterialApp({
    Key key,
    this.title,
    this.theme,
    this.routes,
    this.onGenerateRoute
  }) : super(key: key) {
    assert(routes != null);
  }

  final String title;
  final ThemeData theme;
  final Map<String, RouteBuilder> routes;
  final RouteGenerator onGenerateRoute;

  _MaterialAppState createState() => new _MaterialAppState();
}

class _MaterialAppState extends State<MaterialApp> {

  GlobalObjectKey _navigator;

  void initState() {
    super.initState();
    _navigator = new GlobalObjectKey(this);
    WidgetFlutterBinding.instance.addEventListener(_backHandler);
  }

  void dispose() {
    WidgetFlutterBinding.instance.removeEventListener(_backHandler);
    super.dispose();
  }

  void _backHandler(sky.Event event) {
    assert(mounted);
    if (event.type == 'back') {
      NavigatorState navigator = _navigator.currentState;
      assert(navigator != null);
      if (navigator.hasPreviousRoute)
        navigator.pop();
      else
        activity.finishCurrentActivity();
    }
  }

  Widget build(BuildContext context) {
    return new Theme(
      data: config.theme ?? new ThemeData.fallback(),
      child: new DefaultTextStyle(
        style: _errorTextStyle,
        child: new Title(
          title: config.title,
          child: new Navigator(
            key: _navigator,
            routes: config.routes,
            onGenerateRoute: config.onGenerateRoute
          )
        )
      )
    );
  }

}
