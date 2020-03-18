// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: deprecated_member_use_from_same_package
// The tests for layers will be removed after deprecation https://flutter.dev/go/annotator-tree

import 'dart:ui' show window;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('provides a value to the annotation tree in a particular region', (WidgetTester tester) async {
    await tester.pumpWidget(
      Container(
        alignment: Alignment.topLeft,
        child: Transform.translate(
          offset: const Offset(50, 50),
          child: const AnnotatedRegion<int>(
            child: SizedBox(width: 10, height: 10),
            value: 1,
          ),
        ),
      ),
    );
    AnnotationResult<int> result = RendererBinding.instance.renderView.search<int>(const Offset(10.0, 10.0));
    expect(result, isNotNull);
    expect(result.entries, hasLength(0));
    result = RendererBinding.instance.renderView.search<int>(const Offset(55.0, 55.0));
    expect(result, isNotNull);
    expect(result.entries, hasLength(1));
    expect(result.entries.toList()[0], const AnnotationEntry<int>(annotation: 1, localPosition: Offset(5, 5)));
  });
  testWidgets('provides correct localPosition when nested', (WidgetTester tester) async {
    await tester.pumpWidget(
      Container(
        alignment: Alignment.topLeft,
        child: Transform.translate(
          offset: const Offset(20.0, 20.0),
          child: AnnotatedRegion<int>(
            value: 1,
            child: Transform.translate(
              offset: const Offset(20.0, 20.0),
              child: const AnnotatedRegion<int>(
                value: 2,
                child: SizedBox(width: 100.0, height: 100.0),
              ),
            ),
          ),
        ),
      ),
    );
    final AnnotationResult<int> result = RendererBinding.instance.renderView.search<int>(const Offset(100.0, 100.0));
    expect(result, isNotNull);
    expect(result.entries, hasLength(2));
    expect(result.entries.toList()[0], const AnnotationEntry<int>(annotation: 2, localPosition: Offset(60, 60)));
    expect(result.entries.toList()[1], const AnnotationEntry<int>(annotation: 1, localPosition: Offset(80, 80)));
  });


  testWidgets('provides a value to the layer tree', (WidgetTester tester) async {
    await tester.pumpWidget(
      const AnnotatedRegion<int>(
        child: SizedBox(width: 100.0, height: 100.0),
        value: 1,
      ),
    );
    final List<Layer> layers = tester.layers;
    final AnnotatedRegionLayer<int> layer = layers.whereType<AnnotatedRegionLayer<int>>().first;
    expect(layer.value, 1);
  });
  testWidgets('provides a value to the layer tree in a particular region', (WidgetTester tester) async {
    await tester.pumpWidget(
      Transform.translate(
        offset: const Offset(25.0, 25.0),
        child: const AnnotatedRegion<int>(
          child: SizedBox(width: 100.0, height: 100.0),
          value: 1,
        ),
      ),
    );
    int result = RendererBinding.instance.renderView.debugLayer.find<int>(Offset(
      10.0 * window.devicePixelRatio,
      10.0 * window.devicePixelRatio,
    ));
    expect(result, null);
    result = RendererBinding.instance.renderView.debugLayer.find<int>(Offset(
      50.0 * window.devicePixelRatio,
      50.0 * window.devicePixelRatio,
    ));
    expect(result, 1);
  });
}
