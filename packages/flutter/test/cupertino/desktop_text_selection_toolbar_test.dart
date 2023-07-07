// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('positions itself at the anchor', (WidgetTester tester) async {
    // An arbitrary point on the screen to position at.
    const Offset anchor = Offset(30.0, 40.0);

    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoDesktopTextSelectionToolbar(
            anchor: anchor,
            children: <Widget>[
              CupertinoDesktopTextSelectionToolbarButton(
                child: const Text('Tap me'),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(
      tester.getTopLeft(find.byType(CupertinoDesktopTextSelectionToolbarButton)),
      // Greater than due to padding internal to the toolbar.
      greaterThan(anchor),
    );
  });
}
