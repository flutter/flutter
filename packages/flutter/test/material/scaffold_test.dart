// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:test/test.dart';

void main() {
  testWidgets('Scaffold control test', (WidgetTester tester) {
      Key bodyKey = new UniqueKey();
      tester.pumpWidget(new Scaffold(
        appBar: new AppBar(title: new Text('Title')),
        body: new Container(key: bodyKey)
      ));

      RenderBox bodyBox = tester.renderObject(find.byKey(bodyKey));
      expect(bodyBox.size, equals(new Size(800.0, 544.0)));

      tester.pumpWidget(new MediaQuery(
        data: new MediaQueryData(padding: new EdgeInsets.only(bottom: 100.0)),
        child: new Scaffold(
          appBar: new AppBar(title: new Text('Title')),
          body: new Container(key: bodyKey)
        )
      ));

      bodyBox = tester.renderObject(find.byKey(bodyKey));
      expect(bodyBox.size, equals(new Size(800.0, 444.0)));

      tester.pumpWidget(new MediaQuery(
        data: new MediaQueryData(padding: new EdgeInsets.only(bottom: 100.0)),
        child: new Scaffold(
          appBar: new AppBar(title: new Text('Title')),
          body: new Container(key: bodyKey),
          resizeToAvoidBottomPadding: false
        )
      ));

      bodyBox = tester.renderObject(find.byKey(bodyKey));
      expect(bodyBox.size, equals(new Size(800.0, 544.0)));
  });
}
