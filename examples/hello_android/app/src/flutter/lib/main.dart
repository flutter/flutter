// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

final Random random = new Random();

Future<String> handleGetRandom(String json) async {
  Map message = JSON.decode(json);
  double min = message['min'].toDouble();
  double max = message['max'].toDouble();

  double value = (random.nextDouble() * (max - min)) + min;

  Map reply = {'value': value};
  return JSON.encode(reply);
}

class HelloAndroid extends StatefulWidget {
  @override
  _HelloAndroidState createState() => new _HelloAndroidState();
}

class _HelloAndroidState extends State<HelloAndroid> {
  double _latitude;
  double _longitude;

  @override
  Widget build(BuildContext context) {
    return new Material(
      child: new Center(
        child: new Column(
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

  void _getLocation() {
    Map message = {'provider': 'network'};
    HostMessages.sendToHost('getLocation', JSON.encode(message))
        .then(_onReceivedLocation);
  }

  void _onReceivedLocation(String json) {
    Map reply = JSON.decode(json);
    setState(() {
      _latitude = reply['latitude'];
      _longitude = reply['longitude'];
    });
  }
}

void main() {
  runApp(new HelloAndroid());

  HostMessages.addMessageHandler('getRandom', handleGetRandom);
}
