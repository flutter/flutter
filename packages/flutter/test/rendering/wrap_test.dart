// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Wrap test; toStringDeep', () {
    final RenderWrap renderWrap = RenderWrap();
    expect(renderWrap, hasAGoodToStringDeep);
    expect(
      renderWrap.toStringDeep(minLevel: DiagnosticLevel.info),
      equalsIgnoringHashCodes(
          'RenderWrap#00000 NEEDS-LAYOUT NEEDS-PAINT DETACHED\n'
          '   parentData: MISSING\n'
          '   constraints: MISSING\n'
          '   size: MISSING\n'
          '   direction: horizontal\n'
          '   alignment: start\n'
          '   spacing: 0.0\n'
          '   runAlignment: start\n'
          '   runSpacing: 0.0\n'
          '   crossAxisAlignment: 0.0\n'),
    );
  });

  test(
    'Compute intrinsic height test',
    () {
      final List<RenderBox> children = <RenderBox>[
        RenderConstrainedBox(
          additionalConstraints:
              const BoxConstraints(minWidth: 80, minHeight: 80),
        ),
        RenderConstrainedBox(
          additionalConstraints:
              const BoxConstraints(minWidth: 80, minHeight: 80),
        ),
        RenderConstrainedBox(
          additionalConstraints:
              const BoxConstraints(minWidth: 80, minHeight: 80),
        ),
      ];

      _intrinsicHeightDefaultTest(children, 245, 165);
      _intrinsicHeightDefaultTest(children, 250, 80);
      _intrinsicHeightDefaultTest(children, 80, 250);
      _intrinsicHeightDefaultTest(children, 79, 250);
      _intrinsicHeightDefaultTest(children, 245, 165, isMax: false);
      _intrinsicHeightDefaultTest(children, 250, 80, isMax: false);
      _intrinsicHeightDefaultTest(children, 80, 250, isMax: false);
      _intrinsicHeightDefaultTest(children, 79, 250, isMax: false);
    },
  );

  test(
    'Compute intrinsic width test',
    () {
      final List<RenderBox> children = <RenderBox>[
        RenderConstrainedBox(
          additionalConstraints:
              const BoxConstraints(minWidth: 80, minHeight: 80),
        ),
        RenderConstrainedBox(
          additionalConstraints:
              const BoxConstraints(minWidth: 80, minHeight: 80),
        ),
        RenderConstrainedBox(
          additionalConstraints:
              const BoxConstraints(minWidth: 80, minHeight: 80),
        ),
      ];

      _intrinsicWidthDefaultTest(children, 245, 165);
      _intrinsicWidthDefaultTest(children, 250, 80);
      _intrinsicWidthDefaultTest(children, 80, 250);
      _intrinsicWidthDefaultTest(children, 79, 250);
      _intrinsicWidthDefaultTest(children, 245, 165, isMax: false);
      _intrinsicWidthDefaultTest(children, 250, 80, isMax: false);
      _intrinsicWidthDefaultTest(children, 80, 250, isMax: false);
      _intrinsicWidthDefaultTest(children, 79, 250, isMax: false);
    },
  );
}

void _intrinsicWidthDefaultTest(
  List<RenderBox> children,
  double availableHeight,
  double expectedWidth, {
  Axis direction = Axis.vertical,
  double spacing = 5.0,
  double runSpacing = 5.0,
  bool isMax = true,
}) {
  final RenderWrap renderWrap = _prepareWrapForComputeIntrinsicSize(
    children,
    spacing: spacing,
    runSpacing: runSpacing,
    direction: direction,
  );
  expect(
    isMax
        ? renderWrap.computeMaxIntrinsicWidth(availableHeight)
        : renderWrap.computeMinIntrinsicWidth(availableHeight),
    equals(expectedWidth),
  );

  // clear for available reuse children in test
  renderWrap.removeAll();
}

void _intrinsicHeightDefaultTest(
  List<RenderBox> children,
  double availableWidth,
  double expectedHeight, {
  Axis direction = Axis.horizontal,
  double spacing = 5.0,
  double runSpacing = 5.0,
  bool isMax = true,
}) {
  final RenderWrap renderWrap = _prepareWrapForComputeIntrinsicSize(
    children,
    spacing: spacing,
    runSpacing: runSpacing,
    direction: direction,
  );
  expect(
    isMax
        ? renderWrap.computeMaxIntrinsicHeight(availableWidth)
        : renderWrap.computeMinIntrinsicHeight(availableWidth),
    equals(expectedHeight),
  );

  // clear for available reuse children in test
  renderWrap.removeAll();
}

RenderWrap _prepareWrapForComputeIntrinsicSize(
  List<RenderBox> children, {
  Axis direction = Axis.horizontal,
  double spacing = 5.0,
  double runSpacing = 5.0,
}) {
  final RenderWrap renderWrap = RenderWrap();

  // ignore: prefer_foreach
  for (final RenderBox child in children) {
    renderWrap.add(child);
  }

  renderWrap.spacing = spacing;
  renderWrap.runSpacing = runSpacing;
  renderWrap.direction = direction;

  return renderWrap;
}
