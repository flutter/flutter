// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'multi_view_testing.dart';

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

void main() {
  final binding = _NoImplicitViewTestBinding();

  testWidgets('testWidgets renders and handles gestures without an implicit view', (
    WidgetTester tester,
  ) async {
    expect(binding.platformDispatcher.implicitView, isNull);
    expect(binding.renderViews, isEmpty);

    // Register an explicit view whose id is not 0, emulating a multi-view
    // application that has no implicit view at all. If any gesture or render
    // code silently fell back to the first view (whose id is 0), the
    // assertions below would fail instead of passing for the wrong reason.
    final fakeView = FakeView(binding.platformDispatcher.views.first);
    binding.platformDispatcher.addTestView(fakeView);
    addTearDown(() => binding.platformDispatcher.removeTestView(fakeView));
    final TestFlutterView view = binding.platformDispatcher.view(id: fakeView.viewId)!;

    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    var taps = 0;
    var longPresses = 0;
    await tester.pumpWidget(
      View(
        view: view,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: ListView(
            controller: scrollController,
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

    // timedDrag and fling must not only dispatch their events to the right
    // view but also have the expected effect on it: the drag should actually
    // advance the scroll offset of the list. A gesture that silently targets
    // a different view (e.g. because a pointer event is missing its view id)
    // would leave the offset unchanged and fail here.
    expect(scrollController.offset, 0.0);
    await tester.timedDrag(
      find.text('tap target'),
      const Offset(0.0, -50.0),
      const Duration(milliseconds: 100),
    );
    expect(scrollController.offset, greaterThan(0.0));
    final double offsetAfterTimedDrag = scrollController.offset;

    // The non-zero initialOffset exercises the pointer move that flingFrom
    // dispatches before the main drag; it must carry the view id as well.
    await tester.fling(
      find.byType(ListView),
      const Offset(0.0, -100.0),
      500.0,
      initialOffset: const Offset(0.0, -10.0),
    );
    expect(scrollController.offset, greaterThan(offsetAfterTimedDrag));

    // dragUntilVisible in continuous mode starts and ends its gesture on the
    // dragged widget's view; neither it nor the fling may fall back to an
    // implicit view.
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

  testWidgets('restartAndRestore works without an implicit view', (WidgetTester tester) async {
    // Register an explicit view, like in the test above.
    final fakeView = FakeView(binding.platformDispatcher.views.first);
    binding.platformDispatcher.addTestView(fakeView);
    addTearDown(() => binding.platformDispatcher.removeTestView(fakeView));
    final TestFlutterView view = binding.platformDispatcher.view(id: fakeView.viewId)!;

    await tester.pumpWidget(
      View(
        view: view,
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: RootRestorationScope(restorationId: 'root', child: _RestorationProbe()),
        ),
      ),
      wrapWithView: false,
    );

    final _RestorationProbeState stateBefore = tester.state<_RestorationProbeState>(
      find.byType(_RestorationProbe),
    );
    stateBefore.increment();
    await tester.pump();
    expect(stateBefore.restorableCounter.value, 1);
    expect(stateBefore.plainCounter, 1);

    // Without an implicit view this used to crash: taking the tree down
    // before the restoration called runApp unconditionally.
    await tester.restartAndRestore();

    final _RestorationProbeState stateAfter = tester.state<_RestorationProbeState>(
      find.byType(_RestorationProbe),
    );
    // The state object was recreated by the restart ...
    expect(identical(stateBefore, stateAfter), isFalse);
    // ... the restorable value survived ...
    expect(stateAfter.restorableCounter.value, 1);
    // ... and the non-restorable field was reset.
    expect(stateAfter.plainCounter, 0);
  });
}

class _RestorationProbe extends StatefulWidget {
  const _RestorationProbe();

  @override
  State<_RestorationProbe> createState() => _RestorationProbeState();
}

class _RestorationProbeState extends State<_RestorationProbe> with RestorationMixin {
  final RestorableInt restorableCounter = RestorableInt(0);
  int plainCounter = 0;

  void increment() {
    setState(() {
      restorableCounter.value += 1;
      plainCounter += 1;
    });
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(restorableCounter, 'counter');
  }

  @override
  String? get restorationId => 'restoration_probe';

  @override
  void dispose() {
    restorableCounter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text('counter: ${restorableCounter.value}');
  }
}
