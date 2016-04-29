// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Block inside LazyBlock', (WidgetTester tester) {
    tester.pumpWidget(new LazyBlock(
      delegate: new LazyBlockChildren(
        children: <Widget>[
          new Block(
            children: <Widget>[
              new Text('1'),
              new Text('2'),
              new Text('3'),
            ]
          ),
          new Block(
            children: <Widget>[
              new Text('4'),
              new Text('5'),
              new Text('6'),
            ]
          ),
        ]
      )
    ));
  });
}
