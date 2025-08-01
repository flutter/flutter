// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Display;
import 'package:flutter/src/widgets/_window.dart'
    show
        RegularWindow,
        RegularWindowController,
        RegularWindowControllerDelegate,
        WindowScope,
        WindowingOwner;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubWindowController extends RegularWindowController {
  _StubWindowController() : super.empty();

  @override
  Size get contentSize => throw UnimplementedError();

  @override
  String get title => 'Stub Window';

  @override
  bool get isActivated {
    throw UnimplementedError();
  }

  @override
  bool get isMaximized {
    throw UnimplementedError();
  }

  @override
  bool get isMinimized {
    throw UnimplementedError();
  }

  @override
  bool get isFullscreen {
    throw UnimplementedError();
  }

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
        () => RegularWindow(controller: _StubWindowController(), child: const Text('Test')),
        throwsUnsupportedError,
      );
    });

    testWidgets('Accessing WindowScope.of throws UnsupportedError', (WidgetTester tester) async {
      await tester.pumpWidget(LookupBoundary(child: Container()));
      final BuildContext context = tester.element(find.byType(Container));

      expect(() => WindowScope.of(context), throwsUnsupportedError);
    });
  });
}
