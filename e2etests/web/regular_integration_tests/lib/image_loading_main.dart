// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const MethodChannel channel =
      OptionalMethodChannel('flutter/web_test_e2e', JSONMethodCodec());
  await channel.invokeMethod<void>(
    'setDevicePixelRatio',
    '1.5',
  );
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        key: const Key('mainapp'),
        title: 'Integration Test App',
        home: Column(children: <Widget>[
          Image.asset('assets/images/sample_image1.png'),
          Image.network('assets/images/sample_image1.png'),
      ])
    );
  }
}
