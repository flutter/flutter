// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';

void main() {
  enableFlutterDriverExtension();
  runApp(const MyApp());
}

/// The main app entrance of the test
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

/// A page with a button in the center.
///
/// On press the button, a page with platform view should be pushed into the scene.
class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? ''),
      ),
      body: Column(children: <Widget>[
        TextButton(
          key: const ValueKey<String>('platform_view_button'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute<PlatformViewPage>(
                  builder: (BuildContext context) => const PlatformViewPage()),
            );
          },
          child: const Text('show platform view'),
        ),
        // Push this button to perform an animation, which ensure the threads are unmerged after the animation.
        ElevatedButton(
          key: const ValueKey<String>('unmerge_button'),
          onPressed: () {},
          child: const Text('Tap to unmerge threads'),
        ),
      ]),
    );
  }
}

/// A page contains the platform view to be tested.
class PlatformViewPage extends StatelessWidget {
  const PlatformViewPage({Key? key}) : super(key: key);

  static Key button = const ValueKey<String>('plus_button');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform View'),
      ),
      body: Column(
        children: <Widget>[
          const Expanded(
            child: SizedBox(
              width: 300,
              child: UiKitView(viewType: 'platform_view'),
            ),
          ),
          ElevatedButton(
            key: button,
            onPressed: (){},
            child: const Text('button'),
          )
        ],
      ),
    );
  }
}
