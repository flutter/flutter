// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import 'semantics_tester.dart';

void main() {
  testWidgets('OverflowEntries context contains Overlay',
      (WidgetTester tester) async {
    final Key overlayKey = new UniqueKey();
    bool didBuild = false;
    await tester.pumpWidget(new Overlay(
      key: overlayKey,
      initialEntries: <OverlayEntry>[
        new OverlayEntry(
          builder: (BuildContext context) {
            didBuild = true;
            final Overlay overlay = context.ancestorWidgetOfExactType(Overlay);
            expect(overlay, isNotNull);
            expect(overlay.key, equals(overlayKey));
            return new Container();
          },
        )
      ],
    ));
    expect(didBuild, isTrue);
  });

  testWidgets('semanticsBarrier should hide underlying semantic tree',
        (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    final TestSemantics expectedSemantics = new TestSemantics.root(
      label: 'included in tree',
    );

    final Key overlayKey = new UniqueKey();
    await tester.pumpWidget(new Overlay(
      key: overlayKey,
      initialEntries: <OverlayEntry>[
        new OverlayEntry(
          builder: (BuildContext context) {
            return new Container(
              child: new Semantics(
                label: 'not included in tree',
                child: new Container()
              )
            );
          },
        ),
        new OverlayEntry(
          builder: (BuildContext context) {
            return new Container(
              child: new Semantics(
                  label: 'included in tree',
                  child: new Container()
              )
            );
          },
          semanticsBarrier: true,
        )
      ],
    ));

    expect(semantics, hasSemantics(expectedSemantics));

    semantics.dispose();
  });
}
