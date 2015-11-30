// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'page.dart';
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

AssetBundle _initDefaultBundle() {
  if (rootBundle != null)
    return rootBundle;
  const String _kAssetBase = '/packages/material_design_icons/icons/';
  return new NetworkAssetBundle(Uri.base.resolve(_kAssetBase));
}

final AssetBundle _defaultBundle = _initDefaultBundle();

class RouteArguments {
  const RouteArguments({ this.context });
  final BuildContext context;
}
typedef Widget RouteBuilder(RouteArguments args);
typedef RouteBuilder RouteGenerator(String name);

class MaterialApp extends StatefulComponent {
  MaterialApp({
    Key key,
    this.title,
    this.theme,
    this.routes: const <String, RouteBuilder>{},
    this.onGenerateRoute
  }) : super(key: key) {
    assert(routes != null);
    assert(routes.containsKey(Navigator.defaultRouteName) || onGenerateRoute != null);
  }

  final String title;
  final ThemeData theme;
  final Map<String, RouteBuilder> routes;
  final RouteGenerator onGenerateRoute;

  _MaterialAppState createState() => new _MaterialAppState();
}

class _MaterialAppState extends State<MaterialApp> implements BindingObserver {

  GlobalObjectKey _navigator;

  Size _size;

  void initState() {
    super.initState();
    _navigator = new GlobalObjectKey(this);
    _size = ui.window.size;
    FlutterBinding.instance.addObserver(this);
  }

  void dispose() {
    FlutterBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool didPopRoute() {
    assert(mounted);
    NavigatorState navigator = _navigator.currentState;
    assert(navigator != null);
    navigator.openTransaction((NavigatorTransaction transaction) {
      if (!transaction.pop())
        activity.finishCurrentActivity();
    });
    return true;
  }

  void didChangeSize(Size size) => setState(() { _size = size; });

  final HeroController _heroController = new HeroController();

  Route _generateRoute(NamedRouteSettings settings) {
    return new MaterialPageRoute(
      builder: (BuildContext context) {
        RouteBuilder builder = config.routes[settings.name] ?? config.onGenerateRoute(settings.name);
        return builder(new RouteArguments(context: context));
      },
      settings: settings
    );
  }

  Widget build(BuildContext context) {
    return new MediaQuery(
      data: new MediaQueryData(size: _size),
      child: new Theme(
        data: config.theme ?? new ThemeData.fallback(),
        child: new DefaultTextStyle(
          style: _errorTextStyle,
          child: new DefaultAssetBundle(
            bundle: _defaultBundle,
            child: new Title(
              title: config.title,
              child: new Navigator(
                key: _navigator,
                initialRoute: ui.window.defaultRouteName,
                onGenerateRoute: _generateRoute,
                observer: _heroController
              )
            )
          )
        )
      )
    );
  }

}
