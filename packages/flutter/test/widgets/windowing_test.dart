// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Display;
import 'package:flutter/src/foundation/_features.dart' show isWindowingEnabled;
import 'package:flutter/src/widgets/_window.dart'
    show
        BaseWindowController,
        RegularWindow,
        RegularWindowController,
        RegularWindowControllerDelegate,
        WindowScope,
        WindowingOwner;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'multi_view_testing.dart';

class _StubWindowController extends RegularWindowController {
  _StubWindowController(WidgetTester tester) : super.empty() {
    rootView = FakeView(tester.view);
  }

  @override
  Size get contentSize => Size.zero;

  @override
  String get title => 'Stub Window';

  @override
  bool get isActivated => true;

  @override
  bool get isMaximized => false;

  @override
  bool get isMinimized => false;

  @override
  bool get isFullscreen => false;

  @override
  void setSize(Size size) {}

  @override
  void setConstraints(BoxConstraints constraints) {}

  @override
  void setTitle(String title) {}

  @override
  void activate() {}

  @override
  void setMaximized(bool maximized) {}

  @override
  void setMinimized(bool minimized) {}

  @override
  void setFullscreen(bool fullscreen, {Display? display}) {}

  @override
  void destroy() {}
}

void main() {
  group('Windowing', () {
    group('isWindowingEnabled is false', () {
      setUp(() {
        isWindowingEnabled = false;
      });

      test('createDefaultOwner returns a WindowingOwner', () {
        final WindowingOwner owner = WindowingOwner.createDefaultOwner();
        expect(owner, isA<WindowingOwner>());
      });

      test('default WindowingOwner throws when accessing createRegularWindowController', () {
        final WindowingOwner owner = WindowingOwner.createDefaultOwner();
        expect(
          () => owner.createRegularWindowController(delegate: RegularWindowControllerDelegate()),
          throwsUnsupportedError,
        );
      });

      test('default WindowingOwner throws when accessing hasTopLevelWindows', () {
        final WindowingOwner owner = WindowingOwner.createDefaultOwner();
        expect(() => owner.hasTopLevelWindows(), throwsUnsupportedError);
      });

      testWidgets('RegularWindow throws UnsupportedError', (WidgetTester tester) async {
        expect(
          () => RegularWindow(controller: _StubWindowController(tester), child: const Text('Test')),
          throwsUnsupportedError,
        );
      });

      testWidgets('Accessing WindowScope.of throws UnsupportedError', (WidgetTester tester) async {
        await tester.pumpWidget(LookupBoundary(child: Container()));
        final BuildContext context = tester.element(find.byType(Container));

        expect(() => WindowScope.of(context), throwsUnsupportedError);
      });
    });

    group('isWindowingEnabled is true', () {
      setUp(() {
        isWindowingEnabled = true;
      });

      test('createDefaultOwner returns a WindowingOwner', () {
        final WindowingOwner owner = WindowingOwner.createDefaultOwner();
        expect(owner, isA<WindowingOwner>());
      });

      testWidgets('RegularWindow does not throw', (WidgetTester tester) async {
        await tester.pumpWidget(
          wrapWithView: false,
          RegularWindow(controller: _StubWindowController(tester), child: Container()),
        );
      });

      testWidgets('Can access WindowScope.of', (WidgetTester tester) async {
        await tester.pumpWidget(
          wrapWithView: false,
          RegularWindow(
            controller: _StubWindowController(tester),
            child: Builder(
              builder: (BuildContext context) {
                final BaseWindowController scope = WindowScope.of(context);
                expect(scope, isA<RegularWindowController>());
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      });

      testWidgets('Can access WindowScope.maybeOf', (WidgetTester tester) async {
        await tester.pumpWidget(
          wrapWithView: false,
          RegularWindow(
            controller: _StubWindowController(tester),
            child: Builder(
              builder: (BuildContext context) {
                final BaseWindowController? scope = WindowScope.maybeOf(context);
                expect(scope, isA<RegularWindowController>());
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      });

      testWidgets('Can access WindowScope.contentSizeOf', (WidgetTester tester) async {
        await tester.pumpWidget(
          wrapWithView: false,
          RegularWindow(
            controller: _StubWindowController(tester),
            child: Builder(
              builder: (BuildContext context) {
                final Size size = WindowScope.contentSizeOf(context);
                expect(size, equals(Size.zero));
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      });

      testWidgets('Can access WindowScope.maybeContentSizeOf', (WidgetTester tester) async {
        await tester.pumpWidget(
          wrapWithView: false,
          RegularWindow(
            controller: _StubWindowController(tester),
            child: Builder(
              builder: (BuildContext context) {
                final Size? size = WindowScope.maybeContentSizeOf(context);
                expect(size, equals(Size.zero));
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      });

      testWidgets('Can access WindowScope.titleOf', (WidgetTester tester) async {
        await tester.pumpWidget(
          wrapWithView: false,
          RegularWindow(
            controller: _StubWindowController(tester),
            child: Builder(
              builder: (BuildContext context) {
                final String title = WindowScope.titleOf(context);
                expect(title, equals('Stub Window'));
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      });

      testWidgets('Can access WindowScope.maybeTitleOf', (WidgetTester tester) async {
        await tester.pumpWidget(
          wrapWithView: false,
          RegularWindow(
            controller: _StubWindowController(tester),
            child: Builder(
              builder: (BuildContext context) {
                final String? title = WindowScope.maybeTitleOf(context);
                expect(title, equals('Stub Window'));
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      });

      testWidgets('Can access WindowScope.isActivatedOf', (WidgetTester tester) async {
        await tester.pumpWidget(
          wrapWithView: false,
          RegularWindow(
            controller: _StubWindowController(tester),
            child: Builder(
              builder: (BuildContext context) {
                final bool isActivated = WindowScope.isActivatedOf(context);
                expect(isActivated, equals(true));
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      });

      testWidgets('Can access WindowScope.maybeIsActivatedOf', (WidgetTester tester) async {
        await tester.pumpWidget(
          wrapWithView: false,
          RegularWindow(
            controller: _StubWindowController(tester),
            child: Builder(
              builder: (BuildContext context) {
                final bool? isActivated = WindowScope.maybeIsActivatedOf(context);
                expect(isActivated, equals(true));
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      });

      testWidgets('Can access WindowScope.isMinimizedOf', (WidgetTester tester) async {
        await tester.pumpWidget(
          wrapWithView: false,
          RegularWindow(
            controller: _StubWindowController(tester),
            child: Builder(
              builder: (BuildContext context) {
                final bool isMinimized = WindowScope.isMinimizedOf(context);
                expect(isMinimized, equals(false));
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      });

      testWidgets('Can access WindowScope.maybeIsMinimizedOf', (WidgetTester tester) async {
        await tester.pumpWidget(
          wrapWithView: false,
          RegularWindow(
            controller: _StubWindowController(tester),
            child: Builder(
              builder: (BuildContext context) {
                final bool? isMinimized = WindowScope.maybeIsMinimizedOf(context);
                expect(isMinimized, equals(false));
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      });

      testWidgets('Can access WindowScope.isMaximizedOf', (WidgetTester tester) async {
        await tester.pumpWidget(
          wrapWithView: false,
          RegularWindow(
            controller: _StubWindowController(tester),
            child: Builder(
              builder: (BuildContext context) {
                final bool isMaximized = WindowScope.isMaximizedOf(context);
                expect(isMaximized, equals(false));
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      });

      testWidgets('Can access WindowScope.maybeIsMaximizedOf', (WidgetTester tester) async {
        await tester.pumpWidget(
          wrapWithView: false,
          RegularWindow(
            controller: _StubWindowController(tester),
            child: Builder(
              builder: (BuildContext context) {
                final bool? isMaximized = WindowScope.maybeIsMaximizedOf(context);
                expect(isMaximized, equals(false));
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      });

      testWidgets('Can access WindowScope.isFullscreenOf', (WidgetTester tester) async {
        await tester.pumpWidget(
          wrapWithView: false,
          RegularWindow(
            controller: _StubWindowController(tester),
            child: Builder(
              builder: (BuildContext context) {
                final bool isFullscreen = WindowScope.isFullscreenOf(context);
                expect(isFullscreen, equals(false));
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      });

      testWidgets('Can access WindowScope.maybeIsFullscreenOf', (WidgetTester tester) async {
        await tester.pumpWidget(
          wrapWithView: false,
          RegularWindow(
            controller: _StubWindowController(tester),
            child: Builder(
              builder: (BuildContext context) {
                final bool? isFullscreen = WindowScope.maybeIsFullscreenOf(context);
                expect(isFullscreen, equals(false));
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      });
    });
  });
}
