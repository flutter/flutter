// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import '../painting/image_test_utils.dart';
import '../painting/mocks_for_image_cache.dart' show TestImage;

void main() {
  tearDown(() {
    imageCache.clear();
  });

  RecordingPhysics _findPhysics(WidgetTester tester) {
    return Scrollable.of(find.byType(TestWidget).evaluate().first).position.physics as RecordingPhysics;
  }

  ScrollMetrics _findMetrics(WidgetTester tester) {
    return Scrollable.of(find.byType(TestWidget).evaluate().first).position;
  }

  testWidgets('ScrollAwareImageProvider does not delay if widget is not in scrollable', (WidgetTester tester) async {
    final GlobalKey<TestWidgetState> key = GlobalKey<TestWidgetState>();
    await tester.pumpWidget(TestWidget(key));

    final DisposableBuildContext context = DisposableBuildContext(key.currentState);
    const TestImage testImage = TestImage(width: 10, height: 10);
    final TestImageProvider testImageProvider = TestImageProvider(testImage);
    final ScrollAwareImageProvider<TestImageProvider> imageProvider = ScrollAwareImageProvider<TestImageProvider>(
      context: context,
      imageProvider: testImageProvider,
    );

    expect(testImageProvider.configuration, null);
    expect(imageCache.containsKey(testImageProvider), false);

    final ImageStream stream = imageProvider.resolve(ImageConfiguration.empty);

    expect(testImageProvider.configuration, ImageConfiguration.empty);
    expect(stream.completer, isNotNull);
    expect(stream.completer.hasListeners, true);
    expect(imageCache.containsKey(testImageProvider), true);
    expect(imageCache.currentSize, 0);

    testImageProvider.complete();

    expect(imageCache.currentSize, 1);
  });

  testWidgets('ScrollAwareImageProvider does not delay if in scrollable that is not scrolling', (WidgetTester tester) async {
    final GlobalKey<TestWidgetState> key = GlobalKey<TestWidgetState>();
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: ListView(
        physics: RecordingPhysics(),
        children: <Widget>[
          TestWidget(key),
        ],
      ),
    ));

    final DisposableBuildContext context = DisposableBuildContext(key.currentState);
    const TestImage testImage = TestImage(width: 10, height: 10);
    final TestImageProvider testImageProvider = TestImageProvider(testImage);
    final ScrollAwareImageProvider<TestImageProvider> imageProvider = ScrollAwareImageProvider<TestImageProvider>(
      context: context,
      imageProvider: testImageProvider,
    );

    expect(testImageProvider.configuration, null);
    expect(imageCache.containsKey(testImageProvider), false);

    final ImageStream stream = imageProvider.resolve(ImageConfiguration.empty);

    expect(testImageProvider.configuration, ImageConfiguration.empty);
    expect(stream.completer, isNotNull);
    expect(stream.completer.hasListeners, true);
    expect(imageCache.containsKey(testImageProvider), true);
    expect(imageCache.currentSize, 0);

    testImageProvider.complete();

    expect(imageCache.currentSize, 1);
    expect(_findPhysics(tester).velocities, <double>[0]);
  });

  testWidgets('ScrollAwareImageProvider does not delay if in scrollable that is scrolling slowly', (WidgetTester tester) async {
    final List<GlobalKey<TestWidgetState>> keys = <GlobalKey<TestWidgetState>>[];
    final ScrollController scrollController = ScrollController();
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: ListView.builder(
        physics: RecordingPhysics(),
        controller: scrollController,
        itemBuilder: (BuildContext context, int index) {
          keys.add(GlobalKey<TestWidgetState>());
          return TestWidget(keys.last);
        },
        itemCount: 50,
      ),
    ));

    final DisposableBuildContext context = DisposableBuildContext(keys.last.currentState);
    const TestImage testImage = TestImage(width: 10, height: 10);
    final TestImageProvider testImageProvider = TestImageProvider(testImage);
    final ScrollAwareImageProvider<TestImageProvider> imageProvider = ScrollAwareImageProvider<TestImageProvider>(
      context: context,
      imageProvider: testImageProvider,
    );

    expect(testImageProvider.configuration, null);
    expect(imageCache.containsKey(testImageProvider), false);

    scrollController.animateTo(
      100,
      duration: const Duration(seconds: 2),
      curve: Curves.fastLinearToSlowEaseIn,
    );
    await tester.pump();
    final RecordingPhysics physics = _findPhysics(tester);

    expect(physics.velocities.length, 0);
    final ImageStream stream = imageProvider.resolve(ImageConfiguration.empty);
    expect(physics.velocities.length, 1);
    expect(
      const ScrollPhysics().recommendDeferredLoading(
        physics.velocities.first,
        _findMetrics(tester),
        find.byType(TestWidget).evaluate().first,
      ),
      false,
    );

    expect(testImageProvider.configuration, ImageConfiguration.empty);
    expect(stream.completer, isNotNull);
    expect(stream.completer.hasListeners, true);
    expect(imageCache.containsKey(testImageProvider), true);
    expect(imageCache.currentSize, 0);

    testImageProvider.complete();

    expect(imageCache.currentSize, 1);
  });

  testWidgets('ScrollAwareImageProvider delays if in scrollable that is scrolling fast', (WidgetTester tester) async {
    final List<GlobalKey<TestWidgetState>> keys = <GlobalKey<TestWidgetState>>[];
    final ScrollController scrollController = ScrollController();
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: ListView.builder(
        physics: RecordingPhysics(),
        controller: scrollController,
        itemBuilder: (BuildContext context, int index) {
          keys.add(GlobalKey<TestWidgetState>());
          return TestWidget(keys.last);
        },
        itemCount: 50,
      ),
    ));

    final DisposableBuildContext context = DisposableBuildContext(keys.last.currentState);
    const TestImage testImage = TestImage(width: 10, height: 10);
    final TestImageProvider testImageProvider = TestImageProvider(testImage);
    final ScrollAwareImageProvider<TestImageProvider> imageProvider = ScrollAwareImageProvider<TestImageProvider>(
      context: context,
      imageProvider: testImageProvider,
    );

    expect(testImageProvider.configuration, null);
    expect(imageCache.containsKey(testImageProvider), false);

    scrollController.animateTo(
      3000,
      duration: const Duration(seconds: 2),
      curve: Curves.fastLinearToSlowEaseIn,
    );
    await tester.pump();
    final RecordingPhysics physics = _findPhysics(tester);

    expect(physics.velocities.length, 0);
    final ImageStream stream = imageProvider.resolve(ImageConfiguration.empty);
    expect(physics.velocities.length, 1);
    expect(
      const ScrollPhysics().recommendDeferredLoading(
        physics.velocities.first,
        _findMetrics(tester),
        find.byType(TestWidget).evaluate().first,
      ),
      true,
    );

    expect(testImageProvider.configuration, null);
    expect(stream.completer, null);

    expect(imageCache.containsKey(testImageProvider), false);
    expect(imageCache.currentSize, 0);

    await tester.pump(const Duration(seconds: 1));
    expect(physics.velocities.last, 0);

    expect(testImageProvider.configuration, ImageConfiguration.empty);
    expect(stream.completer, isNotNull);
    expect(stream.completer.hasListeners, true);

    expect(imageCache.containsKey(testImageProvider), true);
    expect(imageCache.currentSize, 0);

    testImageProvider.complete();

    expect(imageCache.currentSize, 1);
  });

  testWidgets('ScrollAwareImageProvider delays if in scrollable that is scrolling fast and fizzles if disposed', (WidgetTester tester) async {
    final List<GlobalKey<TestWidgetState>> keys = <GlobalKey<TestWidgetState>>[];
    final ScrollController scrollController = ScrollController();
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: ListView.builder(
        physics: RecordingPhysics(),
        controller: scrollController,
        itemBuilder: (BuildContext context, int index) {
          keys.add(GlobalKey<TestWidgetState>());
          return TestWidget(keys.last);
        },
        itemCount: 50,
      ),
    ));

    final DisposableBuildContext context = DisposableBuildContext(keys.last.currentState);
    const TestImage testImage = TestImage(width: 10, height: 10);
    final TestImageProvider testImageProvider = TestImageProvider(testImage);
    final ScrollAwareImageProvider<TestImageProvider> imageProvider = ScrollAwareImageProvider<TestImageProvider>(
      context: context,
      imageProvider: testImageProvider,
    );

    expect(testImageProvider.configuration, null);
    expect(imageCache.containsKey(testImageProvider), false);

    scrollController.animateTo(
      3000,
      duration: const Duration(seconds: 2),
      curve: Curves.fastLinearToSlowEaseIn,
    );
    await tester.pump();
    final RecordingPhysics physics = _findPhysics(tester);

    expect(physics.velocities.length, 0);
    final ImageStream stream = imageProvider.resolve(ImageConfiguration.empty);
    expect(physics.velocities.length, 1);
    expect(
      const ScrollPhysics().recommendDeferredLoading(
        physics.velocities.first,
        _findMetrics(tester),
        find.byType(TestWidget).evaluate().first,
      ),
      true,
    );

    expect(testImageProvider.configuration, null);
    expect(stream.completer, null);

    expect(imageCache.containsKey(testImageProvider), false);
    expect(imageCache.currentSize, 0);

    // as if we had picked a context that scrolled out of the tree.
    context.dispose();

    await tester.pump(const Duration(seconds: 1));
    expect(physics.velocities.length, 1);

    expect(testImageProvider.configuration, null);
    expect(stream.completer, null);

    expect(imageCache.containsKey(testImageProvider), false);
    expect(imageCache.currentSize, 0);

    testImageProvider.complete();

    expect(imageCache.currentSize, 0);
  });
}

class TestWidget extends StatefulWidget {
  const TestWidget(Key key) : super(key: key);

  @override
  State<TestWidget> createState() => TestWidgetState();
}

class TestWidgetState extends State<TestWidget> {
  @override
  Widget build(BuildContext context) => const SizedBox(height: 50);
}

class RecordingPhysics extends ScrollPhysics {
  RecordingPhysics({ ScrollPhysics parent }) : super(parent: parent);

  final List<double> velocities = <double>[];

  @override
  RecordingPhysics applyTo(ScrollPhysics ancestor) {
    return RecordingPhysics(parent: buildParent(ancestor));
  }

  @override
  bool recommendDeferredLoading(double velocity, ScrollMetrics metrics, BuildContext context) {
    velocities.add(velocity);
    return super.recommendDeferredLoading(velocity, metrics, context);
  }
}
