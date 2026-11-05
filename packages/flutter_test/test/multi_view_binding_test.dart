// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoImplicitViewPlatformDispatcher extends TestPlatformDispatcher {
  _NoImplicitViewPlatformDispatcher({required super.platformDispatcher});

  @override
  TestFlutterView? get implicitView => null;
}

class _NoImplicitViewTestBinding extends AutomatedTestWidgetsFlutterBinding {
  late final _NoImplicitViewPlatformDispatcher _noImplicitViewPlatformDispatcher =
      _NoImplicitViewPlatformDispatcher(platformDispatcher: super.platformDispatcher);

  @override
  TestPlatformDispatcher get platformDispatcher => _noImplicitViewPlatformDispatcher;
}

/// A [FlutterView] that reports a different [viewId] than the view it
/// delegates to.
///
/// Used to verify that gestures and rendering carry the real view id: if any
/// code silently fell back to the first view (whose id is 0), a test using
/// this view would fail instead of passing for the wrong reason.
class _RenumberedView implements FlutterView {
  _RenumberedView(this._inner, this.viewId);

  final FlutterView _inner;

  @override
  final int viewId;

  @override
  PlatformDispatcher get platformDispatcher => _inner.platformDispatcher;

  @override
  Display get display => _inner.display;

  @override
  double get devicePixelRatio => _inner.devicePixelRatio;

  @override
  ViewConstraints get physicalConstraints => _inner.physicalConstraints;

  @override
  Size get physicalSize => _inner.physicalSize;

  @override
  ViewPadding get viewInsets => _inner.viewInsets;

  @override
  ViewPadding get viewPadding => _inner.viewPadding;

  @override
  ViewPadding get systemGestureInsets => _inner.systemGestureInsets;

  @override
  ViewPadding get padding => _inner.padding;

  @override
  GestureSettings get gestureSettings => _inner.gestureSettings;

  @override
  List<DisplayFeature> get displayFeatures => _inner.displayFeatures;

  @override
  DisplayCornerRadii? get displayCornerRadii => _inner.displayCornerRadii;

  @override
  void render(Scene scene, {Size? size}) => _inner.render(scene, size: size);

  @override
  void updateSemantics(SemanticsUpdate update) => _inner.updateSemantics(update);
}

void main() {
  final binding = _NoImplicitViewTestBinding();

  testWidgets('testWidgets renders and handles gestures without an implicit view', (
    WidgetTester tester,
  ) async {
    expect(binding.platformDispatcher.implicitView, isNull);
    expect(binding.renderViews, isEmpty);

    // Register an explicit view whose id is not 0, emulating a multi-view
    // application that has no implicit view at all.
    final FlutterView renumberedView = _RenumberedView(binding.platformDispatcher.views.first, 100);
    binding.platformDispatcher.addTestView(renumberedView);
    addTearDown(() => binding.platformDispatcher.removeTestView(renumberedView));
    final TestFlutterView view = binding.platformDispatcher.view(id: renumberedView.viewId)!;

    var taps = 0;
    var longPresses = 0;
    await tester.pumpWidget(
      View(
        view: view,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: ListView(
            children: <Widget>[
              GestureDetector(onTap: () => taps += 1, child: const Text('tap target')),
              GestureDetector(
                onLongPress: () => longPresses += 1,
                child: const Text('long press target'),
              ),
              const SizedBox(height: 600.0),
              const Text('target below the fold'),
            ],
          ),
        ),
      ),
      wrapWithView: false,
    );
    expect(binding.renderViews, hasLength(1));
    expect(find.byType(View), findsOneWidget);
    await tester.tap(find.text('tap target'));
    await tester.longPress(find.text('long press target'));
    expect(taps, 1);
    expect(longPresses, 1);

    // timedDrag resolves the view from the finder; in continuous mode
    // dragUntilVisible starts and ends its gesture on the dragged widget's
    // view. Neither may fall back to an implicit view.
    await tester.timedDrag(
      find.text('tap target'),
      const Offset(0.0, -50.0),
      const Duration(milliseconds: 100),
    );

    // Fling with an initial offset exercises the pointer move that is
    // dispatched before the main drag: it must carry the view id as well.
    await tester.fling(
      find.text('long press target'),
      const Offset(0.0, -100.0),
      500.0,
      initialOffset: const Offset(0.0, 10.0),
    );

    await tester.dragUntilVisible(
      find.text('target below the fold'),
      find.byType(ListView),
      const Offset(0.0, -100.0),
      continuous: true,
    );
    expect(find.text('target below the fold'), findsOneWidget);
  });

  testWidgets('the previous multi-view tree is unmounted after a test', (
    WidgetTester tester,
  ) async {
    expect(find.text('tap target'), findsNothing);
    expect(find.text('long press target'), findsNothing);
    expect(find.byType(View), findsNothing);
    expect(binding.renderViews, isEmpty);
  });
}
