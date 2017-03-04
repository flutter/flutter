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
  static const PlatformMethodChannel platform = const PlatformMethodChannel('geo');
  String _location = 'Unknown location.';

  Future<Null> _getLocation() async {
    String location;
    try {
      final List<double> result = await platform.invokeMethod('getLocation', 'network');
      location = 'Latitude ${result[0]}, Longitude ${result[1]}.';
    } on PlatformException catch (e) {
      location = "Failed to get location: '${e.message}'.";
    }

    setState(() {
      _location = location;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Material(
      child: new Center(
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            new RaisedButton(
              child: new Text('Get Location'),
              onPressed: _getLocation,
            ),
            new Text(_location)
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(new PlatformServices());
}
