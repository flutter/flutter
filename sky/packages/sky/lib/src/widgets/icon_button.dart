// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/src/widgets/basic.dart';
import 'package:sky/src/widgets/icon.dart';
import 'package:sky/src/widgets/framework.dart';
import 'package:sky/src/widgets/gesture_detector.dart';

class IconButton extends Component {

  IconButton({ Key key, this.icon, this.onPressed, this.color }) : super(key: key);

  final String icon;
  final Function onPressed;
  final Color color;

  Widget build() {
    Widget child = new Icon(type: icon, size: 24);
    if (color != null) {
      child = new ColorFilter(
        color: color,
        transferMode: sky.TransferMode.srcATop,
        child: child
      );
    }
    return new GestureDetector(
      onTap: onPressed,
      child: new Padding(
        child: child,
        padding: const EdgeDims.all(8.0))
    );
  }

}
