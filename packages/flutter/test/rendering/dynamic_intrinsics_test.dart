// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rendering_tester.dart';

class RenderFixedSize extends RenderBox {
  double dimension = 100.0;

  void grow() {
    dimension *= 2.0;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicWidth(final double height) => dimension;
  @override
  double computeMaxIntrinsicWidth(final double height) => dimension;
  @override
  double computeMinIntrinsicHeight(final double width) => dimension;
  @override
  double computeMaxIntrinsicHeight(final double width) => dimension;

  @override
  void performLayout() {
    size = Size.square(dimension);
  }
}

class RenderParentSize extends RenderProxyBox {
  RenderParentSize({ required final RenderBox child }) : super(child);

  @override
  bool get sizedByParent => true;

  @override
  void performResize() {
    size = constraints.biggest;
  }

  @override
  void performLayout() {
    child!.layout(constraints);
  }
}

class RenderIntrinsicSize extends RenderProxyBox {
  RenderIntrinsicSize({ required final RenderBox child }) : super(child);

  @override
  void performLayout() {
    child!.layout(constraints);
    size = Size(
      child!.getMinIntrinsicWidth(double.infinity),
      child!.getMinIntrinsicHeight(double.infinity),
    );
  }
}

class RenderInvalidIntrinsics extends RenderBox {
  @override
  bool get sizedByParent => true;
  @override
  double computeMinIntrinsicWidth(final double height) => -1;
  @override
  double computeMaxIntrinsicWidth(final double height) => -1;
  @override
  double computeMinIntrinsicHeight(final double width) => -1;
  @override
  double computeMaxIntrinsicHeight(final double width) => -1;
  @override
  Size computeDryLayout(final BoxConstraints constraints) => Size.zero;
}

void main() {
  TestRenderingFlutterBinding.ensureInitialized();

  test('Whether using intrinsics means you get hooked into layout', () {
    RenderBox root;
    RenderFixedSize inner;
    layout(
      root = RenderIntrinsicSize(
        child: RenderParentSize(
          child: inner = RenderFixedSize(),
        ),
      ),
      constraints: const BoxConstraints(
        maxWidth: 1000.0,
        maxHeight: 1000.0,
      ),
    );
    expect(root.size, equals(inner.size));

    inner.grow();
    pumpFrame();
    expect(root.size, equals(inner.size));
  });

  test('Parent returns correct intrinsics', () {
    RenderParentSize parent;
    RenderFixedSize inner;

    layout(
      RenderIntrinsicSize(
        child: parent = RenderParentSize(
          child: inner = RenderFixedSize(),
        ),
      ),
      constraints: const BoxConstraints(
        maxWidth: 1000.0,
        maxHeight: 1000.0,
      ),
    );

    _expectIntrinsicDimensions(parent, 100);

    inner.grow();
    pumpFrame();

    _expectIntrinsicDimensions(parent, 200);
  });

  test('Intrinsic checks are turned on', () async {
    final List<FlutterErrorDetails> errorDetails = <FlutterErrorDetails>[];
    layout(
      RenderInvalidIntrinsics(),
      constraints: const BoxConstraints(
        maxWidth: 1000.0,
        maxHeight: 1000.0,
      ),
      onErrors: () {
        errorDetails.addAll(TestRenderingFlutterBinding.instance.takeAllFlutterErrorDetails());
      },
    );

    expect(errorDetails, isNotEmpty);
    expect(
      errorDetails.map((final FlutterErrorDetails details) => details.toString()),
      everyElement(contains('violate the intrinsic protocol')),
    );
  });
}

/// Asserts that all unbounded intrinsic dimensions for [object] match
/// [dimension].
void _expectIntrinsicDimensions(final RenderBox object, final double dimension) {
  expect(object.getMinIntrinsicWidth(double.infinity), equals(dimension));
  expect(object.getMaxIntrinsicWidth(double.infinity), equals(dimension));
  expect(object.getMinIntrinsicHeight(double.infinity), equals(dimension));
  expect(object.getMaxIntrinsicHeight(double.infinity), equals(dimension));
}
