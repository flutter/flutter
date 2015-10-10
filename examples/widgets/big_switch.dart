// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class BigSwitch extends StatefulComponent {
  BigSwitch({ this.scale });

  final double scale;

  BigSwitchState createState() => new BigSwitchState();
}

class BigSwitchState extends State<BigSwitch> {
  bool _value = false;

  void _handleOnChanged(bool value) {
    setState(() {
      _value = value;
    });
  }

  Widget build(BuildContext context) {
    Matrix4 scale = new Matrix4.identity();
    scale.scale(config.scale, config.scale);
    return new Transform(
      transform: scale,
      child: new Switch(value: _value, onChanged: _handleOnChanged)
    );
  }
}

void main() {
  runApp(new Container(
    child: new BigSwitch(scale: 5.0),
    padding: new EdgeDims.all(20.0),
    decoration: new BoxDecoration(
      backgroundColor: Colors.teal[600]
    )
  ));
}
