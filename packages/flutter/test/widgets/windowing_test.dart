// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Display;
import 'package:flutter/src/foundation/_features.dart' show isWindowingEnabled;
import 'package:flutter/src/widgets/_window.dart'
    show
        BaseWindowController,
        DialogWindow,
        DialogWindowController,
        DialogWindowControllerDelegate,
        RegularWindow,
        RegularWindowController,
        RegularWindowControllerDelegate,
        WindowScope,
        WindowingOwner,
        createDefaultWindowingOwner;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'multi_view_testing.dart';

class _StubRegularWindowController extends RegularWindowController {
  _StubRegularWindowController(WidgetTester tester) : super.empty() {
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

class _StubDialogWindowController extends DialogWindowController {
  _StubDialogWindowController(WidgetTester tester) : super.empty() {
    rootView = FakeView(tester.view);
  }

  @override
  BaseWindowController? get parent => null;

  @override
  Size get contentSize => Size.zero;

  @override
  String get title => 'Stub Window';

  @override
  bool get isActivated => true;

  @override
  bool get isMinimized => false;

  @override
  void setSize(Size size) {}

  @override
  void setConstraints(BoxConstraints constraints) {}

  @override
  void setTitle(String title) {}

  @override
  void activate() {}

  @override
  void setMinimized(bool minimized) {}

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
        final WindowingOwner owner = createDefaultWindowingOwner();
        expect(owner, isA<WindowingOwner>());
      });

      test('default WindowingOwner throws when accessing createRegularWindowController', () {
        final WindowingOwner owner = createDefaultWindowingOwner();
        expect(
          () => owner.createRegularWindowController(delegate: RegularWindowControllerDelegate()),
          throwsUnsupportedError,
        );
      });

      test('default WindowingOwner throws when accessing createDialogWindowController', () {
        final WindowingOwner owner = createDefaultWindowingOwner();
        expect(
          () => owner.createDialogWindowController(delegate: DialogWindowControllerDelegate()),
          throwsUnsupportedError,
        );
      });

      testWidgets('DialogWindow throws UnsupportedError', (WidgetTester tester) async {
        expect(
          () => DialogWindow(
            controller: _StubDialogWindowController(tester),
            child: const Text('Test'),
          ),
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

      testWidgets('RegularWindow does not throw', (WidgetTester tester) async {
        final _StubRegularWindowController controller = _StubRegularWindowController(tester);
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          RegularWindow(controller: controller, child: Container()),
        );
      });

      testWidgets('Dialog does not throw', (WidgetTester tester) async {
        final _StubDialogWindowController controller = _StubDialogWindowController(tester);
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          DialogWindow(controller: controller, child: Container()),
        );
      });

      testWidgets('Can access WindowScope.of for regular windows', (WidgetTester tester) async {
        final _StubRegularWindowController controller = _StubRegularWindowController(tester);
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          RegularWindow(
            controller: controller,
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

      testWidgets('Can access WindowScope.of for dialog windows', (WidgetTester tester) async {
        final _StubDialogWindowController controller = _StubDialogWindowController(tester);
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          DialogWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                final BaseWindowController scope = WindowScope.of(context);
                expect(scope, isA<DialogWindowController>());
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      });

      testWidgets('Can access WindowScope.maybeOf for regular windows', (
        WidgetTester tester,
      ) async {
        final _StubRegularWindowController controller = _StubRegularWindowController(tester);
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          RegularWindow(
            controller: controller,
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

      testWidgets('Can access WindowScope.maybeOf for dialog windows', (WidgetTester tester) async {
        final _StubDialogWindowController controller = _StubDialogWindowController(tester);
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          DialogWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                final BaseWindowController? scope = WindowScope.maybeOf(context);
                expect(scope, isA<DialogWindowController>());
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      });

      testWidgets('Can access WindowScope.contentSizeOf for regular windows', (
        WidgetTester tester,
      ) async {
        final _StubRegularWindowController controller = _StubRegularWindowController(tester);
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          RegularWindow(
            controller: controller,
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

      testWidgets('Can access WindowScope.contentSizeOf for dialog windows', (
        WidgetTester tester,
      ) async {
        final _StubDialogWindowController controller = _StubDialogWindowController(tester);
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          DialogWindow(
            controller: controller,
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

      testWidgets('Can access WindowScope.maybeContentSizeOf for regular windows', (
        WidgetTester tester,
      ) async {
        final _StubRegularWindowController controller = _StubRegularWindowController(tester);
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          RegularWindow(
            controller: controller,
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

      testWidgets('Can access WindowScope.maybeContentSizeOf for dialog windows', (
        WidgetTester tester,
      ) async {
        final _StubDialogWindowController controller = _StubDialogWindowController(tester);
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          DialogWindow(
            controller: controller,
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

      testWidgets('Can access WindowScope.titleOf for regular windows', (
        WidgetTester tester,
      ) async {
        final _StubRegularWindowController controller = _StubRegularWindowController(tester);
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          RegularWindow(
            controller: controller,
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

      testWidgets('Can access WindowScope.titleOf for dialog windows', (WidgetTester tester) async {
        final _StubDialogWindowController controller = _StubDialogWindowController(tester);
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          DialogWindow(
            controller: controller,
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

      testWidgets('Can access WindowScope.maybeTitleOf for regular windows', (
        WidgetTester tester,
      ) async {
        final _StubRegularWindowController controller = _StubRegularWindowController(tester);
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          RegularWindow(
            controller: controller,
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

      testWidgets('Can access WindowScope.maybeTitleOf for dialog windows', (
        WidgetTester tester,
      ) async {
        final _StubDialogWindowController controller = _StubDialogWindowController(tester);
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          DialogWindow(
            controller: controller,
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

      testWidgets('Can access WindowScope.isActivatedOf for regular windows', (
        WidgetTester tester,
      ) async {
        final _StubRegularWindowController controller = _StubRegularWindowController(tester);
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          RegularWindow(
            controller: controller,
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

      testWidgets('Can access WindowScope.isActivatedOf for dialog windows', (
        WidgetTester tester,
      ) async {
        final _StubDialogWindowController controller = _StubDialogWindowController(tester);
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          DialogWindow(
            controller: controller,
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

      testWidgets('Can access WindowScope.maybeIsActivatedOf for regular windows', (
        WidgetTester tester,
      ) async {
        final _StubRegularWindowController controller = _StubRegularWindowController(tester);
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          RegularWindow(
            controller: controller,
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

      testWidgets('Can access WindowScope.maybeIsActivatedOf for dialog windows', (
        WidgetTester tester,
      ) async {
        final _StubDialogWindowController controller = _StubDialogWindowController(tester);
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          DialogWindow(
            controller: controller,
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

      testWidgets('Can access WindowScope.isMinimizedOf for regular windows', (
        WidgetTester tester,
      ) async {
        final _StubRegularWindowController controller = _StubRegularWindowController(tester);
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          RegularWindow(
            controller: controller,
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

      testWidgets('Can access WindowScope.isMinimizedOf for dialog windows', (
        WidgetTester tester,
      ) async {
        final _StubDialogWindowController controller = _StubDialogWindowController(tester);
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          DialogWindow(
            controller: controller,
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

      testWidgets('Can access WindowScope.maybeIsMinimizedOf for regular windows', (
        WidgetTester tester,
      ) async {
        final _StubRegularWindowController controller = _StubRegularWindowController(tester);
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          RegularWindow(
            controller: controller,
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

      testWidgets('Can access WindowScope.maybeIsMinimizedOf for dialog windows', (
        WidgetTester tester,
      ) async {
        final _StubDialogWindowController controller = _StubDialogWindowController(tester);
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          DialogWindow(
            controller: controller,
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

      testWidgets('Can access WindowScope.isMaximizedOf for regular windows', (
        WidgetTester tester,
      ) async {
        final _StubRegularWindowController controller = _StubRegularWindowController(tester);
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          RegularWindow(
            controller: controller,
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

      testWidgets('Can access WindowScope.isMaximizedOf for dialog windows', (
        WidgetTester tester,
      ) async {
        final _StubDialogWindowController controller = _StubDialogWindowController(tester);
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          DialogWindow(
            controller: controller,
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

      testWidgets('Can access WindowScope.maybeIsMaximizedOf for regular windows', (
        WidgetTester tester,
      ) async {
        final _StubRegularWindowController controller = _StubRegularWindowController(tester);
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          RegularWindow(
            controller: controller,
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

      testWidgets('Can access WindowScope.maybeIsMaximizedOf for dialog windows', (
        WidgetTester tester,
      ) async {
        final _StubDialogWindowController controller = _StubDialogWindowController(tester);
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          DialogWindow(
            controller: controller,
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

      testWidgets('Can access WindowScope.isFullscreenOf for regular windows', (
        WidgetTester tester,
      ) async {
        final _StubRegularWindowController controller = _StubRegularWindowController(tester);
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          RegularWindow(
            controller: controller,
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

      testWidgets('Can access WindowScope.isFullscreenOf for dialog windows', (
        WidgetTester tester,
      ) async {
        final _StubDialogWindowController controller = _StubDialogWindowController(tester);
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          DialogWindow(
            controller: controller,
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

      testWidgets('Can access WindowScope.maybeIsFullscreenOf for regular windows', (
        WidgetTester tester,
      ) async {
        final _StubRegularWindowController controller = _StubRegularWindowController(tester);
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          RegularWindow(
            controller: controller,
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

      testWidgets('Can access WindowScope.maybeIsFullscreenOf for dialog windows', (
        WidgetTester tester,
      ) async {
        final _StubDialogWindowController controller = _StubDialogWindowController(tester);
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          DialogWindow(
            controller: controller,
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
