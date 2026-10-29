// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const Key listKey = ValueKey<String>('list');

  Widget buildSheet({
    required DraggableScrollableController controller,
    required ValueChanged<ScrollController> onScrollController,
    double initialChildSize = 0.5,
    double minChildSize = 0.25,
    double maxChildSize = 1,
    bool snap = false,
    ScrollPhysics? physics,
  }) => Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: const MediaQueryData(),
      child: DraggableScrollableSheet(
        controller: controller,
        initialChildSize: initialChildSize,
        minChildSize: minChildSize,
        maxChildSize: maxChildSize,
        snap: snap,
        expand: false,
        builder: (BuildContext context, ScrollController scrollController) {
          onScrollController(scrollController);
          return ListView.builder(
            key: listKey,
            controller: scrollController,
            physics: physics,
            padding: EdgeInsets.zero,
            cacheExtent: 1000,
            itemCount: 40,
            itemExtent: 50,
            itemBuilder: (BuildContext context, int index) =>
                SizedBox(key: ValueKey<int>(index), child: Text('Item $index')),
          );
        },
      ),
    ),
  );

  Widget buildModalSheet({
    required DraggableScrollableController controller,
    required ValueChanged<ScrollController> onScrollController,
    FocusNode? focusNode,
    int focusIndex = 4,
  }) => MaterialApp(
    home: Builder(
      builder: (BuildContext context) => Scaffold(
        body: TextButton(
          onPressed: () {
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (BuildContext context) => Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
                child: DraggableScrollableSheet(
                  controller: controller,
                  expand: false,
                  builder: (BuildContext context, ScrollController scroll) {
                    onScrollController(scroll);
                    return ListView.builder(
                      key: listKey,
                      controller: scroll,
                      padding: EdgeInsets.zero,
                      itemCount: 20,
                      itemExtent: 50,
                      itemBuilder: (BuildContext context, int index) => TextField(
                        key: ValueKey<int>(index),
                        focusNode: index == focusIndex ? focusNode : null,
                        decoration: InputDecoration(hintText: 'Field $index'),
                      ),
                    );
                  },
                ),
              ),
            );
          },
          child: const Text('Open'),
        ),
      ),
    ),
  );

  testWidgets('The modal sheet can expand after the keyboard reveals a text field', (
    WidgetTester tester,
  ) async {
    // Regression test for https://github.com/flutter/flutter/issues/94942.
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 600);
    addTearDown(tester.view.reset);
    late ScrollController scrollController;
    final controller = DraggableScrollableController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      buildModalSheet(
        controller: controller,
        onScrollController: (ScrollController value) {
          scrollController = value;
        },
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<int>(4)));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 200);
    await tester.pumpAndSettle();

    // Focusing the field retains the normal fractional sheet size and scrolls
    // the field into view. That offset must not prevent the next upward drag.
    expect(controller.size, 0.5);
    final double revealedOffset = scrollController.offset;
    expect(revealedOffset, greaterThan(0));
    await tester.drag(find.byKey(listKey), const Offset(0, -60));
    await tester.pumpAndSettle();
    expect(controller.size, greaterThan(0.5));
    expect(scrollController.offset, closeTo(revealedOffset, precisionErrorTolerance));
  }, variant: TargetPlatformVariant.all());

  for (final keepFocus in <bool>[true, false]) {
    testWidgets('Hiding the keyboard keeps the sheet responsive with keepFocus=$keepFocus', (
      WidgetTester tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(400, 600);
      addTearDown(tester.view.reset);
      final controller = DraggableScrollableController();
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);
      late ScrollController scrollController;
      await tester.pumpWidget(
        buildModalSheet(
          controller: controller,
          focusNode: focusNode,
          onScrollController: (ScrollController value) {
            scrollController = value;
          },
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<int>(4)));
      tester.view.viewInsets = const FakeViewPadding(bottom: 200);
      await tester.pumpAndSettle();
      expect(focusNode.hasFocus, isTrue);
      expect(scrollController.offset, greaterThan(0));

      await tester.drag(find.byKey(listKey), const Offset(0, -60));
      await tester.pumpAndSettle();
      final double expandedSize = controller.size;
      final double revealedOffset = scrollController.offset;
      final double heightWithKeyboard = tester.getSize(find.byKey(listKey)).height;
      expect(expandedSize, greaterThan(0.5));

      tester.testTextInput.hide();
      if (!keepFocus) {
        focusNode.unfocus();
      }
      // Keyboard metrics arrive over several frames on mobile platforms.
      // The fractional sheet size must stay fixed while its pixel height grows.
      for (final inset in <double>[160, 120, 80, 40, 0]) {
        tester.view.viewInsets = FakeViewPadding(bottom: inset);
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump();
        expect(controller.size, closeTo(expandedSize, precisionErrorTolerance));
        expect(
          tester.getSize(find.byKey(listKey)).height,
          closeTo(expandedSize * (600 - inset), precisionErrorTolerance),
        );
        expect(scrollController.offset, closeTo(revealedOffset, precisionErrorTolerance));
      }
      await tester.pumpAndSettle();
      expect(focusNode.hasFocus, keepFocus);
      expect(tester.testTextInput.isVisible, isFalse);
      expect(tester.getSize(find.byKey(listKey)).height, greaterThan(heightWithKeyboard));

      // A downward drag must first move the list back toward its beginning,
      // rather than immediately shrinking the partially expanded sheet.
      final position = scrollController.position as ScrollPositionWithSingleContext;
      final Drag drag = position.drag(DragStartDetails(), () {});
      drag.update(
        DragUpdateDetails(
          delta: Offset(0, revealedOffset / 2),
          primaryDelta: revealedOffset / 2,
          globalPosition: Offset.zero,
        ),
      );
      drag.end(DragEndDetails(primaryVelocity: 0));
      await tester.pumpAndSettle();
      expect(controller.size, closeTo(expandedSize, precisionErrorTolerance));
      expect(scrollController.offset, closeTo(revealedOffset / 2, precisionErrorTolerance));

      // Once the list reaches its beginning, both resizing directions still work.
      scrollController.jumpTo(0);
      await tester.pump();
      await tester.drag(find.byKey(listKey), const Offset(0, 60));
      await tester.pumpAndSettle();
      expect(controller.size, lessThan(expandedSize));
      expect(scrollController.offset, 0);
      final double shrunkenSize = controller.size;
      await tester.drag(find.byKey(listKey), const Offset(0, -60));
      await tester.pumpAndSettle();
      expect(controller.size, greaterThan(shrunkenSize));
      expect(scrollController.offset, 0);
    }, variant: TargetPlatformVariant.all());
  }

  testWidgets('Hiding the keyboard at the list end corrects its offset without getting stuck', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 600);
    addTearDown(tester.view.reset);
    final controller = DraggableScrollableController();
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    late ScrollController scrollController;
    await tester.pumpWidget(
      buildModalSheet(
        controller: controller,
        focusNode: focusNode,
        focusIndex: 19,
        onScrollController: (ScrollController value) {
          scrollController = value;
        },
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    scrollController.jumpTo(scrollController.position.maxScrollExtent);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<int>(19)));
    tester.view.viewInsets = const FakeViewPadding(bottom: 200);
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(listKey), const Offset(0, -60));
    await tester.pumpAndSettle();
    final double expandedSize = controller.size;
    expect(expandedSize, greaterThan(0.5));

    tester.testTextInput.hide();
    for (final inset in <double>[160, 120, 80, 40, 0]) {
      tester.view.viewInsets = FakeViewPadding(bottom: inset);
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump();
      expect(controller.size, closeTo(expandedSize, precisionErrorTolerance));
    }
    await tester.pumpAndSettle();
    expect(focusNode.hasFocus, isTrue);
    expect(
      scrollController.offset,
      closeTo(scrollController.position.maxScrollExtent, precisionErrorTolerance),
    );
    final Rect viewport = tester.getRect(find.byKey(listKey));
    final Rect lastField = tester.getRect(find.byKey(const ValueKey<int>(19)));
    expect(lastField.bottom, closeTo(viewport.bottom, precisionErrorTolerance));

    await tester.drag(find.byKey(listKey), const Offset(0, 60));
    await tester.pumpAndSettle();
    expect(controller.size, closeTo(expandedSize, precisionErrorTolerance));
    expect(scrollController.offset, lessThan(scrollController.position.maxScrollExtent));
    await tester.drag(find.byKey(listKey), const Offset(0, -60));
    await tester.pumpAndSettle();
    expect(controller.size, greaterThan(expandedSize));
    expect(scrollController.offset, lessThanOrEqualTo(scrollController.position.maxScrollExtent));
  }, variant: TargetPlatformVariant.all());

  testWidgets('The sheet can expand after ensureVisible scrolls its contents', (
    WidgetTester tester,
  ) async {
    final controller = DraggableScrollableController();
    addTearDown(controller.dispose);
    late ScrollController scrollController;
    await tester.pumpWidget(
      buildSheet(
        controller: controller,
        onScrollController: (ScrollController value) {
          scrollController = value;
        },
      ),
    );
    await Scrollable.ensureVisible(
      tester.element(find.byKey(const ValueKey<int>(8), skipOffstage: false)),
    );
    await tester.pumpAndSettle();
    expect(controller.size, 0.5);
    expect(scrollController.offset, 400);
    await tester.drag(find.byKey(listKey), const Offset(0, -80));
    await tester.pumpAndSettle();
    expect(controller.size, greaterThan(0.5));
    expect(scrollController.offset, 400);
  });

  for (final animate in <bool>[false, true]) {
    testWidgets('An upward drag expands the sheet after a list ${animate ? 'animation' : 'jump'}', (
      WidgetTester tester,
    ) async {
      final controller = DraggableScrollableController();
      addTearDown(controller.dispose);
      late ScrollController scrollController;
      await tester.pumpWidget(
        buildSheet(
          controller: controller,
          onScrollController: (ScrollController value) {
            scrollController = value;
          },
        ),
      );
      if (animate) {
        final Future<void> scrolling = scrollController.animateTo(
          110,
          duration: const Duration(milliseconds: 300),
          curve: Curves.linear,
        );
        await tester.pumpAndSettle();
        await scrolling;
      } else {
        scrollController.jumpTo(110);
        await tester.pumpAndSettle();
      }
      expect(controller.size, 0.5);
      expect(scrollController.offset, 110);
      await tester.drag(find.byKey(listKey), const Offset(0, -80));
      await tester.pumpAndSettle();
      expect(controller.size, greaterThan(0.5));
      expect(scrollController.offset, 110);
    });
  }

  testWidgets('Downward drags return the list before shrinking the sheet', (
    WidgetTester tester,
  ) async {
    final controller = DraggableScrollableController();
    addTearDown(controller.dispose);
    late ScrollController scrollController;
    await tester.pumpWidget(
      buildSheet(
        controller: controller,
        onScrollController: (ScrollController value) {
          scrollController = value;
        },
      ),
    );
    scrollController.jumpTo(110);
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(listKey), const Offset(0, 60));
    await tester.pumpAndSettle();
    expect(scrollController.offset, inExclusiveRange(0, 110));
    expect(controller.size, 0.5);
  });

  testWidgets('A fully expanded sheet scrolls the list on upward drags', (
    WidgetTester tester,
  ) async {
    final controller = DraggableScrollableController();
    addTearDown(controller.dispose);
    late ScrollController scrollController;
    await tester.pumpWidget(
      buildSheet(
        controller: controller,
        initialChildSize: 1,
        onScrollController: (ScrollController value) {
          scrollController = value;
        },
      ),
    );
    scrollController.jumpTo(110);
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(listKey), const Offset(0, -80));
    await tester.pumpAndSettle();
    expect(controller.size, 1);
    expect(scrollController.offset, greaterThan(110));
  });

  testWidgets('Reaching maxChildSize allows subsequent drags to scroll the list', (
    WidgetTester tester,
  ) async {
    final controller = DraggableScrollableController();
    addTearDown(controller.dispose);
    late ScrollController scrollController;
    await tester.pumpWidget(
      buildSheet(
        controller: controller,
        initialChildSize: 0.7,
        maxChildSize: 0.8,
        onScrollController: (ScrollController value) {
          scrollController = value;
        },
      ),
    );
    scrollController.jumpTo(110);
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(listKey), const Offset(0, -120));
    await tester.pumpAndSettle();
    expect(controller.size, 0.8);
    final double offset = scrollController.offset;
    await tester.drag(find.byKey(listKey), const Offset(0, -60));
    await tester.pumpAndSettle();
    expect(controller.size, 0.8);
    expect(scrollController.offset, greaterThan(offset));
  });

  testWidgets('A sheet at its minimum can expand with an already scrolled list', (
    WidgetTester tester,
  ) async {
    final controller = DraggableScrollableController();
    addTearDown(controller.dispose);
    late ScrollController scrollController;
    await tester.pumpWidget(
      buildSheet(
        controller: controller,
        initialChildSize: 0.25,
        onScrollController: (ScrollController value) {
          scrollController = value;
        },
      ),
    );
    scrollController.jumpTo(110);
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(listKey), const Offset(0, -60));
    await tester.pumpAndSettle();
    expect(controller.size, greaterThan(0.25));
    expect(scrollController.offset, 110);
  });

  testWidgets('Upward drags still snap the sheet with an already scrolled list', (
    WidgetTester tester,
  ) async {
    final controller = DraggableScrollableController();
    addTearDown(controller.dispose);
    late ScrollController scrollController;
    await tester.pumpWidget(
      buildSheet(
        controller: controller,
        snap: true,
        onScrollController: (ScrollController value) {
          scrollController = value;
        },
      ),
    );
    scrollController.jumpTo(110);
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(listKey), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(controller.size, 1);
    expect(scrollController.offset, greaterThanOrEqualTo(110));
  });

  testWidgets('NeverScrollableScrollPhysics prevents dragging an already scrolled sheet', (
    WidgetTester tester,
  ) async {
    final controller = DraggableScrollableController();
    addTearDown(controller.dispose);
    late ScrollController scrollController;
    await tester.pumpWidget(
      buildSheet(
        controller: controller,
        physics: const NeverScrollableScrollPhysics(),
        onScrollController: (ScrollController value) {
          scrollController = value;
        },
      ),
    );
    scrollController.jumpTo(110);
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(listKey), const Offset(0, -80));
    await tester.pumpAndSettle();
    expect(controller.size, 0.5);
    expect(scrollController.offset, 110);
  });

  testWidgets('A fixed-size sheet can still scroll an already moved list', (
    WidgetTester tester,
  ) async {
    final controller = DraggableScrollableController();
    addTearDown(controller.dispose);
    late ScrollController scrollController;
    await tester.pumpWidget(
      buildSheet(
        controller: controller,
        minChildSize: 0.5,
        maxChildSize: 0.5,
        onScrollController: (ScrollController value) {
          scrollController = value;
        },
      ),
    );
    scrollController.jumpTo(110);
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(listKey), const Offset(0, -80));
    await tester.pumpAndSettle();
    expect(controller.size, 0.5);
    expect(scrollController.offset, greaterThan(110));
  });

  for (final physics in <ScrollPhysics>[
    const ClampingScrollPhysics(),
    const BouncingScrollPhysics(),
  ]) {
    for (final initialOffset in <double>[0, 110]) {
      testWidgets('Upward drag preserves its remainder from $initialOffset with $physics', (
        WidgetTester tester,
      ) async {
        final controller = DraggableScrollableController();
        addTearDown(controller.dispose);
        late ScrollController scrollController;
        await tester.pumpWidget(
          buildSheet(
            controller: controller,
            initialChildSize: 0.7,
            maxChildSize: 0.8,
            physics: physics,
            onScrollController: (ScrollController value) {
              scrollController = value;
            },
          ),
        );
        scrollController.jumpTo(initialOffset);
        await tester.pumpAndSettle();
        final position = scrollController.position as ScrollPositionWithSingleContext;
        final Drag drag = position.drag(DragStartDetails(), () {});
        drag.update(
          DragUpdateDetails(
            delta: const Offset(0, -100),
            primaryDelta: -100,
            globalPosition: Offset.zero,
          ),
        );
        await tester.pump();
        expect(controller.size, 0.8);
        expect(scrollController.offset, closeTo(initialOffset + 40, precisionErrorTolerance));
        drag.end(DragEndDetails(primaryVelocity: 0));
        await tester.pumpAndSettle();
      });
    }

    for (final initialOffset in <double>[40, 100]) {
      testWidgets('Downward drag preserves its remainder from $initialOffset with $physics', (
        WidgetTester tester,
      ) async {
        final controller = DraggableScrollableController();
        addTearDown(controller.dispose);
        late ScrollController scrollController;
        await tester.pumpWidget(
          buildSheet(
            controller: controller,
            physics: physics,
            onScrollController: (ScrollController value) {
              scrollController = value;
            },
          ),
        );
        scrollController.jumpTo(initialOffset);
        await tester.pumpAndSettle();
        final double initialHeight = controller.pixels;
        final position = scrollController.position as ScrollPositionWithSingleContext;
        final Drag drag = position.drag(DragStartDetails(), () {});
        drag.update(
          DragUpdateDetails(
            delta: const Offset(0, 100),
            primaryDelta: 100,
            globalPosition: Offset.zero,
          ),
        );
        await tester.pump();
        expect(scrollController.offset, closeTo(0, precisionErrorTolerance));
        expect(
          controller.pixels,
          closeTo(initialHeight - (100 - initialOffset), precisionErrorTolerance),
        );
        drag.end(DragEndDetails(primaryVelocity: 0));
        await tester.pumpAndSettle();
      });
    }
  }

  for (final scenario in <({double factor, double initialOffset, double offset, double height})>[
    (factor: 0, initialOffset: 40, offset: 40, height: 300),
    (factor: 0.5, initialOffset: 110, offset: 60, height: 300),
    (factor: 0.5, initialOffset: 50, offset: 0, height: 300),
    (factor: 0.5, initialOffset: 40, offset: 0, height: 280),
    (factor: 2, initialOffset: 110, offset: 0, height: 255),
  ]) {
    testWidgets(
      'Downward drags respect ${scenario.factor}x physics from ${scenario.initialOffset}',
      (WidgetTester tester) async {
        final controller = DraggableScrollableController();
        addTearDown(controller.dispose);
        late ScrollController scrollController;
        await tester.pumpWidget(
          buildSheet(
            controller: controller,
            physics: _ScaledScrollPhysics(scenario.factor, parent: const ClampingScrollPhysics()),
            onScrollController: (ScrollController value) {
              scrollController = value;
            },
          ),
        );
        scrollController.jumpTo(scenario.initialOffset);
        await tester.pumpAndSettle();
        final position = scrollController.position as ScrollPositionWithSingleContext;
        final Drag drag = position.drag(DragStartDetails(), () {});
        drag.update(
          DragUpdateDetails(
            delta: const Offset(0, 100),
            primaryDelta: 100,
            globalPosition: Offset.zero,
          ),
        );
        await tester.pump();
        expect(scrollController.offset, closeTo(scenario.offset, precisionErrorTolerance));
        expect(controller.pixels, closeTo(scenario.height, precisionErrorTolerance));
        drag.end(DragEndDetails(primaryVelocity: 0));
        await tester.pumpAndSettle();
      },
    );
  }

  for (final factor in <double>[0.5, 2]) {
    testWidgets('A downward drag across both boundaries applies ${factor}x physics once', (
      WidgetTester tester,
    ) async {
      final controller = DraggableScrollableController();
      addTearDown(controller.dispose);
      late ScrollController scrollController;
      await tester.pumpWidget(
        buildSheet(
          controller: controller,
          physics: _ScaledScrollPhysics(factor, parent: const BouncingScrollPhysics()),
          onScrollController: (ScrollController value) {
            scrollController = value;
          },
        ),
      );
      scrollController.jumpTo(40);
      await tester.pumpAndSettle();
      final position = scrollController.position as ScrollPositionWithSingleContext;
      final Drag drag = position.drag(DragStartDetails(), () {});
      drag.update(
        DragUpdateDetails(
          delta: const Offset(0, 400),
          primaryDelta: 400,
          globalPosition: Offset.zero,
        ),
      );
      await tester.pump();

      // The list consumes 40 / factor of the gesture, then the sheet consumes
      // 150 logical pixels. Only the remaining raw offset gets scroll physics.
      expect(controller.size, 0.25);
      final double remainingDrag = 400 - 40 / factor - 150;
      expect(scrollController.offset, closeTo(-remainingDrag * factor, precisionErrorTolerance));
      drag.end(DragEndDetails(primaryVelocity: 0));
      await tester.pumpAndSettle();
      expect(controller.size, 0.25);
      expect(scrollController.offset, closeTo(0, precisionErrorTolerance));
    });
  }

  testWidgets('A resize notification can cancel the remaining upward drag', (
    WidgetTester tester,
  ) async {
    final controller = DraggableScrollableController();
    addTearDown(controller.dispose);
    late ScrollController scrollController;
    var cancelDrag = true;
    await tester.pumpWidget(
      NotificationListener<DraggableScrollableNotification>(
        onNotification: (DraggableScrollableNotification notification) {
          if (cancelDrag && notification.extent == 0.8) {
            cancelDrag = false;
            controller.jumpTo(0.6);
          }
          return false;
        },
        child: buildSheet(
          controller: controller,
          initialChildSize: 0.7,
          maxChildSize: 0.8,
          onScrollController: (ScrollController value) {
            scrollController = value;
          },
        ),
      ),
    );
    scrollController.jumpTo(110);
    await tester.pumpAndSettle();
    final position = scrollController.position as ScrollPositionWithSingleContext;
    final Drag drag = position.drag(DragStartDetails(), () {});
    drag.update(
      DragUpdateDetails(
        delta: const Offset(0, -100),
        primaryDelta: -100,
        globalPosition: Offset.zero,
      ),
    );
    await tester.pumpAndSettle();
    expect(cancelDrag, isFalse);
    expect(controller.size, 0.6);
    expect(scrollController.offset, 110);
  });

  for (final notificationType in <Type>[UserScrollNotification, ScrollUpdateNotification]) {
    testWidgets('A $notificationType can cancel the remaining downward drag', (
      WidgetTester tester,
    ) async {
      final controller = DraggableScrollableController();
      addTearDown(controller.dispose);
      late ScrollController scrollController;
      var cancelDrag = false;
      await tester.pumpWidget(
        NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification notification) {
            if (cancelDrag && notification.runtimeType == notificationType) {
              cancelDrag = false;
              scrollController.jumpTo(25);
            }
            return false;
          },
          child: buildSheet(
            controller: controller,
            physics: const ClampingScrollPhysics(),
            onScrollController: (ScrollController value) {
              scrollController = value;
            },
          ),
        ),
      );
      scrollController.jumpTo(40);
      await tester.pumpAndSettle();
      cancelDrag = true;
      final position = scrollController.position as ScrollPositionWithSingleContext;
      final Drag drag = position.drag(DragStartDetails(), () {});
      drag.update(
        DragUpdateDetails(
          delta: const Offset(0, 100),
          primaryDelta: 100,
          globalPosition: Offset.zero,
        ),
      );
      await tester.pumpAndSettle();
      expect(cancelDrag, isFalse);
      expect(controller.size, 0.5);
      expect(scrollController.offset, 25);
    });
  }

  testWidgets('Mouse wheel scrolling retains its normal list offsets', (WidgetTester tester) async {
    final controller = DraggableScrollableController();
    addTearDown(controller.dispose);
    late ScrollController scrollController;
    await tester.pumpWidget(
      buildSheet(
        controller: controller,
        onScrollController: (ScrollController value) {
          scrollController = value;
        },
      ),
    );
    scrollController.jumpTo(110);
    await tester.pumpAndSettle();
    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: tester.getCenter(find.byKey(listKey)),
        scrollDelta: const Offset(0, 40),
      ),
    );
    await tester.pumpAndSettle();
    expect(controller.size, 0.5);
    expect(scrollController.offset, 150);
  });

  testWidgets('A list offset survives programmatic sheet resizing', (WidgetTester tester) async {
    final controller = DraggableScrollableController();
    addTearDown(controller.dispose);
    late ScrollController scrollController;
    await tester.pumpWidget(
      buildSheet(
        controller: controller,
        initialChildSize: 1,
        onScrollController: (ScrollController value) {
          scrollController = value;
        },
      ),
    );
    scrollController.jumpTo(110);
    controller.jumpTo(0.5);
    await tester.pumpAndSettle();
    expect(controller.size, 0.5);
    expect(scrollController.offset, 110);
    final Future<void> resizing = controller.animateTo(
      0.7,
      duration: const Duration(milliseconds: 200),
      curve: Curves.linear,
    );
    await tester.pumpAndSettle();
    await resizing;
    expect(controller.size, 0.7);
    expect(scrollController.offset, 110);
  });

  testWidgets('A trackpad gesture can expand an already scrolled sheet', (
    WidgetTester tester,
  ) async {
    final controller = DraggableScrollableController();
    addTearDown(controller.dispose);
    late ScrollController scrollController;
    await tester.pumpWidget(
      buildSheet(
        controller: controller,
        onScrollController: (ScrollController value) {
          scrollController = value;
        },
      ),
    );
    scrollController.jumpTo(110);
    await tester.pumpAndSettle();
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.trackpad);
    final Offset center = tester.getCenter(find.byKey(listKey));
    await gesture.panZoomStart(center);
    await tester.pump();
    await gesture.panZoomUpdate(center, pan: const Offset(0, -80));
    await tester.pump();
    await gesture.panZoomEnd();
    await tester.pumpAndSettle();
    expect(controller.size, greaterThan(0.5));
    expect(scrollController.offset, 110);
  });
}

class _ScaledScrollPhysics extends ScrollPhysics {
  const _ScaledScrollPhysics(this.factor, {super.parent});

  final double factor;

  @override
  _ScaledScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _ScaledScrollPhysics(factor, parent: buildParent(ancestor));
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    return super.applyPhysicsToUserOffset(position, offset) * factor;
  }
}
