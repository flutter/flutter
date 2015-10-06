// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/material.dart';
import 'package:sky/painting.dart';
import 'package:sky/services.dart';
import 'package:sky/src/widgets/basic.dart';
import 'package:sky/src/widgets/binding.dart';
import 'package:sky/src/widgets/framework.dart';
import 'package:sky/src/widgets/navigator.dart';
import 'package:sky/src/widgets/theme.dart';
import 'package:sky/src/widgets/title.dart';

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

class App extends StatefulComponent {
  App({
    Key key,
    this.title,
    this.theme,
    this.routes,
    this.onGenerateRoute
  }) : super(key: key) {
    assert(() {
      'The "routes" argument to App() is required.';
      'This might be a sign that you have not upgraded to our new Widgets framework.';
      'For more details see: https://groups.google.com/forum/#!topic/flutter-dev/hcX3OvLws9c';
      '...or look at our examples: https://github.com/flutter/engine/tree/master/examples';
      return routes != null;
    });
  }

  final String title;
  final ThemeData theme;
  final Map<String, RouteBuilder> routes;
  final RouteGenerator onGenerateRoute;

  _AppState createState() => new _AppState();
}

class _AppState extends State<App> {

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
