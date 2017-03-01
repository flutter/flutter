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
  Future<dynamic> _locationRequest;

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
              onPressed: _requestLocation,
            ),
            new FutureBuilder<dynamic>(
              future: _locationRequest,
              builder: _buildLocation,
            ),
          ],
        ),
      ),
    );
  }

  void _requestLocation() {
    setState(() {
      _locationRequest = const PlatformMethodChannel('geo').invokeMethod(
        'getLocation',
        'network',
      );
    });
  }

  Widget _buildLocation(BuildContext context, AsyncSnapshot<dynamic> snapshot) {
    switch (snapshot.connectionState) {
      case ConnectionState.none:
        return new Text('Press button to request location');
      case ConnectionState.waiting:
        return new Text('Awaiting response...');
      default:
        try {
          final List<double> location = snapshot.requireData;
          return new Text('Lat. ${location[0]}, Long. ${location[1]}');
        } on PlatformException catch (e) {
          return new Text('Request failed: ${e.message}');
        }
    }
  }
}

void main() {
  runApp(new PlatformServices());
}
