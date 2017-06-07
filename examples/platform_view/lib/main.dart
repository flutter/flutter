// Copyright 2017, the Flutter project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(new PlatformView());
}

class PlatformView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Platform View',
      theme: new ThemeData(
        primarySwatch: Colors.grey,
      ),
      home: new MyHomePage(title: 'Platform View'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const MethodChannel _methodChannel =
      const MethodChannel("samples.flutter.io/platform_view");

  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  Future<Null> _launchPlatformCount() async {
    final int platformCounter =
        await _methodChannel.invokeMethod("switchView", _counter);
    setState(() {
      _counter = platformCounter;
    });
  }

  @override
  Widget build(BuildContext context) => new Scaffold(
        appBar: new AppBar(
          title: new Text(widget.title),
        ),
        body: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new Expanded(
              child: new Center(
                child: new Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    new Text(
                      'Button tapped $_counter time${ _counter == 1 ? '' : 's' }.',
                      style: const TextStyle(fontSize: 17.0),
                    ),
                    new Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: new RaisedButton(
                          child: Platform.isIOS
                              ? const Text('Continue in iOS view')
                              : const Text('Continue in Android view'),
                          onPressed: _launchPlatformCount),
                    ),
                  ],
                ),
              ),
            ),
            new Container(
              padding: const EdgeInsets.only(bottom: 15.0, left: 5.0),
              child: new Row(
                children: <Widget>[
                  new Image.asset('assets/flutter-mark-square-64.png',
                      scale: 1.5),
                  const Text(
                    'Flutter',
                    style: const TextStyle(fontSize: 30.0),
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: new FloatingActionButton(
          onPressed: _incrementCounter,
          tooltip: 'Increment',
          child: const Icon(Icons.add),
        ),
      );
}
