// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/src/widgets/_window.dart'
    show
        RegularWindow,
        RegularWindowController,
        RegularWindowControllerDelegate,
        WindowControllerContext,
        WindowSizing,
        WindowingOwner;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubWindowController extends RegularWindowController {
  _StubWindowController() : super.empty();

  @override
  void setTitle(String title) {}

  @override
  void activate() {}

  @override
  void setMaximized(bool maximized) {}

  @override
  Size get contentSize => throw UnimplementedError();

  @override
  void destroy() {}

  @override
  bool isFullscreen() {
    throw UnimplementedError();
  }

  @override
  bool isMaximized() {
    throw UnimplementedError();
  }

  @override
  bool isMinimized() {
    throw UnimplementedError();
  }

  @override
  void setFullscreen(bool fullscreen, {int? displayId}) {}

  @override
  void setMinimized(bool minimized) {}

  @override
  void updateContentSize(WindowSizing sizing) {}
}

void main() {
  group('Windowing', () {
    test('createDefaultOwner returns a WindowingOwner', () {
      final WindowingOwner owner = WindowingOwner.createDefaultOwner();
      expect(owner, isA<WindowingOwner>());
    });

    test('default WindowingOwner throws when accessing createRegularWindowController', () {
      final WindowingOwner owner = WindowingOwner.createDefaultOwner();
      expect(
        () => owner.createRegularWindowController(
          contentSize: WindowSizing(),
          delegate: RegularWindowControllerDelegate(),
        ),
        throwsUnsupportedError,
      );
    });

    test('default WindowingOwner throws when accessing hasTopLevelWindows', () {
      final WindowingOwner owner = WindowingOwner.createDefaultOwner();
      expect(() => owner.hasTopLevelWindows(), throwsUnsupportedError);
    });

    testWidgets('RegularWindow throws UnsupportedError', (WidgetTester tester) async {
      expect(
        () => RegularWindow(controller: _StubWindowController(), child: const Text('Test')),
        throwsUnsupportedError,
      );
    });

    testWidgets('Accessing WindowControllerContet.of throws UnsupportedError', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(LookupBoundary(child: Container()));
      final BuildContext context = tester.element(find.byType(Container));

      expect(() => WindowControllerContext.of(context), throwsUnsupportedError);
    });

    test('Creating WindowSizing throws UnsupportedError when windowing is disabled', () {
      expect(
        () => WindowSizing(
          preferredSize: const Size(100, 100),
          preferredConstraints: const BoxConstraints(),
        ),
        throwsUnsupportedError,
      );
    });
  });
}
