// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final OverlayPortalController controller1 = OverlayPortalController(debugLabel: 'controller1');
  setUp(controller1.show);

  testWidgets('Basic test', (WidgetTester tester) async {
    late StateSetter setState;
    Matrix4 transform = Matrix4.identity();
    late final OverlayEntry overlayEntry;
    addTearDown(() {
      overlayEntry
        ..remove()
        ..dispose();
    });

    late Matrix4 paintTransform;
    late Size regularChildSize;
    late Rect regularChildRectInTheater;
    late Size theaterSize;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            overlayEntry = OverlayEntry(
              builder: (BuildContext context) {
                return Positioned(
                  left: 10,
                  top: 20,
                  child: StatefulBuilder(
                    builder: (BuildContext context, StateSetter setter) {
                      setState = setter;
                      return Transform(
                        transform: transform,
                        // RenderTransform uses size in its applyPaintTransform
                        // implementation if alignment is set.
                        alignment: Alignment.topLeft,
                        child: OverlayPortal.overlayChildLayoutBuilder(
                          controller: controller1,
                          overlayChildBuilder:
                              (BuildContext context, OverlayChildLayoutInfo layoutInfo) {
                                paintTransform = layoutInfo.childPaintTransform;
                                regularChildSize = layoutInfo.childSize;
                                regularChildRectInTheater = MatrixUtils.transformRect(
                                  paintTransform,
                                  Offset.zero & layoutInfo.childSize,
                                );
                                theaterSize = layoutInfo.overlaySize;
                                return const SizedBox();
                              },
                          child: const SizedBox(width: 40, height: 50),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
    // Does not schedule a new frame by itself.
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(paintTransform, Matrix4.translationValues(10.0, 20.0, 0.0));
    expect(regularChildSize, const Size(40, 50));
    expect(theaterSize, const Size(800, 600));
    expect(regularChildRectInTheater, const Offset(10.0, 20.0) & regularChildSize);

    setState(() => transform = Matrix4.diagonal3Values(2.0, 4.0, 1.0));
    assert(tester.binding.hasScheduledFrame);
    await tester.pump();

    expect(paintTransform, Matrix4.translationValues(10.0, 20.0, 0.0) * transform);
    expect(regularChildSize, const Size(40, 50));
    expect(theaterSize, const Size(800, 600));
    expect(regularChildRectInTheater, const Offset(10.0, 20.0) & const Size(80.0, 200.0));
  });

  testWidgets('child changes size', (WidgetTester tester) async {
    late StateSetter setState;
    late final OverlayEntry overlayEntry;
    addTearDown(
      () => overlayEntry
        ..remove()
        ..dispose(),
    );

    late Size regularChildSize;
    Size childSize = const Size(40, 50);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            overlayEntry = OverlayEntry(
              builder: (BuildContext context) {
                return Positioned(
                  left: 10,
                  top: 20,
                  child: StatefulBuilder(
                    builder: (BuildContext context, StateSetter setter) {
                      setState = setter;
                      return OverlayPortal.overlayChildLayoutBuilder(
                        controller: controller1,
                        overlayChildBuilder:
                            (BuildContext context, OverlayChildLayoutInfo layoutInfo) {
                              regularChildSize = layoutInfo.childSize;
                              return const SizedBox();
                            },
                        child: SizedBox.fromSize(size: childSize),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
    expect(regularChildSize, childSize);

    setState(() => childSize = const Size(123.0, 321.0));

    await tester.pump();
    expect(regularChildSize, childSize);
  });

  testWidgets('builder callback is called when OverlayPortal rebuilds', (
    WidgetTester tester,
  ) async {
    late StateSetter setState;
    Color color = const Color(0x12345678);
    late final OverlayEntry overlayEntry;
    addTearDown(
      () => overlayEntry
        ..remove()
        ..dispose(),
    );

    Widget builder(BuildContext _, OverlayChildLayoutInfo _) => ColoredBox(color: color);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            overlayEntry = OverlayEntry(
              builder: (BuildContext context) {
                return StatefulBuilder(
                  builder: (BuildContext context, StateSetter setter) {
                    setState = setter;
                    return OverlayPortal.overlayChildLayoutBuilder(
                      controller: controller1,
                      overlayChildBuilder: builder,
                      child: const SizedBox(),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
    expect(find.byType(ColoredBox), paints..rect(color: color));

    setState(() => color = const Color(0x87654321));
    await tester.pump();
    expect(find.byType(ColoredBox), paints..rect(color: color));
  });

  testWidgets('Positioned works in the builder', (WidgetTester tester) async {
    late final OverlayEntry overlayEntry;
    addTearDown(
      () => overlayEntry
        ..remove()
        ..dispose(),
    );

    final GlobalKey key = GlobalKey();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            overlayEntry = OverlayEntry(
              builder: (BuildContext context) {
                return OverlayPortal.overlayChildLayoutBuilder(
                  controller: controller1,
                  overlayChildBuilder: (_, _) {
                    return Positioned(
                      left: 123.0,
                      top: 37.0,
                      width: 12.0,
                      height: 23.0,
                      child: SizedBox(key: key),
                    );
                  },
                  child: const SizedBox(width: 10.0, height: 20.0),
                );
              },
            ),
          ],
        ),
      ),
    );

    final Rect rect = tester.getRect(find.byKey(key));
    expect(rect, const Rect.fromLTWH(123.0, 37.0, 12.0, 23.0));
  });

  testWidgets('Rebuilds when the layout info changes', (WidgetTester tester) async {
    late StateSetter setState;
    Matrix4 transform = Matrix4.identity();
    late final OverlayEntry overlayEntry;
    addTearDown(
      () => overlayEntry
        ..remove()
        ..dispose(),
    );

    late Matrix4 paintTransform;

    Widget buildOverlayChild(BuildContext context, OverlayChildLayoutInfo layoutInfo) {
      paintTransform = layoutInfo.childPaintTransform;
      return const SizedBox();
    }

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            overlayEntry = OverlayEntry(
              builder: (BuildContext context) {
                return Positioned(
                  left: 10,
                  top: 20,
                  child: StatefulBuilder(
                    builder: (BuildContext context, StateSetter setter) {
                      setState = setter;
                      return Transform(
                        transform: transform,
                        child: OverlayPortal.overlayChildLayoutBuilder(
                          controller: controller1,
                          overlayChildBuilder: buildOverlayChild,
                          child: const SizedBox(width: 40, height: 50),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );

    expect(paintTransform, Matrix4.translationValues(10.0, 20.0, 0.0));
    setState(() => transform = Matrix4.diagonal3Values(2.0, 4.0, 1.0));
    await tester.pump();
    expect(paintTransform, Matrix4.translationValues(10.0, 20.0, 0.0) * transform);
  });

  testWidgets('Still works if child and overlay child are null', (WidgetTester tester) async {
    late final OverlayEntry overlayEntry;
    addTearDown(
      () => overlayEntry
        ..remove()
        ..dispose(),
    );

    late Size regularChildSize;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            overlayEntry = OverlayEntry(
              builder: (BuildContext context) {
                return Positioned(
                  left: 10,
                  top: 20,
                  child: OverlayPortal.overlayChildLayoutBuilder(
                    controller: controller1,
                    overlayChildBuilder: (BuildContext context, OverlayChildLayoutInfo layoutInfo) {
                      regularChildSize = layoutInfo.childSize;
                      return const _NullLeaf();
                    },
                    child: null,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
    expect(regularChildSize, Size.zero);
  });

  testWidgets('Screams if RenderFollower is spotted in path', (WidgetTester tester) async {
    late final OverlayEntry overlayEntry;
    addTearDown(
      () => overlayEntry
        ..remove()
        ..dispose(),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            overlayEntry = OverlayEntry(
              builder: (BuildContext context) {
                return CompositedTransformFollower(
                  link: LayerLink(),
                  child: OverlayPortal.overlayChildLayoutBuilder(
                    controller: controller1,
                    overlayChildBuilder: (_, _) => const SizedBox(),
                    child: null,
                  ),
                );
              },
            ),
          ],
        ),
      ),
      phase: EnginePhase.layout,
    );

    expect(
      tester.takeException(),
      isA<FlutterError>().having(
        (FlutterError error) => error.message,
        'message',
        contains('RenderFollowerLayer'),
      ),
    );
  });
}

class _NullLeaf extends Widget {
  const _NullLeaf();
  @override
  Element createElement() => _NullElement(this);
}

class _NullElement extends Element {
  _NullElement(super.widget);

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    rebuild(force: true);
  }

  @override
  bool get debugDoingBuild => throw UnimplementedError();
}
