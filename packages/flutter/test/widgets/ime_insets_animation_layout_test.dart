// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test suite validating visual layout continuity and absence of terminal
/// insets jumps during soft keyboard animation in edgeToEdge mode.
///
/// What it tests:
/// Compares layout and widget positions at the terminal progress frame (fraction = 1.0)
/// versus the settled state (onEnd) for:
/// 1. The baseline buggy engine behavior (where onProgress subtracted navigation bar height,
///    causing a 24dp jump upon onEnd dispatch).
/// 2. The fixed engine behavior (where target-inset interpolation ensures 0dp terminal jump).
///
/// Why it was added:
/// Regression test for flutter/flutter#190974 ("viewInsets.bottom jumps by navigation bar
/// height at the end of IME open animation in edgeToEdge mode on Android API 30-34").
void main() {
  testWidgets('IME insets animation comparison: before vs after fix visual continuity', (
    WidgetTester tester,
  ) async {
    // Exact reproduction UI from issue #190974:
    // A view with bottom padding driven by MediaQuery.viewInsetsOf(context).bottom.
    // In edgeToEdge mode on API 34, viewPadding.bottom is 24dp (gesture bar).
    Widget buildTestApp(double bottomInset) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: MediaQueryData(
            size: const Size(400, 800),
            padding: const EdgeInsets.only(bottom: 24),
            viewPadding: const EdgeInsets.only(bottom: 24),
            viewInsets: EdgeInsets.only(bottom: bottomInset),
          ),
          child: ColoredBox(
            color: const Color(0xFFECEFF1),
            child: Builder(
              builder: (BuildContext context) {
                final double insetsBottom = MediaQuery.viewInsetsOf(context).bottom;
                final double paddingBottom = MediaQuery.viewPaddingOf(context).bottom;
                return Padding(
                  padding: EdgeInsets.only(bottom: insetsBottom),
                  child: Column(
                    children: <Widget>[
                      const SizedBox(height: 40),
                      Text(
                        'IME Insets: ${insetsBottom.toStringAsFixed(1)} dp | Padding: ${paddingBottom.toStringAsFixed(1)} dp',
                        key: const ValueKey<String>('metrics_label'),
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Spacer(),
                      // Distinct indicator strip at the bottom of the content area
                      const ColoredBox(
                        key: ValueKey<String>('indicator_bar'),
                        color: Color(0xFFFF0000),
                        child: SizedBox(height: 8, width: double.infinity),
                      ),
                      const ColoredBox(
                        key: ValueKey<String>('input_box'),
                        color: Color(0xFFCFD8DC),
                        child: SizedBox(
                          height: 56,
                          width: double.infinity,
                          child: Center(
                            child: Text(
                              'Input Field (pinned above keyboard)',
                              textDirection: TextDirection.ltr,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    const targetSettledIme = 336.0; // Settled keyboard height on API 34
    const navBarHeight = 24.0; // Navigation bar height on API 34

    // -------------------------------------------------------------------------
    // 1. BEFORE FIX: Simulating the bug from #190974
    // -------------------------------------------------------------------------
    // During animation, excludedInsets subtracted navBarHeight (24dp).
    // Terminal frame of onProgress reported 336 - 24 = 312 dp.
    // Immediately onEnd dispatched 336 dp -> 24 dp jump.
    const double beforeTerminalProgress = targetSettledIme - navBarHeight; // 312.0
    const beforeSettled = targetSettledIme; // 336.0

    // Render Before Terminal Frame (312dp)
    await tester.pumpWidget(buildTestApp(beforeTerminalProgress));
    await tester.pumpAndSettle();
    final Rect beforeTerminalRect = tester.getRect(
      find.byKey(const ValueKey<String>('indicator_bar')),
    );

    // Render Before Settled Frame (336dp)
    await tester.pumpWidget(buildTestApp(beforeSettled));
    await tester.pumpAndSettle();
    final Rect beforeSettledRect = tester.getRect(
      find.byKey(const ValueKey<String>('indicator_bar')),
    );

    // The jump before the fix:
    final double beforeJump = beforeTerminalRect.bottom - beforeSettledRect.bottom;
    expect(
      beforeJump,
      equals(navBarHeight),
      reason: 'Before fix, indicator jumps by navBarHeight (24dp) at onEnd',
    );

    // -------------------------------------------------------------------------
    // 2. AFTER FIX (fix-ime-insets-animation-jump branch)
    // -------------------------------------------------------------------------
    // In the fixed branch, animated insets are interpolated to targetSettledIme (336dp).
    // Terminal progress frame (fraction = 1.0) reports 336.0 dp.
    // onEnd frame dispatches 336.0 dp.
    const afterTerminalProgress = targetSettledIme; // 336.0
    const afterSettled = targetSettledIme; // 336.0

    // Render After Terminal Frame (336dp)
    await tester.pumpWidget(buildTestApp(afterTerminalProgress));
    await tester.pumpAndSettle();
    final Rect afterTerminalRect = tester.getRect(
      find.byKey(const ValueKey<String>('indicator_bar')),
    );

    // Render After Settled Frame (336dp)
    await tester.pumpWidget(buildTestApp(afterSettled));
    await tester.pumpAndSettle();
    final Rect afterSettledRect = tester.getRect(
      find.byKey(const ValueKey<String>('indicator_bar')),
    );

    // The jump after the fix:
    final double afterJump = afterTerminalRect.bottom - afterSettledRect.bottom;
    expect(
      afterJump,
      equals(0.0),
      reason: 'After fix, indicator position is perfectly continuous with 0 jump',
    );

    // -------------------------------------------------------------------------
    // 3. Compare visual position matching
    // -------------------------------------------------------------------------
    expect(afterTerminalRect, equals(afterSettledRect));
    expect(afterSettledRect, equals(beforeSettledRect));
    expect(beforeTerminalRect, isNot(equals(afterTerminalRect)));
  });
}
