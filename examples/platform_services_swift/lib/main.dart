// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PlatformServices extends StatefulWidget {
  @override
  _PlatformServicesState createState() => new _PlatformServicesState();
}

class _PlatformServicesState extends State<PlatformServices> {
  static const PlatformMethodChannel methodChannel =
      const PlatformMethodChannel('io.flutter.samples/battery');
  static const PlatformEventChannel eventChannel =
      const PlatformEventChannel('io.flutter.samples/charging');

  String _batteryLevel = '';
  String _chargingStatus = '';

  Future<Null> _getBatteryLevel() async {
    String batteryLevel;
    try {
      final int result = await methodChannel.invokeMethod('getBatteryLevel');
      batteryLevel = 'Battery level at $result %.';
    } on PlatformException catch (e) {
      batteryLevel = "Failed to get battery level.";
    }
    setState(() {
      _batteryLevel = batteryLevel;
    });
  }

  @override
  void initState() {
    super.initState();
    eventChannel.receiveBroadcastStream().listen(_onEvent, onError: _onError);
  }

  void _onEvent(String event) {
    setState(() {
      _chargingStatus = " ${event == 'charging' ? '' : 'dis'}charging.";
    });
  }

  void _onError(PlatformException error) {
    setState(() {
      _chargingStatus = " unknown.";
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Material(
      child: new Center(
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            new Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                new Text(_batteryLevel, key: new Key('Battery level label')),
                new RaisedButton(
                  child: new Text('Refresh'),
                  onPressed: _getBatteryLevel,
                ),
              ],
            ),
            new SizedBox(height: 32.0),
            new Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                new Text("Battery status:"),
                new Text(_chargingStatus),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(new PlatformServices());
}
