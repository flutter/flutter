// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rendering_tester.dart';

void main() {
  TestRenderingFlutterBinding.ensureInitialized();

  // Create non-const instances, otherwise tests pass even if the
  // operator override is incorrect.
  ViewConfiguration createViewConfiguration({
    Size size = const Size(20, 20),
    double devicePixelRatio = 2.0,
  }) {
    return ViewConfiguration(size: size, devicePixelRatio: devicePixelRatio);
  }

  group('RenderView', () {
    test('accounts for device pixel ratio in paintBounds', () {
      layout(RenderAspectRatio(aspectRatio: 1.0));
      pumpFrame();
      final Size logicalSize = TestRenderingFlutterBinding.instance.renderView.configuration.size;
      final double devicePixelRatio = TestRenderingFlutterBinding.instance.renderView.configuration.devicePixelRatio;
      final Size physicalSize = logicalSize * devicePixelRatio;
      expect(TestRenderingFlutterBinding.instance.renderView.paintBounds, Offset.zero & physicalSize);
    });

    test('does not replace the root layer unnecessarily', () {
      final RenderView view = RenderView(
        configuration: createViewConfiguration(),
        view: RendererBinding.instance.platformDispatcher.views.single,
      );
      final PipelineOwner owner = PipelineOwner();
      view.attach(owner);
      view.prepareInitialFrame();
      final ContainerLayer firstLayer = view.debugLayer!;
      view.configuration = createViewConfiguration();
      expect(identical(view.debugLayer, firstLayer), true);

      view.configuration = createViewConfiguration(devicePixelRatio: 5.0);
      expect(identical(view.debugLayer, firstLayer), false);
    });

    test('does not replace the root layer unnecessarily when view resizes', () {
      final RenderView view = RenderView(
        configuration: createViewConfiguration(size: const Size(100.0, 100.0)),
        view: RendererBinding.instance.platformDispatcher.views.single,
      );
      final PipelineOwner owner = PipelineOwner();
      view.attach(owner);
      view.prepareInitialFrame();
      final ContainerLayer firstLayer = view.debugLayer!;
      view.configuration = createViewConfiguration(size: const Size(100.0, 1117.0));
      expect(identical(view.debugLayer, firstLayer), true);
    });
  });

  test('ViewConfiguration == and hashCode', () {
    final ViewConfiguration viewConfigurationA = createViewConfiguration();
    final ViewConfiguration viewConfigurationB = createViewConfiguration();
    final ViewConfiguration viewConfigurationC = createViewConfiguration(devicePixelRatio: 3.0);

    expect(viewConfigurationA == viewConfigurationB, true);
    expect(viewConfigurationA != viewConfigurationC, true);
    expect(viewConfigurationA.hashCode, viewConfigurationB.hashCode);
    expect(viewConfigurationA.hashCode != viewConfigurationC.hashCode, true);
  });

  test('invokes DebugPaintCallback', () {
    final PaintPattern paintsOrangeRect = paints..rect(
      color: orange,
      rect: orangeRect,
    );
    final PaintPattern paintsGreenRect = paints..rect(
      color: green,
      rect: greenRect,
    );
    final PaintPattern paintOrangeAndGreenRect = paints
      ..rect(
        color: orange,
        rect: orangeRect,
      )
      ..rect(
        color: green,
        rect: greenRect,
      );
    void paintCallback(PaintingContext context, Offset offset, RenderView renderView) {
      context.canvas.drawRect(
        greenRect,
        Paint()..color = green,
      );
    }

    layout(TestRenderObject());
    expect(
      TestRenderingFlutterBinding.instance.renderView,
      paintsOrangeRect,
    );
    expect(
      TestRenderingFlutterBinding.instance.renderView,
      isNot(paintsGreenRect),
    );

    RenderView.debugAddPaintCallback(paintCallback);
    expect(
      TestRenderingFlutterBinding.instance.renderView,
      paintOrangeAndGreenRect,
    );

    RenderView.debugRemovePaintCallback(paintCallback);
    expect(
      TestRenderingFlutterBinding.instance.renderView,
      paintsOrangeRect,
    );
    expect(
      TestRenderingFlutterBinding.instance.renderView,
      isNot(paintsGreenRect),
    );
  });

  test('Config can be set and changed after instantiation without calling prepareInitialFrame first', () {
    final RenderView view = RenderView(
      view: RendererBinding.instance.platformDispatcher.views.single,
    );
    view.configuration = const ViewConfiguration(size: Size(100, 200), devicePixelRatio: 3.0);
    view.configuration = const ViewConfiguration(size: Size(200, 300), devicePixelRatio: 2.0);
    PipelineOwner().rootNode = view;
    view.prepareInitialFrame();
  });
}

const Color orange = Color(0xFFFF9000);
const Color green = Color(0xFF0FF900);
const Rect orangeRect = Rect.fromLTWH(10, 10, 50, 75);
const Rect greenRect = Rect.fromLTWH(20, 20, 100, 150);

class TestRenderObject extends RenderBox {
  @override
  void performLayout() {
    size = constraints.biggest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context.canvas.drawRect(
      orangeRect,
      Paint()..color = orange,
    );
  }
}
