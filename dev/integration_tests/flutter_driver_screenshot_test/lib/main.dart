// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:device_info/device_info.dart';
import './image_page.dart';
import './page.dart';

final List<Page> _allPages = <Page>[
  const ImagePage(),
];

void main() {
  enableFlutterDriverExtension(handler: driverDataHandler.handleMessage);
  runApp(_MyApp());
}

class _MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Screenshot Tests',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const _MyHomePage(title: 'Screenshot Tests Home Page'),
    );
  }
}

class _MyHomePage extends StatefulWidget {
  const _MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<_MyHomePage> {
  @override
  void initState() {
    driverDataHandler.handlerCompleter.complete(_handleDriverMessage);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView.builder(
        itemCount: _allPages.length,
        itemBuilder: (_, int index) => ListTile(
          title: Text(_allPages[index].title, key: _allPages[index].key),
          onTap: () => _pushPage(context, _allPages[index]),
        ),
      ),
    );
  }

  void _pushPage(BuildContext context, Page page) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => page,
    ));
  }

  Future<String> _handleDriverMessage(String message) async {
    switch (message) {
      case 'device_model':
        String target;
        switch (Theme.of(context).platform) {
          case TargetPlatform.iOS:
            target = 'ios';
            break;
          case TargetPlatform.android:
            target = 'android';
            break;
          default:
            target = 'unsupported';
            break;
        }
        final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
        if (target == 'ios') {
          final IosDeviceInfo iosDeviceInfo = await deviceInfo.iosInfo;
          if (iosDeviceInfo.isPhysicalDevice) {
            return iosDeviceInfo.utsname.machine;
          } else {
            return 'sim_' + iosDeviceInfo.name;
          }
        } else if (target == 'android') {
          return (await deviceInfo.androidInfo).model;
        }
        break;
    }
    return 'unknown message: "$message"';
  }
}

class _FutureDataHandler {
  final Completer<DataHandler> handlerCompleter = Completer<DataHandler>();

  Future<String> handleMessage(String message) async {
    final DataHandler handler = await handlerCompleter.future;
    return handler(message);
  }
}

_FutureDataHandler driverDataHandler = _FutureDataHandler();
