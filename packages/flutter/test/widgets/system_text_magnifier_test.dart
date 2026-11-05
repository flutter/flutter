// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const firstInfo = MagnifierInfo(
    globalGesturePosition: Offset(10, 20),
    caretRect: Rect.fromLTWH(8, 12, 2, 18),
    fieldBounds: Rect.fromLTWH(0, 0, 200, 40),
    currentLineBoundaries: Rect.fromLTWH(0, 12, 200, 18),
  );
  const secondInfo = MagnifierInfo(
    globalGesturePosition: Offset(30, 20),
    caretRect: Rect.fromLTWH(28, 12, 2, 18),
    fieldBounds: Rect.fromLTWH(0, 0, 200, 40),
    currentLineBoundaries: Rect.fromLTWH(0, 12, 200, 18),
  );

  // The root overlay starts at (100, 50) in the view, so the platform gets
  // positions shifted by that much.
  Widget buildMagnifier(Widget child) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Padding(
        padding: const EdgeInsets.only(left: 100, top: 50),
        child: Overlay.wrap(child: child),
      ),
    );
  }

  List<MethodCall> recordPlatformCalls(WidgetTester tester) {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
      MethodCall call,
    ) async {
      calls.add(call);
      return call.method == 'Magnifier.showSystemMagnifier' ? true : null;
    });
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null);
    });
    return calls;
  }

  Map<String, Object> showArguments(Offset position, Rect caretRect) {
    return <String, Object>{
      'position': <String, double>{'x': position.dx, 'y': position.dy},
      'caretRect': <String, double>{
        'x': caretRect.left,
        'y': caretRect.top,
        'width': caretRect.width,
        'height': caretRect.height,
      },
    };
  }

  testWidgets(
    'shows, moves, and hides the system magnifier in view coordinates',
    (WidgetTester tester) async {
      final List<MethodCall> calls = recordPlatformCalls(tester);
      final magnifierInfo = ValueNotifier<MagnifierInfo>(firstInfo);
      addTearDown(magnifierInfo.dispose);

      // Magnifiers are inserted into an overlay that is already laid out.
      await tester.pumpWidget(buildMagnifier(const SizedBox.shrink()));
      await tester.pumpWidget(buildMagnifier(SystemTextMagnifier(magnifierInfo: magnifierInfo)));

      expect(calls, hasLength(1));
      expect(calls.last.method, 'Magnifier.showSystemMagnifier');
      expect(
        calls.last.arguments,
        showArguments(const Offset(110, 70), const Rect.fromLTWH(108, 62, 2, 18)),
      );

      magnifierInfo.value = secondInfo;
      await tester.pump();

      expect(calls, hasLength(2));
      expect(calls.last.method, 'Magnifier.showSystemMagnifier');
      expect(
        calls.last.arguments,
        showArguments(const Offset(130, 70), const Rect.fromLTWH(128, 62, 2, 18)),
      );

      await tester.pumpWidget(buildMagnifier(const SizedBox.shrink()));

      expect(calls, hasLength(3));
      expect(calls.last.method, 'Magnifier.hideSystemMagnifier');
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'follows a new magnifier info listenable',
    (WidgetTester tester) async {
      final List<MethodCall> calls = recordPlatformCalls(tester);
      final oldInfo = ValueNotifier<MagnifierInfo>(firstInfo);
      addTearDown(oldInfo.dispose);
      final newInfo = ValueNotifier<MagnifierInfo>(secondInfo);
      addTearDown(newInfo.dispose);

      await tester.pumpWidget(buildMagnifier(SystemTextMagnifier(magnifierInfo: oldInfo)));
      await tester.pumpWidget(buildMagnifier(SystemTextMagnifier(magnifierInfo: newInfo)));

      expect(calls, hasLength(2));
      expect(
        calls.last.arguments,
        showArguments(const Offset(130, 70), const Rect.fromLTWH(128, 62, 2, 18)),
      );

      // The old listenable no longer moves the magnifier.
      oldInfo.value = secondInfo;
      await tester.pump();
      expect(calls, hasLength(2));
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'is not supported and sends nothing on other platforms',
    (WidgetTester tester) async {
      final List<MethodCall> calls = recordPlatformCalls(tester);
      final magnifierInfo = ValueNotifier<MagnifierInfo>(firstInfo);
      addTearDown(magnifierInfo.dispose);
      late BuildContext context;

      await tester.pumpWidget(
        buildMagnifier(
          Builder(
            builder: (BuildContext builderContext) {
              context = builderContext;
              return SystemTextMagnifier(magnifierInfo: magnifierInfo);
            },
          ),
        ),
      );
      expect(SystemTextMagnifier.isSupported(context), isFalse);

      magnifierInfo.value = secondInfo;
      await tester.pump();
      await tester.pumpWidget(buildMagnifier(const SizedBox.shrink()));

      expect(calls, isEmpty);
    },
    variant: TargetPlatformVariant.all(excluding: <TargetPlatform>{TargetPlatform.iOS}),
  );

  testWidgets('is supported on iOS', (WidgetTester tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext builderContext) {
          context = builderContext;
          return const SizedBox.shrink();
        },
      ),
    );

    expect(SystemTextMagnifier.isSupported(context), isTrue);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
}
