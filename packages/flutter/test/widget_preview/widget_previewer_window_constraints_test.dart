// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/src/widget_preview/widget_preview.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WidgetPreviewerWindowConstraints', () {
    testWidgets(
      'propagates constraints to descendants',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          LayoutBuilder(
            builder: (_, BoxConstraints constraints) {
              return WidgetPreviewerWindowConstraints(
                constraints: constraints,
                child: Builder(
                  builder: (BuildContext context) {
                    final BoxConstraints propagatedConstraints =
                        WidgetPreviewerWindowConstraints.getRootConstraints(
                      context,
                    );
                    expect(propagatedConstraints, constraints);
                    return Container();
                  },
                ),
              );
            },
          ),
        );
      },
    );

    testWidgets(
      'applies constraints to WidgetPreview with single unconstrained child',
      (WidgetTester tester) async {
        late BoxConstraints previewWindowConstraints;
        await tester.pumpWidget(
          MaterialApp(
            home: LayoutBuilder(
              builder: (_, BoxConstraints constraints) {
                previewWindowConstraints = constraints;
                return WidgetPreviewerWindowConstraints(
                  constraints: constraints,
                  child: WidgetPreview(
                    child: ListView(
                      children: <Widget>[
                        for (int i = 0; i < 10000; ++i) Text(i.toString()),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
        final Size previewerSize = tester.getSize(
          find.byType(WidgetPreviewerWindowConstraints),
        );
        expect(previewWindowConstraints.maxHeight, previewerSize.height);
        expect(previewWindowConstraints.maxWidth, previewerSize.width);

        // WidgetPreviewWrapper will forcefully apply constraints on the height
        // of an unconstrained child, forcing the child to be at most the
        // height of the constraints provided by
        // [WidgetPreviewerWindowConstraints] scaled by
        // [WidgetPreviewWrapper.unconstrainedChildScalingRatio].
        final Size wrapperSize = tester.getSize(
          find.byType(WidgetPreviewWrapper),
        );
        expect(
          wrapperSize.height,
          previewerSize.height *
              WidgetPreviewWrapper.unconstrainedChildScalingRatio,
        );
      },
    );

    testWidgets(
      'applies constraints to WidgetPreview with multiple unconstrained children',
      (WidgetTester tester) async {
        late BoxConstraints previewWindowConstraints;
        await tester.pumpWidget(
          MaterialApp(
            home: LayoutBuilder(
              builder: (_, BoxConstraints constraints) {
                previewWindowConstraints = constraints;
                return WidgetPreviewerWindowConstraints(
                  constraints: constraints,
                  child: SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        for (int i = 0; i < 10; ++i)
                          WidgetPreview(
                            child: ListView(
                              children: <Widget>[
                                for (int i = 0; i < 10000; ++i)
                                  Text(i.toString()),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
        final Size previewerSize = tester.getSize(
          find.byType(WidgetPreviewerWindowConstraints),
        );
        expect(previewWindowConstraints.maxHeight, previewerSize.height);
        expect(previewWindowConstraints.maxWidth, previewerSize.width);

        // WidgetPreviewWrapper will forcefully apply constraints on the height
        // of an unconstrained child, forcing the child to be at most the
        // height of the constraints provided by
        // [WidgetPreviewerWindowConstraints] scaled by
        // [WidgetPreviewWrapper.unconstrainedChildScalingRatio].
        //
        // This constraint should be applied to all [WidgetPreview] children
        // of [WidgetPreviewerWindowConstraints] whether or not they are not on
        // screen.
        final FinderResult<Element> previewWrappers = find.byType(WidgetPreviewWrapper).evaluate();
        for (final Element element in previewWrappers) {
          final Size wrapperSize = element.size!;
          expect(
            wrapperSize.height,
            previewerSize.height *
                WidgetPreviewWrapper.unconstrainedChildScalingRatio,
          );
        }
      },
    );
  });
}
