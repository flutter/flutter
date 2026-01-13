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
        PopupWindow,
        PopupWindowController,
        RegularWindow,
        RegularWindowController,
        RegularWindowControllerDelegate,
        TooltipWindow,
        TooltipWindowController,
        WindowScope,
        WindowingOwner,
        createDefaultWindowingOwner;
import 'package:flutter/src/widgets/_window_positioner.dart';
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

class _StubTooltipWindowController extends TooltipWindowController {
  _StubTooltipWindowController({required this.tester}) : super.empty() {
    rootView = FakeView(tester.view);
  }

  final WidgetTester tester;

  @override
  BaseWindowController get parent => _StubRegularWindowController(tester);

  @override
  Size get contentSize => Size.zero;

  @override
  void setConstraints(BoxConstraints constraints) {}

  @override
  void updatePosition({Rect? anchorRect, WindowPositioner? positioner}) {}

  @override
  void destroy() {}
}

class _StubPopupWindowController extends PopupWindowController {
  _StubPopupWindowController({required this.tester}) : super.empty() {
    rootView = FakeView(tester.view);
  }

  final WidgetTester tester;

  @override
  BaseWindowController get parent => _StubRegularWindowController(tester);

  @override
  bool get isActivated => true;

  @override
  Size get contentSize => Size.zero;

  @override
  void activate() {}

  @override
  void setConstraints(BoxConstraints constraints) {}

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

      testWidgets('TooltipWindow throws UnsupportedError', (WidgetTester tester) async {
        expect(
          () => TooltipWindow(
            controller: _StubTooltipWindowController(tester: tester),
            child: const Text('Test'),
          ),
          throwsUnsupportedError,
        );
      });

      testWidgets('PopupWindow throws UnsupportedError', (WidgetTester tester) async {
        expect(
          () => PopupWindow(
            controller: _StubPopupWindowController(tester: tester),
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
        final controller = _StubRegularWindowController(tester);
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          RegularWindow(controller: controller, child: Container()),
        );
      });

      testWidgets('Dialog does not throw', (WidgetTester tester) async {
        final controller = _StubDialogWindowController(tester);
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          DialogWindow(controller: controller, child: Container()),
        );
      });

      testWidgets('Can access WindowScope.of for regular windows', (WidgetTester tester) async {
        final controller = _StubRegularWindowController(tester);
        BaseWindowController? scope;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          RegularWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                scope = WindowScope.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(scope, isA<RegularWindowController>());
      });

      testWidgets('Can access WindowScope.of for dialog windows', (WidgetTester tester) async {
        final controller = _StubDialogWindowController(tester);
        BaseWindowController? scope;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          DialogWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                scope = WindowScope.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(scope, isA<DialogWindowController>());
      });

      testWidgets('Can access WindowScope.of for tooltip windows', (WidgetTester tester) async {
        final controller = _StubTooltipWindowController(tester: tester);
        BaseWindowController? scope;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          TooltipWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                scope = WindowScope.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(scope, isA<TooltipWindowController>());
      });

      testWidgets('Can access WindowScope.of for popup windows', (WidgetTester tester) async {
        final controller = _StubPopupWindowController(tester: tester);
        BaseWindowController? scope;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          PopupWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                scope = WindowScope.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(scope, isA<PopupWindowController>());
      });

      testWidgets('Can access WindowScope.maybeOf for regular windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubRegularWindowController(tester);
        BaseWindowController? scope;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          RegularWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                scope = WindowScope.maybeOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(scope, isA<RegularWindowController>());
      });

      testWidgets('Can access WindowScope.maybeOf for dialog windows', (WidgetTester tester) async {
        final controller = _StubDialogWindowController(tester);
        BaseWindowController? scope;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          DialogWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                scope = WindowScope.maybeOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(scope, isA<DialogWindowController>());
      });

      testWidgets('Can access WindowScope.maybeOf for tooltip windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubTooltipWindowController(tester: tester);
        BaseWindowController? scope;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          TooltipWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                scope = WindowScope.maybeOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(scope, isA<TooltipWindowController>());
      });

      testWidgets('Can access WindowScope.maybeOf for popup windows', (WidgetTester tester) async {
        final controller = _StubPopupWindowController(tester: tester);
        BaseWindowController? scope;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          PopupWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                scope = WindowScope.maybeOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(scope, isA<PopupWindowController>());
      });

      testWidgets('Can access WindowScope.contentSizeOf for regular windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubRegularWindowController(tester);
        Size? size;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          RegularWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                size = WindowScope.contentSizeOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(size, equals(Size.zero));
      });

      testWidgets('Can access WindowScope.contentSizeOf for dialog windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubDialogWindowController(tester);
        Size? size;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          DialogWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                size = WindowScope.contentSizeOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(size, equals(Size.zero));
      });

      testWidgets('Can access WindowScope.contentSizeOf for tooltip windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubTooltipWindowController(tester: tester);
        Size? size;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          TooltipWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                size = WindowScope.contentSizeOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(size, equals(Size.zero));
      });

      testWidgets('Can access WindowScope.contentSizeOf for popup windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubPopupWindowController(tester: tester);
        Size? size;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          PopupWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                size = WindowScope.contentSizeOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(size, equals(Size.zero));
      });

      testWidgets('Can access WindowScope.maybeContentSizeOf for regular windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubRegularWindowController(tester);
        Size? size;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          RegularWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                size = WindowScope.maybeContentSizeOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(size, equals(Size.zero));
      });

      testWidgets('Can access WindowScope.maybeContentSizeOf for dialog windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubDialogWindowController(tester);
        Size? size;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          DialogWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                size = WindowScope.maybeContentSizeOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(size, equals(Size.zero));
      });

      testWidgets('Can access WindowScope.maybeContentSizeOf for tooltip windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubTooltipWindowController(tester: tester);
        Size? size;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          TooltipWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                size = WindowScope.maybeContentSizeOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(size, equals(Size.zero));
      });

      testWidgets('Can access WindowScope.maybeContentSizeOf for popup windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubPopupWindowController(tester: tester);
        Size? size;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          PopupWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                size = WindowScope.maybeContentSizeOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(size, equals(Size.zero));
      });

      testWidgets('Can access WindowScope.titleOf for regular windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubRegularWindowController(tester);
        String? title;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          RegularWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                title = WindowScope.titleOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(title, equals('Stub Window'));
      });

      testWidgets('Can access WindowScope.titleOf for dialog windows', (WidgetTester tester) async {
        final controller = _StubDialogWindowController(tester);
        String? title;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          DialogWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                title = WindowScope.titleOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(title, equals('Stub Window'));
      });

      testWidgets('Can access WindowScope.titleOf for tooltip windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubTooltipWindowController(tester: tester);
        String? title;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          TooltipWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                title = WindowScope.titleOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(title, equals(''));
      });

      testWidgets('Can access WindowScope.titleOf for popup windows', (WidgetTester tester) async {
        final controller = _StubPopupWindowController(tester: tester);
        String? title;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          PopupWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                title = WindowScope.titleOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(title, equals(''));
      });

      testWidgets('Can access WindowScope.maybeTitleOf for regular windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubRegularWindowController(tester);
        String? title;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          RegularWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                title = WindowScope.maybeTitleOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(title, equals('Stub Window'));
      });

      testWidgets('Can access WindowScope.maybeTitleOf for dialog windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubDialogWindowController(tester);
        String? title;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          DialogWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                title = WindowScope.maybeTitleOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(title, equals('Stub Window'));
      });

      testWidgets('Can access WindowScope.maybeTitleOf for tooltip windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubTooltipWindowController(tester: tester);
        String? title;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          TooltipWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                title = WindowScope.maybeTitleOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(title, equals(''));
      });

      testWidgets('Can access WindowScope.maybeTitleOf for popup windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubPopupWindowController(tester: tester);
        String? title;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          PopupWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                title = WindowScope.maybeTitleOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(title, equals(''));
      });

      testWidgets('Can access WindowScope.isActivatedOf for regular windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubRegularWindowController(tester);
        bool? isActivated;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          RegularWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                isActivated = WindowScope.isActivatedOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(isActivated, equals(true));
      });

      testWidgets('Can access WindowScope.isActivatedOf for dialog windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubDialogWindowController(tester);
        bool? isActivated;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          DialogWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                isActivated = WindowScope.isActivatedOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(isActivated, equals(true));
      });

      testWidgets('Can access WindowScope.isActivatedOf for tooltip windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubTooltipWindowController(tester: tester);
        bool? isActivated;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          TooltipWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                isActivated = WindowScope.isActivatedOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(isActivated, equals(false));
      });

      testWidgets('Can access WindowScope.isActivatedOf for popup windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubPopupWindowController(tester: tester);
        bool? isActivated;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          PopupWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                isActivated = WindowScope.isActivatedOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(isActivated, equals(true));
      });

      testWidgets('Can access WindowScope.maybeIsActivatedOf for regular windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubRegularWindowController(tester);
        bool? isActivated;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          RegularWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                isActivated = WindowScope.maybeIsActivatedOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(isActivated, equals(true));
      });

      testWidgets('Can access WindowScope.maybeIsActivatedOf for dialog windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubDialogWindowController(tester);
        bool? isActivated;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          DialogWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                isActivated = WindowScope.maybeIsActivatedOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(isActivated, equals(true));
      });

      testWidgets('Can access WindowScope.maybeIsActivatedOf for tooltip windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubTooltipWindowController(tester: tester);
        bool? isActivated;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          TooltipWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                isActivated = WindowScope.maybeIsActivatedOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(isActivated, equals(false));
      });

      testWidgets('Can access WindowScope.maybeIsActivatedOf for popup windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubPopupWindowController(tester: tester);
        bool? isActivated;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          PopupWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                isActivated = WindowScope.maybeIsActivatedOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(isActivated, equals(true));
      });

      testWidgets('Can access WindowScope.isMinimizedOf for regular windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubRegularWindowController(tester);
        bool? isMinimized;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          RegularWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                isMinimized = WindowScope.isMinimizedOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(isMinimized, equals(false));
      });

      testWidgets('Can access WindowScope.isMinimizedOf for dialog windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubDialogWindowController(tester);
        bool? isMinimized;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          DialogWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                isMinimized = WindowScope.isMinimizedOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(isMinimized, equals(false));
      });

      testWidgets('Can access WindowScope.isMinimizedOf for tooltip windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubTooltipWindowController(tester: tester);
        bool? isMinimized;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          TooltipWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                isMinimized = WindowScope.isMinimizedOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(isMinimized, equals(false));
      });

      testWidgets('Can access WindowScope.isMinimizedOf for popup windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubPopupWindowController(tester: tester);
        bool? isMinimized;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          PopupWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                isMinimized = WindowScope.isMinimizedOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(isMinimized, equals(false));
      });

      testWidgets('Can access WindowScope.maybeIsMinimizedOf for regular windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubRegularWindowController(tester);
        bool? isMinimized;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          RegularWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                isMinimized = WindowScope.maybeIsMinimizedOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(isMinimized, equals(false));
      });

      testWidgets('Can access WindowScope.maybeIsMinimizedOf for dialog windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubDialogWindowController(tester);
        bool? isMinimized;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          DialogWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                isMinimized = WindowScope.maybeIsMinimizedOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(isMinimized, equals(false));
      });

      testWidgets('Can access WindowScope.maybeIsMinimizedOf for tooltip windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubTooltipWindowController(tester: tester);
        bool? isMinimized;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          TooltipWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                isMinimized = WindowScope.maybeIsMinimizedOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(isMinimized, equals(false));
      });

      testWidgets('Can access WindowScope.maybeIsMinimizedOf for popup windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubPopupWindowController(tester: tester);
        bool? isMinimized;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          PopupWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                isMinimized = WindowScope.maybeIsMinimizedOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(isMinimized, equals(false));
      });

      testWidgets('Can access WindowScope.isMaximizedOf for regular windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubRegularWindowController(tester);
        bool? isMaximized;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          RegularWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                isMaximized = WindowScope.isMaximizedOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(isMaximized, equals(false));
      });

      testWidgets('Can access WindowScope.isMaximizedOf for dialog windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubDialogWindowController(tester);
        bool? isMaximized;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          DialogWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                isMaximized = WindowScope.isMaximizedOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(isMaximized, equals(false));
      });

      testWidgets('Can access WindowScope.isMaximizedOf for tooltip windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubTooltipWindowController(tester: tester);
        bool? isMaximized;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          TooltipWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                isMaximized = WindowScope.isMaximizedOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(isMaximized, equals(false));
      });

      testWidgets('Can access WindowScope.isMaximizedOf for popup windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubPopupWindowController(tester: tester);
        bool? isMaximized;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          PopupWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                isMaximized = WindowScope.isMaximizedOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(isMaximized, equals(false));
      });

      testWidgets('Can access WindowScope.maybeIsMaximizedOf for regular windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubRegularWindowController(tester);
        bool? isMaximized;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          RegularWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                isMaximized = WindowScope.maybeIsMaximizedOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(isMaximized, equals(false));
      });

      testWidgets('Can access WindowScope.maybeIsMaximizedOf for dialog windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubDialogWindowController(tester);
        bool? isMaximized;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          DialogWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                isMaximized = WindowScope.maybeIsMaximizedOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(isMaximized, equals(false));
      });

      testWidgets('Can access WindowScope.maybeIsMaximizedOf for tooltip windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubTooltipWindowController(tester: tester);
        bool? isMaximized;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          TooltipWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                isMaximized = WindowScope.maybeIsMaximizedOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(isMaximized, equals(false));
      });

      testWidgets('Can access WindowScope.maybeIsMaximizedOf for popup windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubPopupWindowController(tester: tester);
        bool? isMaximized;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          PopupWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                isMaximized = WindowScope.maybeIsMaximizedOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(isMaximized, equals(false));
      });

      testWidgets('Can access WindowScope.isFullscreenOf for regular windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubRegularWindowController(tester);
        bool? isFullscreen;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          RegularWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                isFullscreen = WindowScope.isFullscreenOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(isFullscreen, equals(false));
      });

      testWidgets('Can access WindowScope.isFullscreenOf for dialog windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubDialogWindowController(tester);
        bool? isFullscreen;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          DialogWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                isFullscreen = WindowScope.isFullscreenOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(isFullscreen, equals(false));
      });

      testWidgets('Can access WindowScope.isFullscreenOf for tooltip windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubTooltipWindowController(tester: tester);
        bool? isFullscreen;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          TooltipWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                isFullscreen = WindowScope.isFullscreenOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(isFullscreen, equals(false));
      });

      testWidgets('Can access WindowScope.isFullscreenOf for popup windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubPopupWindowController(tester: tester);
        bool? isFullscreen;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          PopupWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                isFullscreen = WindowScope.isFullscreenOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(isFullscreen, equals(false));
      });

      testWidgets('Can access WindowScope.maybeIsFullscreenOf for regular windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubRegularWindowController(tester);
        bool? isFullscreen;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          RegularWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                isFullscreen = WindowScope.maybeIsFullscreenOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(isFullscreen, equals(false));
      });

      testWidgets('Can access WindowScope.maybeIsFullscreenOf for dialog windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubDialogWindowController(tester);
        bool? isFullscreen;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          DialogWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                isFullscreen = WindowScope.maybeIsFullscreenOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(isFullscreen, equals(false));
      });

      testWidgets('Can access WindowScope.maybeIsFullscreenOf for tooltip windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubTooltipWindowController(tester: tester);
        bool? isFullscreen;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          TooltipWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                isFullscreen = WindowScope.maybeIsFullscreenOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(isFullscreen, equals(false));
      });

      testWidgets('Can access WindowScope.maybeIsFullscreenOf for popup windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubPopupWindowController(tester: tester);
        bool? isFullscreen;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          PopupWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                isFullscreen = WindowScope.maybeIsFullscreenOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(isFullscreen, equals(false));
      });
    });
  });
}
