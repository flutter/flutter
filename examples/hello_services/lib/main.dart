// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final Random random = new Random();

Future<dynamic> handleGetRandom(Map<String, dynamic> message) async {
  final double min = message['min'].toDouble();
  final double max = message['max'].toDouble();

  return <String, double>{
    'value': (random.nextDouble() * (max - min)) + min
  };
}

class HelloServices extends StatefulWidget {
  @override
  _HelloServicesState createState() => new _HelloServicesState();
}

class _HelloServicesState extends State<HelloServices> {
  double _latitude;
  double _longitude;

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
              onPressed: _getLocation
            ),
            new Text('Latitude: $_latitude, Longitude: $_longitude'),
          ]
        )
      )
    );
  }

  Future<Null> _getLocation() async {
    final Map<String, String> message = <String, String>{'provider': 'network'};
    final Map<String, dynamic> reply = await PlatformMessages.sendJSON('getLocation', message);
    // If the widget was removed from the tree while the message was in flight,
    // we want to discard the reply rather than calling setState to update our
    // non-existent appearance.
    if (!mounted)
      return;
    setState(() {
      _latitude = reply['latitude'].toDouble();
      _longitude = reply['longitude'].toDouble();
    });
  }
}

void main() {
  runApp(new HelloServices());

  PlatformMessages.setJSONMessageHandler('getRandom', handleGetRandom);
}
