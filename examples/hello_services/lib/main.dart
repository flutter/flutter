// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final Random random = new Random();

final PlatformMethodChannel randomChannel = new PlatformMethodChannel('random');

Future<dynamic> handleGetRandom(MethodCall call) async {
  if (call.method == 'getRandom') {
    final int min = call.arguments[0];
    final int max = call.arguments[1];
    return random.nextInt(max - min) + min;
  }
}

class HelloServices extends StatefulWidget {
  @override
  _HelloServicesState createState() => new _HelloServicesState();
}

class _HelloServicesState extends State<HelloServices> {
  static PlatformMethodChannel locationChannel = new PlatformMethodChannel('location');
  String _location = 'Press button to get location';

  @override
  Widget build(BuildContext context) {
    return new Material(
      child: new Center(
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            new Text('Hello from Flutter!'),
            new RaisedButton(
              child: new Text('Get Location'),
              onPressed: _getLocation,
            ),
            new Text(_location),
          ],
        ),
      ),
    );
  }

  Future<Null> _getLocation() async {
    String location;
    try {
      final List<double> reply = await locationChannel.invokeMethod(
        'getLocation',
        'network',
      );
      location = 'Latitude: ${reply[0]}, Longitude: ${reply[1]}';
    } on PlatformException catch(e) {
      location = 'Error: ' + e.message;
    }
    // If the widget was removed from the tree while the message was in flight,
    // we want to discard the reply rather than calling setState to update our
    // non-existent appearance.
    if (!mounted) return;
    setState(() {
      _location = location;
    });
  }
}

void main() {
  runApp(new HelloServices());
  randomChannel.setMethodCallHandler(handleGetRandom);
}
