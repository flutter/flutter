// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import '../rendering/mock_canvas.dart';

void main() {
  testWidgets('Container control test', (WidgetTester tester) async {
    final Container container = new Container(
      alignment: FractionalOffset.bottomRight,
      padding: const EdgeInsets.all(7.0),
      decoration: const BoxDecoration(backgroundColor: const Color(0xFF00FF00)),
      foregroundDecoration: const BoxDecoration(backgroundColor: const Color(0x7F0000FF)),
      width: 53.0,
      height: 76.0,
      constraints: const BoxConstraints(
        minWidth: 50.0,
        maxWidth: 55.0,
        minHeight: 78.0,
        maxHeight: 82.0,
      ),
      margin: const EdgeInsets.all(5.0),
      child: const SizedBox(
        width: 25.0,
        height: 33.0,
        child: const DecoratedBox(
          decoration: const BoxDecoration(backgroundColor: const Color(0xFFFFFF00)),
        ),
      ),
    );

    expect(container, hasOneLineDescription);

    await tester.pumpWidget(new Align(
      alignment: FractionalOffset.topLeft,
      child: container
    ));

    final RenderBox box = tester.renderObject(find.byType(Container));
    expect(box, isNotNull);

    expect(box, paints
      ..rect(rect: new Rect.fromLTWH(5.0, 5.0, 53.0, 78.0), color: const Color(0xFF00FF00))
      ..rect(rect: new Rect.fromLTWH(26.0, 43.0, 25.0, 33.0), color: const Color(0xFFFFFF00))
      ..rect(rect: new Rect.fromLTWH(5.0, 5.0, 53.0, 78.0), color: const Color(0x7F0000FF))
    );
  });

  testWidgets('Can be placed in an infinite box', (WidgetTester tester) async {
    await tester.pumpWidget(new ListView(children: <Widget>[new Container()]));
  });
}
