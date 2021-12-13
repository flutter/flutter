// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navKey = GlobalKey(debugLabel: 'mainNavigator');
Map<String, WidgetBuilder>? appRoutes;

final Map<String, WidgetBuilder> _defaultAppRoutes = <String, WidgetBuilder>{
  '/': (BuildContext context) => Container(),
};

void main() {
  runApp(MyApp(appRoutes ?? _defaultAppRoutes));
}

class MyApp extends StatelessWidget {
  const MyApp(this.routes, {Key? key}) : super(key: key);

  final Map<String, WidgetBuilder> routes;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      key: const Key('mainapp'),
      navigatorKey: navKey,
      theme: ThemeData(fontFamily: 'RobotoMono'),
      title: 'Integration Test App',
      routes: routes,
    );
  }
}
