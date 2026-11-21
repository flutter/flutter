// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
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

  // Records the calls sent on the platform channel. The platform answers each
  // show call with what `showResult` returns.
  List<MethodCall> recordPlatformCalls(
    WidgetTester tester, {
    Future<bool?> Function() showResult = _shown,
  }) {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
      MethodCall call,
    ) async {
      calls.add(call);
      return call.method == 'Magnifier.showSystemMagnifier' ? showResult() : null;
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

  testWidgets('shows, moves, and hides the system magnifier in view coordinates', (
    WidgetTester tester,
  ) async {
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
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('follows a new magnifier info listenable', (WidgetTester tester) async {
    final List<MethodCall> calls = recordPlatformCalls(tester);
    final oldInfo = ValueNotifier<MagnifierInfo>(firstInfo);
    addTearDown(oldInfo.dispose);
    final newInfo = ValueNotifier<MagnifierInfo>(secondInfo);
    addTearDown(newInfo.dispose);

    await tester.pumpWidget(buildMagnifier(const SizedBox.shrink()));
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
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('keeps following the magnifier info when the loupe is not shown', (
    WidgetTester tester,
  ) async {
    final List<MethodCall> calls = recordPlatformCalls(
      tester,
      showResult: () => Future<bool?>.value(false),
    );
    final magnifierInfo = ValueNotifier<MagnifierInfo>(firstInfo);
    addTearDown(magnifierInfo.dispose);

    await tester.pumpWidget(buildMagnifier(const SizedBox.shrink()));
    await tester.pumpWidget(buildMagnifier(SystemTextMagnifier(magnifierInfo: magnifierInfo)));
    magnifierInfo.value = secondInfo;
    await tester.pump();
    await tester.pumpWidget(buildMagnifier(const SizedBox.shrink()));

    expect(calls.map((MethodCall call) => call.method), <String>[
      'Magnifier.showSystemMagnifier',
      'Magnifier.showSystemMagnifier',
      'Magnifier.hideSystemMagnifier',
    ]);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('stops sending calls when the platform has no system loupe', (
    WidgetTester tester,
  ) async {
    final List<MethodCall> calls = recordPlatformCalls(
      tester,
      showResult: () => Future<bool?>.value(),
    );
    final magnifierInfo = ValueNotifier<MagnifierInfo>(firstInfo);
    addTearDown(magnifierInfo.dispose);
    final otherInfo = ValueNotifier<MagnifierInfo>(firstInfo);
    addTearDown(otherInfo.dispose);

    await tester.pumpWidget(buildMagnifier(const SizedBox.shrink()));
    await tester.pumpWidget(buildMagnifier(SystemTextMagnifier(magnifierInfo: magnifierInfo)));
    expect(calls, hasLength(1));

    magnifierInfo.value = secondInfo;
    await tester.pump();
    await tester.pumpWidget(buildMagnifier(SystemTextMagnifier(magnifierInfo: otherInfo)));
    otherInfo.value = secondInfo;
    await tester.pump();
    await tester.pumpWidget(buildMagnifier(const SizedBox.shrink()));

    expect(calls, hasLength(1));
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('stops following a new magnifier info when the platform answers late', (
    WidgetTester tester,
  ) async {
    final result = Completer<bool?>();
    final List<MethodCall> calls = recordPlatformCalls(tester, showResult: () => result.future);
    final oldInfo = ValueNotifier<MagnifierInfo>(firstInfo);
    addTearDown(oldInfo.dispose);
    final newInfo = ValueNotifier<MagnifierInfo>(firstInfo);
    addTearDown(newInfo.dispose);

    await tester.pumpWidget(buildMagnifier(const SizedBox.shrink()));
    await tester.pumpWidget(buildMagnifier(SystemTextMagnifier(magnifierInfo: oldInfo)));
    // The widget follows the new magnifier info before the first result
    // arrives.
    await tester.pumpWidget(buildMagnifier(SystemTextMagnifier(magnifierInfo: newInfo)));
    expect(calls, hasLength(2));

    result.complete();
    await tester.pump();

    newInfo.value = secondInfo;
    await tester.pump();
    await tester.pumpWidget(buildMagnifier(const SizedBox.shrink()));

    expect(calls, hasLength(2));
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('hides the loupe when removed before the platform answers', (
    WidgetTester tester,
  ) async {
    final result = Completer<bool?>();
    final List<MethodCall> calls = recordPlatformCalls(tester, showResult: () => result.future);
    final magnifierInfo = ValueNotifier<MagnifierInfo>(firstInfo);
    addTearDown(magnifierInfo.dispose);

    await tester.pumpWidget(buildMagnifier(const SizedBox.shrink()));
    await tester.pumpWidget(buildMagnifier(SystemTextMagnifier(magnifierInfo: magnifierInfo)));
    await tester.pumpWidget(buildMagnifier(const SizedBox.shrink()));

    result.complete();
    await tester.pump();

    expect(calls.map((MethodCall call) => call.method), <String>[
      'Magnifier.showSystemMagnifier',
      'Magnifier.hideSystemMagnifier',
    ]);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('does not show the loupe when the overlay has a singular transform', (
    WidgetTester tester,
  ) async {
    final List<MethodCall> calls = recordPlatformCalls(tester);
    final magnifierInfo = ValueNotifier<MagnifierInfo>(firstInfo);
    addTearDown(magnifierInfo.dispose);

    // A FittedBox with no size does not paint its child, so the overlay's
    // paint transform is the zero matrix.
    Widget buildInEmptyFittedBox(Widget child) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox.shrink(
            child: FittedBox(
              child: SizedBox(width: 200, height: 100, child: Overlay.wrap(child: child)),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildInEmptyFittedBox(const SizedBox.shrink()));
    await tester.pumpWidget(
      buildInEmptyFittedBox(SystemTextMagnifier(magnifierInfo: magnifierInfo)),
    );
    magnifierInfo.value = secondInfo;
    await tester.pump();

    // A zero scale gives a singular transform that is not the zero matrix.
    Widget buildScaledToZero(Widget child) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Transform.scale(scale: 0, child: Overlay.wrap(child: child)),
      );
    }

    await tester.pumpWidget(buildScaledToZero(const SizedBox.shrink()));
    await tester.pumpWidget(buildScaledToZero(SystemTextMagnifier(magnifierInfo: magnifierInfo)));
    magnifierInfo.value = firstInfo;
    await tester.pump();

    expect(
      calls.where((MethodCall call) => call.method == 'Magnifier.showSystemMagnifier'),
      isEmpty,
    );
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('is not supported and asserts on other platforms', (WidgetTester tester) async {
    recordPlatformCalls(tester);
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
    expect(tester.takeException(), isAssertionError);
  }, variant: TargetPlatformVariant.all(excluding: <TargetPlatform>{TargetPlatform.iOS}));

  test('debugFillProperties', () {
    final magnifierInfo = ValueNotifier<MagnifierInfo>(firstInfo);
    addTearDown(magnifierInfo.dispose);
    final builder = DiagnosticPropertiesBuilder();

    SystemTextMagnifier(magnifierInfo: magnifierInfo).debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();
    expect(description, <Matcher>[startsWith('magnifierInfo: ValueNotifier<MagnifierInfo>#')]);
  });

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

Future<bool?> _shown() => Future<bool?>.value(true);
