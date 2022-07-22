// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Builds the correct button per-platform', (WidgetTester tester) async {
    const String buttonText = 'Click me';

    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoTextSelectionToolbarButtonsBuilder(
            buttonItems: <ContextMenuButtonItem>[
              ContextMenuButtonItem(
                label: buttonText,
                onPressed: () {
                },
              ),
            ],
            builder: (BuildContext context, List<Widget> children) {
              return ListView(
                children: children,
              );
            },
          ),
        ),
      ),
    );

    expect(find.text(buttonText), findsOneWidget);

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        expect(find.byType(CupertinoTextSelectionToolbarButton), findsOneWidget);
        expect(find.byType(CupertinoDesktopTextSelectionToolbarButton), findsNothing);
        break;
      case TargetPlatform.macOS:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        expect(find.byType(CupertinoTextSelectionToolbarButton), findsNothing);
        expect(find.byType(CupertinoDesktopTextSelectionToolbarButton), findsOneWidget);
        break;
    }
  },
    variant: TargetPlatformVariant.all(),
  );
}
