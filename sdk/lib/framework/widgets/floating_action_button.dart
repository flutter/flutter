// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../theme2/colors.dart';
import '../theme2/edges.dart';
import 'button_base.dart';
import 'ink_well.dart';
import 'material.dart';
import 'basic.dart';

// TODO(eseidel): This needs to change based on device size?
// http://www.google.com/design/spec/layout/metrics-keylines.html#metrics-keylines-keylines-spacing
const double _kSize = 56.0;

class FloatingActionButton extends ButtonBase {

  FloatingActionButton({ Object key, this.child })
      : super(key: key);

  final UINode child;

  UINode buildContent() {
    return new Material(
      child: new ClipOval(
        child: new Container(
          width: _kSize,
          height: _kSize,
          child: new InkWell(child: new Center(child: child))
        )
      ),
      color: Red[500],
      edge: MaterialEdge.circle,
      level: highlight ? 3 : 2
    );
  }

}
