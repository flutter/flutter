// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final Random random = new Random();

Future<String> handleGetRandom(String json) async {
  Map<String, dynamic> message = JSON.decode(json);
  double min = message['min'].toDouble();
  double max = message['max'].toDouble();

  double value = (random.nextDouble() * (max - min)) + min;

  Map<String, double> reply = <String, double>{'value': value};
  return JSON.encode(reply);
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

  void _getLocation() {
    Map<String, String> message = <String, String>{'provider': 'network'};
    HostMessages.sendToHost('getLocation', JSON.encode(message))
        .then(_onReceivedLocation);
  }

  void _onReceivedLocation(String json) {
    Map<String, num> reply = JSON.decode(json);
    setState(() {
      _latitude = reply['latitude'].toDouble();
      _longitude = reply['longitude'].toDouble();
    });
  }
}

void main() {
  runApp(new HelloServices());

  HostMessages.addMessageHandler('getRandom', handleGetRandom);
}
