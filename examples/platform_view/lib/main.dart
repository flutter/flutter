// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const PlatformView());
}

class PlatformView extends StatelessWidget {
  const PlatformView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Platform View',
      theme: ThemeData(
        primarySwatch: Colors.grey,
      ),
      home: const MyHomePage(title: 'Platform View'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const MethodChannel _methodChannel =
      MethodChannel('samples.flutter.io/platform_view');

  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  Future<void> _launchPlatformCount() async {
    final int? platformCounter =
        await _methodChannel.invokeMethod('switchView', _counter);
    setState(() {
      _counter = platformCounter!;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Button tapped $_counter time${ _counter == 1 ? '' : 's' }.',
                      style: const TextStyle(fontSize: 17.0),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: ElevatedButton(
                          child: Platform.isIOS
                              ? const Text('Continue in iOS view')
                              : const Text('Continue in Android view'),
                          onPressed: _launchPlatformCount),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.only(bottom: 15.0, left: 5.0),
              child: Row(
                children: <Widget>[
                  Image.asset('assets/flutter-mark-square-64.png',
                      scale: 1.5),
                  const Text(
                    'Flutter',
                    style: TextStyle(fontSize: 30.0),
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _incrementCounter,
          tooltip: 'Increment',
          child: const Icon(Icons.add),
        ),
      );
}
