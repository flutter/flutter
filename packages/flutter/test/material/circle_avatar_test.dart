// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CircleAvatar test', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Center(
        child: new CircleAvatar(
          backgroundColor: Colors.blue[400],
          radius: 50.0,
          child: new Text('Z')
        )
      )
    );

    RenderBox box = tester.renderObject(find.byType(CircleAvatar));
    expect(box.size.width, equals(100.0));
    expect(box.size.height, equals(100.0));

    expect(find.text('Z'), findsOneWidget);
  });
}
