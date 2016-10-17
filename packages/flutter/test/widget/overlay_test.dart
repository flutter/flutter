// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('OverflowEntries context contains Overlay',
      (WidgetTester tester) async {
    Key overlayKey = new UniqueKey();
    bool didBuild = false;
    await tester.pumpWidget(new Overlay(
      key: overlayKey,
      initialEntries: <OverlayEntry>[
        new OverlayEntry(
          builder: (BuildContext context) {
            didBuild = true;
            Overlay overlay = context.ancestorWidgetOfExactType(Overlay);
            expect(overlay, isNotNull);
            expect(overlay.key, equals(overlayKey));
            return new Container();
          },
        )
      ],
    ));
    expect(didBuild, isTrue);
  });
}
