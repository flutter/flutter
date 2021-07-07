// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('build recorder can record the element trees', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Hello'),
        ),
      )
    ));

    final BuildRecorder buildRecorder = BuildRecorder();
    Element.debugBuildRecorder = buildRecorder;

    await tester.pump();
    buildRecorder.finishFrame(0);

    final Map<String, Object> data = buildRecorder.toJson();

    expect(data['frames'], isNotNull);

    final List<Object?> frames = data['frames']! as List<Object?>;
    expect(frames[0], isNotNull);

    final Map<String, Object?> frameData = frames[0]! as Map<String, Object?>;
    expect(frameData['id'], 0);
    expect(frameData['widgets'], isNotNull);

    final Map<String, Object?> widgetData = frameData['widgets']! as Map<String, Object?>;
    expect(widgetData.keys, contains(contains('FocusScope')));     // The exact IDs depend on widget instances.
  });
}
