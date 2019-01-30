// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ExpandIcon test', (WidgetTester tester) async {
    bool expanded = false;

    await tester.pumpWidget(
      wrap(
          child: ExpandIcon(
            onPressed: (bool isExpanded) {
              expanded = !expanded;
            }
          )
      )
    );

    expect(expanded, isFalse);
    await tester.tap(find.byType(ExpandIcon));
    expect(expanded, isTrue);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byType(ExpandIcon));
    expect(expanded, isFalse);
  });

  testWidgets('ExpandIcon disabled', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
          child: const ExpandIcon(
            onPressed: null
          )
      )
    );

    final IconTheme iconTheme = tester.firstWidget(find.byType(IconTheme).last);
    expect(iconTheme.data.color, equals(Colors.black38));
  });

  testWidgets('ExpandIcon test isExpanded does not trigger callback', (WidgetTester tester) async {
    bool expanded = false;

    await tester.pumpWidget(
      wrap(
          child: ExpandIcon(
            isExpanded: false,
            onPressed: (bool isExpanded) {
              expanded = !expanded;
            }
          )
      )
    );

    await tester.pumpWidget(
      wrap(
          child: ExpandIcon(
            isExpanded: true,
            onPressed: (bool isExpanded) {
              expanded = !expanded;
            }
        )
      )
    );

    expect(expanded, isFalse);
  });

  testWidgets('ExpandIcon is rotated initially if isExpanded is true on first build', (WidgetTester tester) async {
    bool expanded = true;

    await tester.pumpWidget(
        wrap(
            child: ExpandIcon(
              isExpanded: expanded,
              onPressed: (bool isExpanded) {
                expanded = !isExpanded;
              },
            )
        )
    );
    final RotationTransition rotation = tester.firstWidget(find.byType(RotationTransition));
    expect(rotation.turns.value, 0.5);
  });

  testWidgets('ExpandIcon has correct semantic hints', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    const DefaultMaterialLocalizations localizations = DefaultMaterialLocalizations();
    await tester.pumpWidget(wrap(
        child: ExpandIcon(
          isExpanded: true,
          onPressed: (bool _) {},
        )
    ));

    expect(tester.getSemantics(find.byType(ExpandIcon)), matchesSemantics(
      hasTapAction: true,
      hasEnabledState: true,
      isEnabled: true,
      isButton: true,
      onTapHint: localizations.expandedIconTapHint,
    ));

    await tester.pumpWidget(wrap(
      child: ExpandIcon(
        isExpanded: false,
        onPressed: (bool _) {},
      )
    ));

    expect(tester.getSemantics(find.byType(ExpandIcon)), matchesSemantics(
      hasTapAction: true,
      hasEnabledState: true,
      isEnabled: true,
      isButton: true,
      onTapHint: localizations.collapsedIconTapHint,
    ));
    handle.dispose();
  });
}

Widget wrap({ Widget child }) {
  return MaterialApp(
    home: Center(
      child: Material(child: child),
    ),
  );
}
