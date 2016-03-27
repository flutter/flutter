// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'theme.dart';

class Divider extends StatelessWidget {
  Divider({ Key key, this.height: 16.0, this.indent: 0.0, this.color }) : super(key: key) {
    assert(height >= 1.0);
  }

  final double height;
  final double indent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final double bottom = (height ~/ 2.0).toDouble();
    return new Container(
      height: 0.0,
      margin: new EdgeInsets.only(
        top: height - bottom - 1.0,
        left: indent,
        bottom: bottom
      ),
      decoration: new BoxDecoration(
        border: new Border(
          bottom: new BorderSide(color: color ?? Theme.of(context).dividerColor)
        )
      )
    );
  }
}
