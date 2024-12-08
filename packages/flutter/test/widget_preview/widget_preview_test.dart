// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/src/widget_preview/widget_preview.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils.dart';

void main() {
  group('WidgetPreview', () {
    testWidgets(
      'constrained child with no additional constraints',
      (WidgetTester tester) async {
        const Key boxKey = Key('boxKey');
        const Size boxSize = Size(100, 100);
        await tester.pumpWidget(
          WidgetPreviewTestScaffolding(
            previews: <WidgetPreview>[
              WidgetPreview(
                child: SizedBox.fromSize(
                  key: boxKey,
                  size: boxSize,
                ),
              ),
            ],
          ),
        );

        // Verify that the WidgetPreview could take up more space than the
        // constraints specified by boxSize.
        final Size widgetPreviewSize = tester.getSize(
          find.byType(WidgetPreview),
        );
        expect(widgetPreviewSize, greaterThan(boxSize));

        // Retrieve the size of the SizedBox child of the WidgetPreview. The
        // box should take up the size it requests as long as it's less than
        // the environment's size.
        final Size actualBoxSize = tester.getSize(find.byKey(boxKey));
        expect(actualBoxSize, boxSize);
      },
    );

    testWidgets(
      'constrained child respects height and width constraints',
      (WidgetTester tester) async {
        const Key boxKey = Key('boxKey');
        const Size artificialConstraints = Size(100, 100);
        await tester.pumpWidget(
          WidgetPreviewTestScaffolding(
            previews: <WidgetPreview>[
              WidgetPreview(
                height: artificialConstraints.height,
                width: artificialConstraints.width,
                child: SizedBox.fromSize(
                  key: boxKey,
                  size: artificialConstraints * 2,
                ),
              ),
            ],
          ),
        );

        // Verify that the WidgetPreview could take up more space than the
        // constraints specified by artificialConstraints.
        final Size widgetPreviewSize = tester.getSize(
          find.byType(WidgetPreview),
        );
        expect(widgetPreviewSize, greaterThan(artificialConstraints));

        // Retrieve the size of the SizedBox child of the WidgetPreview. The
        // box wants to take up 2x the size specified by artificialConstraints
        // but the WidgetPreview constrains the box to artificalConstraints.
        final Size boxSize = tester.getSize(find.byKey(boxKey));
        expect(boxSize, artificialConstraints);
      },
    );

    testWidgets(
      'unconstrained child respects height and width constraints',
      (WidgetTester tester) async {
        const Key listKey = Key('listKey');
        const Size artificialConstraints = Size(100, 100);
        await tester.pumpWidget(
          WidgetPreviewTestScaffolding(
            previews: <WidgetPreview>[
              WidgetPreview(
                height: artificialConstraints.height,
                width: artificialConstraints.width,
                child: ListView(
                  key: listKey,
                  children: <Widget>[
                    for (int i = 0; i < 10000; ++i) Text(i.toString()),
                  ],
                ),
              ),
            ],
          ),
        );

        // Verify that the WidgetPreview could take up more space than the
        // constraints specified by artificialConstraints.
        final Size widgetPreviewSize = tester.getSize(
          find.byType(WidgetPreview),
        );
        expect(widgetPreviewSize, greaterThan(artificialConstraints));

        // Retrieve the size of the ListView child of the WidgetPreview. The
        // list wants to take up 2x the size specified by artificialConstraints
        // but the WidgetPreview constrains the list to artificalConstraints.
        final Size listSize = tester.getSize(find.byKey(listKey));
        expect(listSize, artificialConstraints);
      },
    );

    testWidgets(
      'unconstrained child with width constraints',
      (WidgetTester tester) async {
        const Key listKey = Key('listKey');
        const Size artificialConstraints = Size(100, 0);
        await tester.pumpWidget(
          WidgetPreviewTestScaffolding(
            previews: <WidgetPreview>[
              WidgetPreview(
                width: artificialConstraints.width,
                child: ListView(
                  key: listKey,
                  children: <Widget>[
                    for (int i = 0; i < 10000; ++i) Text(i.toString()),
                  ],
                ),
              ),
            ],
          ),
        );

        // Verify that the environment is at least as big as the WidgetPreview
        // and the preview is at least as wide as the artificial width.
        final Size environmentSize = tester.getSize(
          find.byType(WidgetPreviewTestScaffolding),
        );
        final Size widgetPreviewSize = tester.getSize(
          find.byType(WidgetPreview),
        );
        expect(environmentSize, greaterThanOrEqualTo(widgetPreviewSize));
        expect(
          widgetPreviewSize.width,
          greaterThan(artificialConstraints.width),
        );

        // Retrieve the size of the ListView child of the WidgetPreview. The
        // list is vertically unconstrained but has horizontal constraints,
        // so the WidgetPreview should apply artifical constraints to the
        // list's height equal to the overall environment height scaled by some
        // known factor while also applying the specified horizontal
        // constraints.
        final Size listSize = tester.getSize(find.byKey(listKey));
        expect(
          listSize.height,
          environmentSize.height *
              WidgetPreviewWrapper.unconstrainedChildScalingRatio,
        );
        expect(listSize.width, artificialConstraints.width);
      },
    );

    testWidgets(
      'applies artificial text scaling factor',
      (WidgetTester tester) async {
        for (final double scaleFactor in <double>[1, 2, 5, 10]) {
          await tester.pumpWidget(
            Builder(
              builder: (BuildContext context) {
                // Text scaling shouldn't be applied at the root of the widget
                // tree.
                final MediaQueryData mediaQuery = MediaQuery.of(context);
                expect(mediaQuery.textScaler, TextScaler.noScaling);

                return WidgetPreviewTestScaffolding(
                  // Ensure that multiple WidgetPreview instances can have
                  // different text scaling factors in the same widget tree.
                  previews: <WidgetPreview>[
                    WidgetPreview(
                      textScaleFactor: scaleFactor,
                      child: Builder(
                        builder: (BuildContext context) {
                          final MediaQueryData mediaQuery =
                              MediaQuery.of(context);
                          expect(
                            mediaQuery.textScaler,
                            TextScaler.linear(scaleFactor),
                          );
                          return Container();
                        },
                      ),
                    ),
                    WidgetPreview(
                      textScaleFactor: scaleFactor * 2,
                      child: Builder(
                        builder: (BuildContext context) {
                          final MediaQueryData mediaQuery =
                              MediaQuery.of(context);
                          expect(
                            mediaQuery.textScaler,
                            TextScaler.linear(scaleFactor * 2),
                          );
                          return Container();
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        }
      },
    );

    testWidgets(
      'applies artificial device size',
      (WidgetTester tester) async {
        final Size viewSize =
            tester.view.physicalSize / tester.view.devicePixelRatio;
        const Size size = Size(100, 100);

        await tester.pumpWidget(
          Builder(
            builder: (BuildContext context) {
              // The size returned by MediaQuery should match that of the view.
              final MediaQueryData mediaQuery = MediaQuery.of(context);
              expect(mediaQuery.size, viewSize);

              return WidgetPreviewTestScaffolding(
                // Ensure that multiple WidgetPreview instances can have
                // different MediaQuery sizes in the same widget tree. The size
                // reported by MediaQuery should match the size of the
                // dimensions provided.
                previews: <WidgetPreview>[
                  // If both width and height and provided, the width and
                  // height of the WidgetPreview are reported by MediaQuery.
                  WidgetPreview(
                    height: size.height,
                    width: size.width,
                    child: Builder(
                      builder: (BuildContext context) {
                        final MediaQueryData mediaQuery =
                            MediaQuery.of(context);
                        expect(mediaQuery.size, size);
                        return Container();
                      },
                    ),
                  ),
                  // If no width is provided, the width of the view is reported.
                  WidgetPreview(
                    height: size.height,
                    child: Builder(
                      builder: (BuildContext context) {
                        final MediaQueryData mediaQuery =
                            MediaQuery.of(context);
                        expect(
                          mediaQuery.size,
                          Size(viewSize.width, size.height),
                        );
                        return Container();
                      },
                    ),
                  ),
                  // If no height is provided, the height of the view is reported.
                  WidgetPreview(
                    width: size.width,
                    child: Builder(
                      builder: (BuildContext context) {
                        final MediaQueryData mediaQuery =
                            MediaQuery.of(context);
                        expect(
                          mediaQuery.size,
                          Size(size.width, viewSize.height),
                        );
                        return Container();
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  });
}
