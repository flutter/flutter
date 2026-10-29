// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

String _initialRoute = 'Home Page';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChannels.navigation.setMethodCallHandler((MethodCall call) async {
    // Both cold and warm deep links are dispatched by FlutterEngine via pushRouteInformation.
    if (call.method == 'pushRouteInformation') {
      final dynamic args = call.arguments;
      final String location;
      if (args is Map) {
        // pushRouteInformation provides a map with 'location'
        location = (args['location'] as String?) ?? args.toString();
      } else {
        location = args.toString();
      }
      _initialRoute = location;
      // We also need to notify the UI if it's already running.
      if (_notifyRoute != null) {
        _notifyRoute!(location);
      }
      // Return false to explicitly signal to the engine that the route was not handled.
      return false;
    }
    return null;
  });
  runApp(const MyApp());
}

void Function(String)? _notifyRoute;

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _route = _initialRoute;

  @override
  void initState() {
    super.initState();
    _notifyRoute = (String location) {
      if (mounted) {
        setState(() {
          _route = location;
        });
      }
    };
  }

  @override
  void dispose() {
    _notifyRoute = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Deep Link Tester',
      home: Scaffold(
        appBar: AppBar(title: const Text('Home')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[Text(_route, key: const Key('routeText'))],
          ),
        ),
      ),
    );
  }
}
