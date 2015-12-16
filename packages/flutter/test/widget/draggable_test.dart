// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:test/test.dart';

void main() {
  test('Drag and drop - control test', () {
    testWidgets((WidgetTester tester) {
      TestPointer pointer = new TestPointer(7);

      List accepted = [];

      tester.pumpWidget(new MaterialApp(
        routes: <String, RouteBuilder>{
          '/': (RouteArguments args) { return new Column(<Widget>[
              new Draggable(
                data: 1,
                child: new Text('Source'),
                feedback: new Text('Dragging')
              ),
              new DragTarget(
                builder: (context, data, rejects) {
                  return new Container(
                    height: 100.0,
                    child: new Text('Target')
                  );
                },
                onAccept: (data) {
                  accepted.add(data);
                }
              ),
            ]);
          },
        }
      ));

      expect(accepted, isEmpty);
      expect(tester.findText('Source'), isNotNull);
      expect(tester.findText('Dragging'), isNull);
      expect(tester.findText('Target'), isNotNull);

      Point firstLocation = tester.getCenter(tester.findText('Source'));
      tester.dispatchEvent(pointer.down(firstLocation), firstLocation);
      tester.pump();

      expect(accepted, isEmpty);
      expect(tester.findText('Source'), isNotNull);
      expect(tester.findText('Dragging'), isNotNull);
      expect(tester.findText('Target'), isNotNull);

      Point secondLocation = tester.getCenter(tester.findText('Target'));
      tester.dispatchEvent(pointer.move(secondLocation), firstLocation);
      tester.pump();

      expect(accepted, isEmpty);
      expect(tester.findText('Source'), isNotNull);
      expect(tester.findText('Dragging'), isNotNull);
      expect(tester.findText('Target'), isNotNull);

      tester.dispatchEvent(pointer.up(), firstLocation);
      tester.pump();

      expect(accepted, equals([1]));
      expect(tester.findText('Source'), isNotNull);
      expect(tester.findText('Dragging'), isNull);
      expect(tester.findText('Target'), isNotNull);
    });
  });
}
