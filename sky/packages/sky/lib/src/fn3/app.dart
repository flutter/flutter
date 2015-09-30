// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/material.dart';
import 'package:sky/painting.dart';
import 'package:sky/services.dart';
import 'package:sky/src/fn3/basic.dart';
import 'package:sky/src/fn3/binding.dart';
import 'package:sky/src/fn3/framework.dart';
import 'package:sky/src/fn3/navigator.dart';
import 'package:sky/src/fn3/theme.dart';
import 'package:sky/src/fn3/title.dart';

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
    this.routes
  }): super(key: key);

  final String title;
  final ThemeData theme;
  final Map<String, RouteBuilder> routes;

  AppState createState() => new AppState();
}

class AppState extends State<App> {

  GlobalObjectKey _navigator;

  void initState(BuildContext context) {
    super.initState(context);
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
            routes: config.routes
          )
        )
      )
    );
  }

}