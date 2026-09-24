// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Display;

import 'package:flutter/src/foundation/_features.dart' show isWindowingEnabled;
import 'package:flutter/src/widgets/_window.dart'
    show
        BaseWindowController,
        DialogWindowController,
        DialogWindowControllerDelegate,
        PopupWindowController,
        SatelliteWindowController,
        TooltipWindowController,
        WindowController,
        WindowControllerDelegate,
        WindowEntry,
        WindowManager,
        WindowRegistry,
        WindowScope,
        WindowingOwner,
        createDefaultWindowingOwner,
        showWindow;
import 'package:flutter/src/widgets/_window_positioner.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'multi_view_testing.dart';

class _StubWindowController extends WindowController {
  _StubWindowController(WidgetTester tester, {int viewId = 100}) : super.empty() {
    rootView = FakeView(tester.view, viewId: viewId);
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
  bool get isDestroyed => _destroyed;
  bool _destroyed = false;

  @override
  void destroy() {
    _destroyed = true;
  }
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
  bool get isDestroyed => _destroyed;
  bool _destroyed = false;

  @override
  void destroy() {
    _destroyed = true;
  }
}

class _StubTooltipWindowController extends TooltipWindowController {
  _StubTooltipWindowController({required this.tester}) : super.empty() {
    rootView = FakeView(tester.view);
  }

  final WidgetTester tester;

  @override
  BaseWindowController get parent => _StubWindowController(tester);

  @override
  Size get contentSize => Size.zero;

  @override
  void setConstraints(BoxConstraints constraints) {}

  @override
  void updatePosition({Rect? anchorRect, WindowPositioner? positioner}) {}

  @override
  bool get isDestroyed => _destroyed;
  bool _destroyed = false;

  @override
  void destroy() {
    _destroyed = true;
  }
}

class _StubPopupWindowController extends PopupWindowController {
  _StubPopupWindowController({required this.tester}) : super.empty() {
    rootView = FakeView(tester.view);
  }

  final WidgetTester tester;

  @override
  BaseWindowController get parent => _StubWindowController(tester);

  @override
  Size get contentSize => Size.zero;

  @override
  void setConstraints(BoxConstraints constraints) {}

  @override
  bool get isDestroyed => _destroyed;
  bool _destroyed = false;

  @override
  void destroy() {
    _destroyed = true;
  }

  @override
  void updatePosition({Rect? anchorRect, WindowPositioner? positioner}) {}

  @override
  Offset get offsetFromParent => Offset.zero;
}

class _StubSatelliteWindowController extends SatelliteWindowController {
  _StubSatelliteWindowController({required this.tester}) : super.empty() {
    rootView = FakeView(tester.view);
  }

  final WidgetTester tester;

  @override
  BaseWindowController get parent => _StubWindowController(tester);

  @override
  Size get contentSize => Size.zero;

  @override
  String get title => 'Stub Satellite Window';

  @override
  bool get isActivated => true;

  @override
  void setParent(BaseWindowController parent) {}

  @override
  void setSize(Size size) {}

  @override
  void setConstraints(BoxConstraints constraints) {}

  @override
  void setTitle(String title) {}

  @override
  void activate() {}

  @override
  bool get isDestroyed => _destroyed;
  bool _destroyed = false;

  @override
  void destroy() {
    _destroyed = true;
  }
}

// A controller that mutates its aspect values and notifies listeners, used to
// verify that dependents rebuild when the controller notifies even though the
// same controller instance is reused across rebuilds.
class _MutableWindowController extends WindowController {
  _MutableWindowController(WidgetTester tester) : super.empty() {
    rootView = FakeView(tester.view);
  }

  Size _contentSize = Size.zero;
  bool _activated = false;
  bool _maximized = false;
  bool _destroyed = false;

  @override
  Size get contentSize {
    _ensureNotDestroyed();
    return _contentSize;
  }

  @override
  String get title {
    _ensureNotDestroyed();
    return 'Mutable Window';
  }

  @override
  bool get isActivated {
    _ensureNotDestroyed();
    return _activated;
  }

  @override
  bool get isMaximized {
    _ensureNotDestroyed();
    return _maximized;
  }

  @override
  bool get isMinimized {
    _ensureNotDestroyed();
    return false;
  }

  @override
  bool get isFullscreen {
    _ensureNotDestroyed();
    return false;
  }

  @override
  void setSize(Size size) {
    _contentSize = size;
    notifyListeners();
  }

  @override
  void setConstraints(BoxConstraints constraints) {}

  @override
  void setTitle(String title) {}

  @override
  void activate() {
    _activated = true;
    notifyListeners();
  }

  @override
  void setMaximized(bool maximized) {
    _maximized = maximized;
    notifyListeners();
  }

  @override
  void setMinimized(bool minimized) {}

  @override
  void setFullscreen(bool fullscreen, {Display? display}) {}

  @override
  bool get isDestroyed => _destroyed;

  @override
  void destroy() {
    if (_destroyed) {
      return;
    }
    _destroyed = true;
    notifyListeners();
  }

  void _ensureNotDestroyed() {
    if (_destroyed) {
      throw StateError('Window has been destroyed.');
    }
  }
}

/// A [Text] widget that can be rendered without an enclosing [Directionality].
Widget _text(String data) => Text(data, textDirection: TextDirection.ltr);

/// Renders [child] in [controller]'s window using a [WindowManager].
///
/// Pump the result with `wrapWithView: false`, since the manager supplies the
/// window's [View] itself.
Widget _buildWindow({required BaseWindowController controller, required Widget child}) {
  return WindowManager(
    initialWindows: <WindowEntry>[
      WindowEntry(controller: controller, builder: (BuildContext context) => child),
    ],
  );
}

/// Renders [child] below a [WindowScope] for [controller] without a
/// [WindowManager].
///
/// Unlike [_buildWindow], the subtree stays mounted after the window is
/// destroyed, since no manager is present to unregister the entry.
Widget _buildUnmanagedWindow({required BaseWindowController controller, required Widget child}) {
  return ListenableBuilder(
    listenable: controller,
    builder: (BuildContext context, Widget? _) => WindowScope(
      controller: controller,
      child: View(view: controller.rootView, child: child),
    ),
  );
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

      test('default WindowingOwner throws when accessing createWindowController', () {
        final WindowingOwner owner = createDefaultWindowingOwner();
        expect(
          () => owner.createWindowController(delegate: WindowControllerDelegate(), resizable: true),
          throwsUnsupportedError,
        );
      });

      test('default WindowingOwner throws when accessing createDialogWindowController', () {
        final WindowingOwner owner = createDefaultWindowingOwner();
        expect(
          () => owner.createDialogWindowController(
            delegate: DialogWindowControllerDelegate(),
            resizable: true,
          ),
          throwsUnsupportedError,
        );
      });

      testWidgets('WindowEntry throws UnsupportedError', (WidgetTester tester) async {
        expect(
          () => WindowEntry(
            controller: _StubDialogWindowController(tester),
            builder: (BuildContext context) => const Text('Test'),
          ),
          throwsUnsupportedError,
        );
      });

      test('WindowRegistry throws UnsupportedError', () {
        expect(WindowRegistry.new, throwsUnsupportedError);
      });

      testWidgets('WindowManager throws UnsupportedError', (WidgetTester tester) async {
        await tester.pumpWidget(
          wrapWithView: false,
          const WindowManager(initialWindows: <WindowEntry>[]),
        );

        expect(tester.takeException(), isA<UnsupportedError>());
      });

      testWidgets('showWindow throws UnsupportedError', (WidgetTester tester) async {
        // The entry itself can only be created while windowing is enabled.
        isWindowingEnabled = true;
        final entry = WindowEntry(
          controller: _StubWindowController(tester),
          builder: (BuildContext context) => const Text('Test'),
        );
        isWindowingEnabled = false;

        await tester.pumpWidget(Container());
        final BuildContext context = tester.element(find.byType(Container));

        expect(() => showWindow(context: context, entry: entry), throwsUnsupportedError);
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

      testWidgets('WindowManager renders a regular window', (WidgetTester tester) async {
        final controller = _StubWindowController(tester);
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          _buildWindow(controller: controller, child: const Placeholder()),
        );

        expect(find.byType(Placeholder), findsOneWidget);
      });

      testWidgets('WindowManager renders a dialog window', (WidgetTester tester) async {
        final controller = _StubDialogWindowController(tester);
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          _buildWindow(controller: controller, child: const Placeholder()),
        );

        expect(find.byType(Placeholder), findsOneWidget);
      });

      testWidgets('Can access WindowScope.of for regular windows', (WidgetTester tester) async {
        final controller = _StubWindowController(tester);
        BaseWindowController? scope;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          _buildWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                scope = WindowScope.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(scope, isA<WindowController>());
      });

      testWidgets('Can access WindowScope.of for dialog windows', (WidgetTester tester) async {
        final controller = _StubDialogWindowController(tester);
        BaseWindowController? scope;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          _buildWindow(
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
          _buildWindow(
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
          _buildWindow(
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

      testWidgets('Can access WindowScope.of for satellite windows', (WidgetTester tester) async {
        final controller = _StubSatelliteWindowController(tester: tester);
        BaseWindowController? scope;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          _buildWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                scope = WindowScope.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(scope, isA<SatelliteWindowController>());
      });

      testWidgets('Can access WindowScope.maybeOf for regular windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubWindowController(tester);
        BaseWindowController? scope;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          _buildWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                scope = WindowScope.maybeOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(scope, isA<WindowController>());
      });

      testWidgets('Can access WindowScope.maybeOf for dialog windows', (WidgetTester tester) async {
        final controller = _StubDialogWindowController(tester);
        BaseWindowController? scope;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          _buildWindow(
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
          _buildWindow(
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
          _buildWindow(
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

      testWidgets('Can access WindowScope.maybeOf for satellite windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubSatelliteWindowController(tester: tester);
        BaseWindowController? scope;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          _buildWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                scope = WindowScope.maybeOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(scope, isA<SatelliteWindowController>());
      });

      testWidgets('Can access WindowScope.contentSizeOf for regular windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubWindowController(tester);
        Size? size;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          _buildWindow(
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
          _buildWindow(
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
          _buildWindow(
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
          _buildWindow(
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

      testWidgets('Can access WindowScope.contentSizeOf for satellite windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubSatelliteWindowController(tester: tester);
        Size? size;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          _buildWindow(
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
        final controller = _StubWindowController(tester);
        Size? size;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          _buildWindow(
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
          _buildWindow(
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
          _buildWindow(
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
          _buildWindow(
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

      testWidgets('Can access WindowScope.maybeContentSizeOf for satellite windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubSatelliteWindowController(tester: tester);
        Size? size;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          _buildWindow(
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
        final controller = _StubWindowController(tester);
        String? title;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          _buildWindow(
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
          _buildWindow(
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
          _buildWindow(
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
          _buildWindow(
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

      testWidgets('Can access WindowScope.titleOf for satellite windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubSatelliteWindowController(tester: tester);
        String? title;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          _buildWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                title = WindowScope.titleOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(title, equals('Stub Satellite Window'));
      });

      testWidgets('Can access WindowScope.maybeTitleOf for regular windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubWindowController(tester);
        String? title;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          _buildWindow(
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
          _buildWindow(
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
          _buildWindow(
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
          _buildWindow(
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

      testWidgets('Can access WindowScope.maybeTitleOf for satellite windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubSatelliteWindowController(tester: tester);
        String? title;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          _buildWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                title = WindowScope.maybeTitleOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(title, equals('Stub Satellite Window'));
      });

      testWidgets('Can access WindowScope.isActivatedOf for regular windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubWindowController(tester);
        bool? isActivated;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          _buildWindow(
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
          _buildWindow(
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
          _buildWindow(
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
          _buildWindow(
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

      testWidgets('Can access WindowScope.isActivatedOf for satellite windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubSatelliteWindowController(tester: tester);
        bool? isActivated;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          _buildWindow(
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
        final controller = _StubWindowController(tester);
        bool? isActivated;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          _buildWindow(
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
          _buildWindow(
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
          _buildWindow(
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
          _buildWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                isActivated = WindowScope.maybeIsActivatedOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(isActivated, isTrue);
      });

      testWidgets('Can access WindowScope.maybeIsActivatedOf for satellite windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubSatelliteWindowController(tester: tester);
        bool? isActivated;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          _buildWindow(
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
        final controller = _StubWindowController(tester);
        bool? isMinimized;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          _buildWindow(
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
          _buildWindow(
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
          _buildWindow(
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
          _buildWindow(
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
        final controller = _StubWindowController(tester);
        bool? isMinimized;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          _buildWindow(
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
          _buildWindow(
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
          _buildWindow(
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
          _buildWindow(
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
        final controller = _StubWindowController(tester);
        bool? isMaximized;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          _buildWindow(
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
          _buildWindow(
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
          _buildWindow(
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
          _buildWindow(
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

      testWidgets('Can access WindowScope.isMaximizedOf for satellite windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubSatelliteWindowController(tester: tester);
        bool? isMaximized;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          _buildWindow(
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
        final controller = _StubWindowController(tester);
        bool? isMaximized;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          _buildWindow(
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
          _buildWindow(
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
          _buildWindow(
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
          _buildWindow(
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

      testWidgets('Can access WindowScope.maybeIsMaximizedOf for satellite windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubSatelliteWindowController(tester: tester);
        bool? isMaximized;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          _buildWindow(
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
        final controller = _StubWindowController(tester);
        bool? isFullscreen;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          _buildWindow(
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
          _buildWindow(
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
          _buildWindow(
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
          _buildWindow(
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

      testWidgets('Can access WindowScope.isFullscreenOf for satellite windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubSatelliteWindowController(tester: tester);
        bool? isFullscreen;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          _buildWindow(
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
        final controller = _StubWindowController(tester);
        bool? isFullscreen;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          _buildWindow(
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
          _buildWindow(
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
          _buildWindow(
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
          _buildWindow(
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

      testWidgets('Can access WindowScope.maybeIsFullscreenOf for satellite windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubSatelliteWindowController(tester: tester);
        bool? isFullscreen;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          _buildWindow(
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

      testWidgets('Dependent rebuilds when an aspect changes and the controller notifies', (
        WidgetTester tester,
      ) async {
        final controller = _MutableWindowController(tester);
        addTearDown(controller.dispose);
        final observed = <bool>[];
        await tester.pumpWidget(
          wrapWithView: false,
          _buildWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                observed.add(WindowScope.isActivatedOf(context));
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(observed, <bool>[false]);

        controller.activate();
        await tester.pump();

        expect(observed, <bool>[false, true]);
      });

      testWidgets('Can access WindowScope.isDestroyedOf for regular windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubWindowController(tester);
        bool? isDestroyed;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          _buildWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                isDestroyed = WindowScope.isDestroyedOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(isDestroyed, equals(false));
      });

      testWidgets('Can access WindowScope.isDestroyedOf for dialog windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubDialogWindowController(tester);
        bool? isDestroyed;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          _buildWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                isDestroyed = WindowScope.isDestroyedOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(isDestroyed, equals(false));
      });

      testWidgets('Can access WindowScope.isDestroyedOf for tooltip windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubTooltipWindowController(tester: tester);
        bool? isDestroyed;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          _buildWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                isDestroyed = WindowScope.isDestroyedOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(isDestroyed, equals(false));
      });

      testWidgets('Can access WindowScope.isDestroyedOf for popup windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubPopupWindowController(tester: tester);
        bool? isDestroyed;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          _buildWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                isDestroyed = WindowScope.isDestroyedOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(isDestroyed, equals(false));
      });

      testWidgets('Can access WindowScope.isDestroyedOf for satellite windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubSatelliteWindowController(tester: tester);
        bool? isDestroyed;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          _buildWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                isDestroyed = WindowScope.isDestroyedOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(isDestroyed, equals(false));
      });

      testWidgets('Can access WindowScope.maybeIsDestroyedOf for regular windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubWindowController(tester);
        bool? isDestroyed;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          _buildWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                isDestroyed = WindowScope.maybeIsDestroyedOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(isDestroyed, equals(false));
      });

      testWidgets('Can access WindowScope.maybeIsDestroyedOf for dialog windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubDialogWindowController(tester);
        bool? isDestroyed;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          _buildWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                isDestroyed = WindowScope.maybeIsDestroyedOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(isDestroyed, equals(false));
      });

      testWidgets('Can access WindowScope.maybeIsDestroyedOf for tooltip windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubTooltipWindowController(tester: tester);
        bool? isDestroyed;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          _buildWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                isDestroyed = WindowScope.maybeIsDestroyedOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(isDestroyed, equals(false));
      });

      testWidgets('Can access WindowScope.maybeIsDestroyedOf for popup windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubPopupWindowController(tester: tester);
        bool? isDestroyed;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          _buildWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                isDestroyed = WindowScope.maybeIsDestroyedOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(isDestroyed, equals(false));
      });

      testWidgets('Can access WindowScope.maybeIsDestroyedOf for satellite windows', (
        WidgetTester tester,
      ) async {
        final controller = _StubSatelliteWindowController(tester: tester);
        bool? isDestroyed;
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          _buildWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                isDestroyed = WindowScope.maybeIsDestroyedOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(isDestroyed, equals(false));
      });

      testWidgets('WindowScope.maybeIsDestroyedOf returns null without a WindowScope ancestor', (
        WidgetTester tester,
      ) async {
        bool? isDestroyed;
        var builderCalled = false;
        await tester.pumpWidget(
          Builder(
            builder: (BuildContext context) {
              builderCalled = true;
              isDestroyed = WindowScope.maybeIsDestroyedOf(context);
              return const SizedBox.shrink();
            },
          ),
        );

        expect(builderCalled, isTrue);
        expect(isDestroyed, isNull);
      });

      testWidgets('Dependent rebuilds when the window is destroyed', (WidgetTester tester) async {
        final controller = _MutableWindowController(tester);
        addTearDown(controller.dispose);
        final observed = <bool>[];
        // A WindowManager would unregister the entry as soon as the window is
        // destroyed, so the dependent is rendered without one here.
        await tester.pumpWidget(
          wrapWithView: false,
          _buildUnmanagedWindow(
            controller: controller,
            child: Builder(
              builder: (BuildContext context) {
                observed.add(WindowScope.isDestroyedOf(context));
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(observed, <bool>[false]);

        // Destroying notifies listeners. The rebuild must not throw even though
        // the controller's other value getters throw once destroyed.
        controller.destroy();
        await tester.pump();

        expect(observed, <bool>[false, true]);
        expect(tester.takeException(), isNull);
      });

      testWidgets('WindowManager renders a satellite window', (WidgetTester tester) async {
        final controller = _StubSatelliteWindowController(tester: tester);
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          wrapWithView: false,
          _buildWindow(controller: controller, child: const Placeholder()),
        );

        expect(find.byType(Placeholder), findsOneWidget);
      });
    });

    group('WindowManager', () {
      setUp(() {
        isWindowingEnabled = true;
      });

      testWidgets('Renders every entry in initialWindows as a sibling subtree', (
        WidgetTester tester,
      ) async {
        final first = _StubWindowController(tester);
        addTearDown(first.dispose);
        final second = _StubWindowController(tester, viewId: 101);
        addTearDown(second.dispose);

        await tester.pumpWidget(
          wrapWithView: false,
          WindowManager(
            initialWindows: <WindowEntry>[
              WindowEntry(controller: first, builder: (BuildContext context) => _text('first')),
              WindowEntry(controller: second, builder: (BuildContext context) => _text('second')),
            ],
          ),
        );

        expect(find.text('first'), findsOneWidget);
        expect(find.text('second'), findsOneWidget);
      });

      testWidgets('Provides a WindowRegistry listing its entries', (WidgetTester tester) async {
        final controller = _StubWindowController(tester);
        addTearDown(controller.dispose);
        late WindowEntry entry;
        late WindowRegistry registry;

        entry = WindowEntry(
          controller: controller,
          builder: (BuildContext context) {
            registry = WindowRegistry.of(context);
            return _text('window');
          },
        );

        await tester.pumpWidget(
          wrapWithView: false,
          WindowManager(initialWindows: <WindowEntry>[entry]),
        );

        expect(registry.windows, <WindowEntry>[entry]);
      });

      testWidgets('showWindow renders an entry alongside the existing windows', (
        WidgetTester tester,
      ) async {
        final first = _StubWindowController(tester);
        addTearDown(first.dispose);
        final second = _StubWindowController(tester, viewId: 101);
        addTearDown(second.dispose);
        late BuildContext windowContext;

        await tester.pumpWidget(
          wrapWithView: false,
          WindowManager(
            initialWindows: <WindowEntry>[
              WindowEntry(
                controller: first,
                builder: (BuildContext context) {
                  windowContext = context;
                  return _text('first');
                },
              ),
            ],
          ),
        );

        expect(find.text('second'), findsNothing);

        showWindow(
          context: windowContext,
          entry: WindowEntry(
            controller: second,
            builder: (BuildContext context) => _text('second'),
          ),
        );
        await tester.pump();

        expect(find.text('first'), findsOneWidget);
        expect(find.text('second'), findsOneWidget);
      });

      testWidgets('Removes an entry once its window is destroyed', (WidgetTester tester) async {
        final controller = _MutableWindowController(tester);
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          wrapWithView: false,
          _buildWindow(controller: controller, child: const Placeholder()),
        );

        expect(find.byType(Placeholder), findsOneWidget);

        controller.destroy();
        await tester.pump();

        expect(find.byType(Placeholder), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('WindowRegistry.maybeOf returns null without a WindowManager ancestor', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(Container());

        expect(WindowRegistry.maybeOf(tester.element(find.byType(Container))), isNull);
      });

      testWidgets('showWindow throws a StateError without a WindowManager ancestor', (
        WidgetTester tester,
      ) async {
        final controller = _StubWindowController(tester);
        addTearDown(controller.dispose);
        await tester.pumpWidget(Container());
        final BuildContext context = tester.element(find.byType(Container));

        expect(
          () => showWindow(
            context: context,
            entry: WindowEntry(
              controller: controller,
              builder: (BuildContext context) => const SizedBox.shrink(),
            ),
          ),
          throwsStateError,
        );
      });
    });
  });
}
