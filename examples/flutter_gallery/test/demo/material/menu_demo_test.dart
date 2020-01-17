// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_gallery/demo/material/menu_demo.dart';
import 'package:flutter_gallery/gallery/themes.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter/rendering.dart';

void main() {
  testWidgets('Menu icon satisfies accessibility contrast ratio guidelines, light mode', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: kLightGalleryTheme,
      home: const MenuDemo(),
    ));

    await expectLater(tester, meetsGuideline(textContrastGuideline));

    final List<Element> icons = find.byWidgetPredicate((widget) => widget is Icon).evaluate().toList();

    await expectLater(tester, meetsGuideline(CustomContrastGuideline(elements: icons)));
  });

  testWidgets('Menu icon satisfies accessibility contrast ratio guidelines, dark mode', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: kDarkGalleryTheme,
      home: const MenuDemo(),
    ));

    await expectLater(tester, meetsGuideline(textContrastGuideline));

    final List<Element> elements = find.byWidgetPredicate((widget) => widget is Icon).evaluate().toList();

    await expectLater(tester, meetsGuideline(CustomContrastGuideline(elements: elements)));
  });
}

class CustomContrastGuideline extends AccessibilityGuideline {
  const CustomContrastGuideline({@required this.elements});

  static const double kMinimumRatio = 4.5;
  static const double kTolerance = -0.01;

  final List<Element> elements;

  @override
  Future<Evaluation> evaluate(WidgetTester tester) async {
    // Obtain rendered image.

    final RenderView renderView = tester.binding.renderView;
    final OffsetLayer layer = renderView.debugLayer as OffsetLayer;
    ui.Image image;
    final ByteData byteData = await tester.binding.runAsync<ByteData>(() async {
      // Needs to be the same pixel ratio otherwise our dimensions won't match the
      // last transform layer.
      image = await layer.toImage(renderView.paintBounds, pixelRatio: 1 / tester.binding.window.devicePixelRatio);
      return image.toByteData();
    });

    // How to evaluate a single element.

    Evaluation evaluateElement(Element element) {
      final RenderBox renderObject = element.renderObject as RenderBox;

      final Rect originalPaintBounds = renderObject.paintBounds;

      final Rect inflatedPaintBounds = originalPaintBounds.inflate(4.0);

      final Rect paintBounds = Rect.fromPoints(
        renderObject.localToGlobal(inflatedPaintBounds.topLeft),
        renderObject.localToGlobal(inflatedPaintBounds.bottomRight),
      );

      final List<int> subset = _subsetFromRect(byteData, paintBounds, image.width, image.height);

      if (subset.isEmpty) {
        return const Evaluation.pass();
      }

      final ContrastReport report = ContrastReport(subset);
      final double contrastRatio = report.contrastRatio();

      if (contrastRatio - kMinimumRatio >= kTolerance) {
        return const Evaluation.pass();
      } else {
        return Evaluation.fail(
            '$element:\nExpected contrast ratio of at least '
            '$kMinimumRatio but found ${contrastRatio.toStringAsFixed(2)} \n'
            'The computed light color was: ${report.lightColor}, '
            'The computed dark color was: ${report.darkColor}\n'
            'See also: https://www.w3.org/TR/UNDERSTANDING-WCAG20/visual-audio-contrast-contrast.html\n'
        );
      }
    }

    // Collate all evaluations into a final evaluation, then return.

    Evaluation result = const Evaluation.pass();

    for (final Element element in elements) {
      result = result + evaluateElement(element);
    }

    return result;
  }

  List<int> _subsetFromRect(ByteData data, Rect paintBounds, int width, int height) {
    final Rect truePaintBounds = paintBounds.intersect(
      Rect.fromLTWH(0.0, 0.0, width.toDouble(), height.toDouble()),
    );

    final int leftX   = truePaintBounds.left.floor();
    final int rightX  = truePaintBounds.right.ceil();
    final int topY    = truePaintBounds.top.floor();
    final int bottomY = truePaintBounds.bottom.ceil();

    final List<int> buffer = <int>[];

    int _getPixel(ByteData data, int x, int y) {
      final int offset = (y * width + x) * 4;
      final int r = data.getUint8(offset);
      final int g = data.getUint8(offset + 1);
      final int b = data.getUint8(offset + 2);
      final int a = data.getUint8(offset + 3);
      final int color = (((a & 0xff) << 24) |
                         ((r & 0xff) << 16) |
                         ((g & 0xff) << 8)  |
                         ((b & 0xff) << 0)) & 0xFFFFFFFF;
      return color;
    }

    for (int x = leftX; x < rightX; x ++) {
      for (int y = topY; y < bottomY; y ++) {
        buffer.add(_getPixel(data, x, y));
      }
    }

    return buffer;
  }

  @override
  String get description => 'Contrast should follow WCAG guidelines';
}
