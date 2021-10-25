// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_ui/widgets/common/tooltip.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('When the cursor hovers over the tooltip, it displays the message.', (WidgetTester tester) async {
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return MaterialApp(
            home: Material(
              child: Column(
                children: const <Widget>[
                  InfoTooltip(tooltipName: 'tooltipTest', tooltipMessage: 'tooltipTestMessage'),
                ],
              ),
            ),
          );
        },
      ),
    );

    expect(find.byType(InfoTooltip), findsOneWidget);

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer(location: Offset.zero);

    /// Tests if the tooltip is displaying the message upon cursor hovering.
    ///
    /// Before hovering, the message is not found.
    /// When the cursor hovers over the icon, the message is displayed and found.
    expect(find.textContaining('tooltipTestMessage'), findsNothing);
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.byKey(const Key('tooltipTestTooltip'))));
    await tester.pumpAndSettle();
    expect(find.textContaining('tooltipTestMessage'), findsOneWidget);
  });
}
