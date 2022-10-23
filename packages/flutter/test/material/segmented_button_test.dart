// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widgets/semantics_tester.dart';


Widget boilerplate({required Widget child}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Center(child: child),
  );
}

void main() {

  testWidgets('SegmentedButtons have correct semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      Material(
        child: boilerplate(
          child: SegmentedButton<int>(
            segments: const <ButtonSegment<int>>[
              ButtonSegment<int>(value: 1, label: Text('1')),
              ButtonSegment<int>(value: 2, label: Text('2')),
              ButtonSegment<int>(value: 3, label: Text('3'), enabled: false),
            ],
            selected: const <int>{2},
            onSelectionChanged: (Set<int> selected) {},
          ),
        ),
      ),
    );

    expect(
      semantics,
      hasSemantics(
        TestSemantics.root(
          children: <TestSemantics>[
            // First is just a regular unselected, enabled button.
            TestSemantics(
              flags: <SemanticsFlag>[
                SemanticsFlag.isButton,
                SemanticsFlag.isEnabled,
                SemanticsFlag.hasEnabledState,
                SemanticsFlag.hasCheckedState,
                SemanticsFlag.isFocusable,
                SemanticsFlag.isInMutuallyExclusiveGroup,
              ],
              label: '1',
              actions: <SemanticsAction>[
                SemanticsAction.tap,
              ],
            ),

            // Second is a selected, enabled button.
            TestSemantics(
              flags: <SemanticsFlag>[
                SemanticsFlag.isButton,
                SemanticsFlag.isEnabled,
                SemanticsFlag.hasEnabledState,
                SemanticsFlag.hasCheckedState,
                SemanticsFlag.isChecked,
                SemanticsFlag.isFocusable,
                SemanticsFlag.isInMutuallyExclusiveGroup,
              ],
              label: '2',
              actions: <SemanticsAction>[
                SemanticsAction.tap,
              ],
            ),

            // Third is an unselected, disabled button.
            TestSemantics(
              flags: <SemanticsFlag>[
                SemanticsFlag.isButton,
                SemanticsFlag.hasEnabledState,
                SemanticsFlag.hasCheckedState,
                SemanticsFlag.isInMutuallyExclusiveGroup,
              ],
              label: '3',
            ),
          ],
        ),
        ignoreId: true,
        ignoreRect: true,
        ignoreTransform: true,
      ),
    );

    semantics.dispose();
  });

  testWidgets('Multi-select SegmentedButtons have correct semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      Material(
        child: boilerplate(
          child: SegmentedButton<int>(
            segments: const <ButtonSegment<int>>[
              ButtonSegment<int>(value: 1, label: Text('1')),
              ButtonSegment<int>(value: 2, label: Text('2')),
              ButtonSegment<int>(value: 3, label: Text('3'), enabled: false),
            ],
            selected: const <int>{1, 3},
            onSelectionChanged: (Set<int> selected) {},
            multiSelectEnabled: true,
          ),
        ),
      ),
    );

    expect(
      semantics,
      hasSemantics(
        TestSemantics.root(
          children: <TestSemantics>[
            // First is selected, enabled button.
            TestSemantics(
              flags: <SemanticsFlag>[
                SemanticsFlag.isButton,
                SemanticsFlag.isEnabled,
                SemanticsFlag.hasEnabledState,
                SemanticsFlag.hasCheckedState,
                SemanticsFlag.isChecked,
                SemanticsFlag.isFocusable,
              ],
              label: '1',
              actions: <SemanticsAction>[
                SemanticsAction.tap,
              ],
            ),

            // Second is an unselected, enabled button.
            TestSemantics(
              flags: <SemanticsFlag>[
                SemanticsFlag.isButton,
                SemanticsFlag.isEnabled,
                SemanticsFlag.hasEnabledState,
                SemanticsFlag.hasCheckedState,
                SemanticsFlag.isFocusable,
              ],
              label: '2',
              actions: <SemanticsAction>[
                SemanticsAction.tap,
              ],
            ),

            // Third is a selected, disabled button.
            TestSemantics(
              flags: <SemanticsFlag>[
                SemanticsFlag.isButton,
                SemanticsFlag.hasEnabledState,
                SemanticsFlag.isChecked,
                SemanticsFlag.hasCheckedState,
              ],
              label: '3',
            ),
          ],
        ),
        ignoreId: true,
        ignoreRect: true,
        ignoreTransform: true,
      ),
    );

    semantics.dispose();
  });
}
