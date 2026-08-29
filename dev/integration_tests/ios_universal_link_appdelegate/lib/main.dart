// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

String _initialRoute = 'Home Page';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChannels.navigation.setMethodCallHandler((MethodCall call) async {
    stderr.writeln('Engine sent: ${call.method} ${call.arguments}');
    if (call.method == 'pushRouteInformation' || call.method == 'pushRoute') {
      final dynamic args = call.arguments;
      var location = '';
      if (args is Map) {
        location = (args['location'] as String?) ?? args.toString();
      } else if (args is String) {
        location = args;
      } else if (args != null) {
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
  String _pluginEvents = 'No Plugin Events';

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
    _pollPluginEvents();
  }

  @override
  void dispose() {
    _notifyRoute = null;
    super.dispose();
  }

  Future<void> _pollPluginEvents() async {
    const channel = MethodChannel('lifecycle_detector');
    while (mounted) {
      try {
        final List<dynamic>? events = await channel.invokeListMethod<dynamic>('getEvents');
        if (events != null && events.isNotEmpty) {
          setState(() {
            // Keep as a list of strings
            _pluginEvents = events.join('\n');
          });
        }
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
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
            children: <Widget>[
              Text(_route, key: const Key('routeText')),
              ..._pluginEvents.split('\n').map((String event) => Text(event)),
            ],
          ),
        ),
      ),
    );
  }
}
