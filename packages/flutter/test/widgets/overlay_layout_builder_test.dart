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
    addTearDown(
      () =>
          overlayEntry
            ..remove()
            ..dispose(),
    );

    late Matrix4 paintTransform;
    late Size regularChildSize;
    late Rect regularChildInTheater;
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
                        child: OverlayPortal.nameTBD(
                          controller: controller1,
                          overlayChildBuilder: (
                            BuildContext context,
                            Size childSize,
                            Matrix4 transform,
                            Size theater,
                          ) {
                            paintTransform = transform;
                            regularChildSize = childSize;
                            regularChildInTheater = MatrixUtils.transformRect(
                              paintTransform,
                              Offset.zero & childSize,
                            );
                            theaterSize = theater;
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
    expect(tester.binding.hasScheduledFrame, isFalse);
    print(regularChildSize);
    print(regularChildInTheater);
    print(theaterSize);

    setState(() => transform = Matrix4.diagonal3Values(2.0, 2.0, 1.0));
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump();
  });

  testWidgets('Still works if child is null', (WidgetTester tester) async {
    late final OverlayEntry overlayEntry;
    addTearDown(
      () =>
          overlayEntry
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
                  child: OverlayPortal.nameTBD(
                    controller: controller1,
                    overlayChildBuilder: (
                      BuildContext context,
                      Size childSize,
                      Matrix4 transform,
                      Size theaterSize,
                    ) {
                      regularChildSize = childSize;
                      return const SizedBox();
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
}
