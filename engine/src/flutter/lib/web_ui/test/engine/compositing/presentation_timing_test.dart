// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

import '../../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  setUpUnitTests();

  for (final enabled in <bool>[true, false]) {
    test('presentation timing waits for preparation and rasterization ($enabled)', () async {
      final bool previousBenchmarkMode = Profiler.isBenchmarkMode;
      final ui_web.BenchmarkValueCallback? previousCallback = engineBenchmarkValueCallback;
      final values = <double>[];
      final view = EngineFlutterView(EnginePlatformDispatcher.instance, createDomHTMLDivElement());
      view.debugPhysicalSizeOverride = const ui.Size(64, 48);
      view.debugForceResize();
      final rasterizer = _ProfileViewRasterizer(view);
      final scene = ui.SceneBuilder().build() as LayerScene;
      try {
        Profiler.isBenchmarkMode = enabled;
        if (enabled) {
          Profiler.ensureInitialized();
        }
        ui_web.benchmarkValueCallback = (String name, double value) {
          if (name == 'presentation_duration') {
            values.add(value);
          }
        };
        final Future<void> draw = rasterizer.draw(scene.layerTree, null);
        await rasterizer.preparing.future;
        expect(values, isEmpty);
        rasterizer.prepared.complete();
        await rasterizer.rasterizing.future;
        expect(values, isEmpty);
        rasterizer.rasterized.complete();
        await draw;
        expect(values, hasLength(enabled ? 1 : 0));
        if (enabled) {
          expect(values.single, greaterThanOrEqualTo(0));
        }
      } finally {
        scene.dispose();
        rasterizer.dispose();
        view.dispose();
        ui_web.benchmarkValueCallback = previousCallback;
        Profiler.isBenchmarkMode = previousBenchmarkMode;
      }
    });
  }
}

class _ProfileViewRasterizer extends ViewRasterizer {
  _ProfileViewRasterizer(super.view);
  final preparing = Completer<void>();
  final prepared = Completer<void>();
  final rasterizing = Completer<void>();
  final rasterized = Completer<void>();

  @override
  final displayFactory = DisplayCanvasFactory<RenderCanvas>(createCanvas: RenderCanvas.new);

  @override
  Future<void> prepareToDraw() {
    preparing.complete();
    return prepared.future;
  }

  @override
  Future<void> rasterize(
    List<DisplayCanvas> canvases,
    List<ui.Picture> pictures,
    FrameTimingRecorder? recorder,
  ) {
    rasterizing.complete();
    return rasterized.future;
  }
}
