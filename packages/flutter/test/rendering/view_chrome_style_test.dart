// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SystemChrome - style', () {
    const double statusBarHeight = 25.0;
    const double navigationBarHeight = 54.0;
    const double deviceHeight = 960.0;
    const double deviceWidth = 480.0;
    const double devicePixelRatio = 2.0;

    void setupTestDevice() {
      final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized() as TestWidgetsFlutterBinding;
      const FakeWindowPadding padding = FakeWindowPadding(
        top: statusBarHeight * devicePixelRatio,
        bottom: navigationBarHeight * devicePixelRatio,
      );

      binding.window
        ..viewPaddingTestValue = padding
        ..paddingTestValue = padding
        ..devicePixelRatioTestValue = devicePixelRatio
        ..physicalSizeTestValue = const Size(
          deviceWidth * devicePixelRatio,
          deviceHeight * devicePixelRatio,
        );
    }

    tearDown(() async {
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle());
      await pumpEventQueue();
    });

    group('status bar', () {
      testWidgets(
        "statusBarColor isn't set for unannotated view",
        (WidgetTester tester) async {
          await tester.pumpWidget(const SizedBox.expand());
          await tester.pumpAndSettle();

          expect(SystemChrome.latestStyle?.statusBarColor, isNull);
        },
      );

      testWidgets(
        'statusBarColor is set for annotated view',
        (WidgetTester tester) async {
          setupTestDevice();
          await tester.pumpWidget(const AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.blue,
            ),
            child: SizedBox.expand(),
          ));
          await tester.pumpAndSettle();

          expect(
            SystemChrome.latestStyle?.statusBarColor,
            Colors.blue,
          );
        },
        variant: TargetPlatformVariant.mobile(),
      );

      testWidgets(
        "statusBarColor isn't set when view covers less than half of the system status bar",
        (WidgetTester tester) async {
          setupTestDevice();
          const double lessThanHalfOfTheStatusBarHeight =
              statusBarHeight / 2.0 - 1;
          await tester.pumpWidget(const Align(
            alignment: Alignment.topCenter,
            child: AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: Colors.blue,
              ),
              child: SizedBox(
                width: 100,
                height: lessThanHalfOfTheStatusBarHeight,
              ),
            ),
          ));
          await tester.pumpAndSettle();

          expect(SystemChrome.latestStyle?.statusBarColor, isNull);
        },
        variant: TargetPlatformVariant.mobile(),
      );

      testWidgets(
        'statusBarColor is set when view covers more than half of tye system status bar',
        (WidgetTester tester) async {
          setupTestDevice();
          const double moreThanHalfOfTheStatusBarHeight =
              statusBarHeight / 2.0 + 1;
          await tester.pumpWidget(const Align(
            alignment: Alignment.topCenter,
            child: AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: Colors.blue,
              ),
              child: SizedBox(
                width: 100,
                height: moreThanHalfOfTheStatusBarHeight,
              ),
            ),
          ));
          await tester.pumpAndSettle();

          expect(
            SystemChrome.latestStyle?.statusBarColor,
            Colors.blue,
          );
        },
        variant: TargetPlatformVariant.mobile(),
      );
    });

    group('navigation color (Android only)', () {
      testWidgets(
        "systemNavigationBarColor isn't set for non Android device",
        (WidgetTester tester) async {
          setupTestDevice();
          await tester.pumpWidget(const AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              systemNavigationBarColor: Colors.blue,
            ),
            child: SizedBox.expand(),
          ));
          await tester.pumpAndSettle();

          expect(
            SystemChrome.latestStyle?.systemNavigationBarColor,
            isNull,
          );
        },
        variant: TargetPlatformVariant.only(TargetPlatform.iOS),
      );

      testWidgets(
        "systemNavigationBarColor isn't set for unannotated view",
        (WidgetTester tester) async {
          await tester.pumpWidget(const SizedBox.expand());
          await tester.pumpAndSettle();

          expect(SystemChrome.latestStyle?.systemNavigationBarColor, isNull);
        },
        variant: TargetPlatformVariant.only(TargetPlatform.android),
      );

      testWidgets(
        'systemNavigationBarColor is set for annotated view',
        (WidgetTester tester) async {
          setupTestDevice();
          await tester.pumpWidget(const AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              systemNavigationBarColor: Colors.blue,
            ),
            child: SizedBox.expand(),
          ));
          await tester.pumpAndSettle();

          expect(
            SystemChrome.latestStyle?.systemNavigationBarColor,
            Colors.blue,
          );
        },
        variant: TargetPlatformVariant.only(TargetPlatform.android),
      );

      testWidgets(
        "systemNavigationBarColor isn't set when view covers less than half of navigation bar",
        (WidgetTester tester) async {
          setupTestDevice();
          const double lessThanHalfOfTheNavigationBarHeight =
              navigationBarHeight / 2.0 - 1;
          await tester.pumpWidget(const Align(
            alignment: Alignment.bottomCenter,
            child: AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                systemNavigationBarColor: Colors.blue,
              ),
              child: SizedBox(
                width: 100,
                height: lessThanHalfOfTheNavigationBarHeight,
              ),
            ),
          ));
          await tester.pumpAndSettle();

          expect(SystemChrome.latestStyle?.systemNavigationBarColor, isNull);
        },
        variant: TargetPlatformVariant.only(TargetPlatform.android),
      );

      testWidgets(
        'systemNavigationBarColor is set when view covers more than half of navigation bar',
        (WidgetTester tester) async {
          setupTestDevice();
          const double moreThanHalfOfTheNavigationBarHeight =
              navigationBarHeight / 2.0 + 1;
          await tester.pumpWidget(const Align(
            alignment: Alignment.bottomCenter,
            child: AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                systemNavigationBarColor: Colors.blue,
              ),
              child: SizedBox(
                width: 100,
                height: moreThanHalfOfTheNavigationBarHeight,
              ),
            ),
          ));
          await tester.pumpAndSettle();

          expect(
            SystemChrome.latestStyle?.systemNavigationBarColor,
            Colors.blue,
          );
        },
        variant: TargetPlatformVariant.only(TargetPlatform.android),
      );
    });
  });
}

class FakeWindowPadding implements WindowPadding {
  const FakeWindowPadding({
    this.left = 0.0,
    this.top = 0.0,
    this.right = 0.0,
    this.bottom = 0.0,
  });

  @override
  final double left;
  @override
  final double top;
  @override
  final double right;
  @override
  final double bottom;
}
