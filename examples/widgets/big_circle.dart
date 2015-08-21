// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/widgets.dart';
import 'package:sky/theme/colors.dart' as colors;

class BigCircleApp extends App {
  Widget build() {
    return new Container(
        padding: new EdgeDims.all(50.0),
        decoration: new BoxDecoration(
          shape: Shape.circle,
          border: new Border.all(width: 10.0, color: const Color(0x80FF00FF)),
          backgroundColor: colors.Teal[600]
        )
    );
  }
}

void main() {
  runApp(new BigCircleApp());
}
