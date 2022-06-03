// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SelectionArea uses correct selection controls', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: SelectionArea(
        child: Text('abc'),
      ),
    ));
    final SelectableRegion region = tester.widget<SelectableRegion>(find.byType(SelectableRegion));

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        expect(region.selectionControls, materialTextSelectionControls);
        break;
      case TargetPlatform.iOS:
        expect(region.selectionControls, cupertinoTextSelectionControls);
        break;
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        expect(region.selectionControls, desktopTextSelectionControls);
        break;
      case TargetPlatform.macOS:
        expect(region.selectionControls, cupertinoDesktopTextSelectionControls);
        break;
    }
  }, variant: TargetPlatformVariant.all());
}
