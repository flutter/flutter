// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart';
import 'package:ui/ui.dart' as ui;

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  for (final failAcquire in <bool>[true, false]) {
    test('context recovery failure completes rendering with an error ($failAcquire)', () async {
      final provider = _FailingCanvasProvider();
      final surface = _FailingRecoverySurface(provider);
      final ui.Picture picture = _solidPicture(const ui.Color(0xFF00FF00));
      try {
        await surface.initialized;
        provider.fail = failAcquire;
        surface.fail = !failAcquire;
        await surface.triggerContextLoss();
        await surface.handledContextLossEvent;
        await expectLater(surface.initialized, throwsStateError);
        await expectLater(surface.rasterizeToCanvas(picture), throwsStateError);
      } finally {
        picture.dispose();
        surface.dispose();
        provider.dispose();
      }
    }, timeout: const Timeout(Duration(seconds: 10)));
  }

  test('reuses a picture-to-image result across two onscreen contexts and resize', () async {
    final provider = OnscreenCanvasProvider();
    final surfaces = <SkwasmOnscreenSurface>[
      SkwasmOnscreenSurface(provider),
      SkwasmOnscreenSurface(provider),
    ];
    final ui.Picture source = _solidPicture(const ui.Color(0xFF00FF00));
    final ui.Image image = await source.toImage(2, 2);
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawImage(image, ui.Offset.zero, ui.Paint());
    final ui.Picture picture = recorder.endRecording();
    try {
      for (final surface in surfaces) {
        domDocument.body!.append(surface.hostElement);
        await surface.initialized;
      }
      for (final size in <BitmapSize>[
        const BitmapSize(2, 2),
        const BitmapSize(128, 96),
        const BitmapSize(2, 2),
      ]) {
        for (final surface in surfaces) {
          await surface.setSize(size);
          await surface.rasterizeToCanvas(picture);
          await _expectOnscreenPixels(surface, <int>[
            for (var pixel = 0; pixel < 4; pixel++) ...<int>[0, 255, 0, 255],
          ]);
        }
      }
    } finally {
      picture.dispose();
      image.dispose();
      source.dispose();
      for (final surface in surfaces) {
        surface.dispose();
        surface.hostElement.remove();
      }
      provider.dispose();
    }
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('multiple surfaces can complete overlapping callbacks', () async {
    final canvasProvider = OnscreenCanvasProvider();
    final first = SkwasmOnscreenSurface(canvasProvider);
    final second = SkwasmOnscreenSurface(canvasProvider);
    ui.Picture? picture;
    try {
      await Future.wait<void>(<Future<void>>[first.initialized, second.initialized])
          .timeout(const Duration(seconds: 10));
      await Future.wait<void>(<Future<void>>[
        first.setSize(const BitmapSize(64, 64)),
        second.setSize(const BitmapSize(64, 64)),
      ]).timeout(const Duration(seconds: 10));

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawColor(const ui.Color(0xFF00FF00), ui.BlendMode.src);
      picture = recorder.endRecording();
      await Future.wait<void>(<Future<void>>[
        first.rasterizeToCanvas(picture),
        second.rasterizeToCanvas(picture),
      ]).timeout(const Duration(seconds: 10));
    } finally {
      picture?.dispose();
      first.dispose();
      second.dispose();
      canvasProvider.dispose();
    }
  }, timeout: const Timeout(Duration(minutes: 1)));

  test('onscreen surface positions overlays without moving the base canvas', () async {
    final canvasProvider = OnscreenCanvasProvider();
    final surface = SkwasmOnscreenSurface(canvasProvider);
    try {
      await surface.initialized.timeout(const Duration(seconds: 10));
      final canvas = surface.hostElement.children.single as DomHTMLCanvasElement;
      expect(canvas.style.position, isNot('absolute'));

      surface.setIsOverlay(true);
      expect(canvas.style.position, 'absolute');

      surface.setIsOverlay(false);
      expect(canvas.style.position, isNot('absolute'));
    } finally {
      surface.dispose();
      canvasProvider.dispose();
    }
  }, timeout: const Timeout(Duration(minutes: 1)));

  test('onscreen surface recreates context and keeps pixels after loss', () async {
    final canvasProvider = OnscreenCanvasProvider();
    final surface = SkwasmOnscreenSurface(canvasProvider);
    domDocument.body!.append(surface.hostElement);
    ui.Picture? picture;
    try {
      await surface.initialized.timeout(const Duration(seconds: 10));
      await surface.setSize(const BitmapSize(2, 2)).timeout(const Duration(seconds: 10));
      final int initialGlContext = surface.glContext;
      surface.setIsOverlay(true);
      var canvas = surface.hostElement.children.single as DomHTMLCanvasElement;
      expect(canvas.style.position, 'absolute');

      picture = _solidPicture(const ui.Color(0xFFFF0000));
      await surface.rasterizeToCanvas(picture).timeout(const Duration(seconds: 10));
      await _expectOnscreenPixels(surface, <int>[
        0xFF,
        0x00,
        0x00,
        0xFF,
        0xFF,
        0x00,
        0x00,
        0xFF,
        0xFF,
        0x00,
        0x00,
        0xFF,
        0xFF,
        0x00,
        0x00,
        0xFF,
      ]);

      await surface.triggerContextLoss().timeout(const Duration(seconds: 10));
      await surface.handledContextLossEvent.timeout(const Duration(seconds: 10));
      await surface.initialized.timeout(const Duration(seconds: 10));
      expect(surface.glContext, isNot(initialGlContext));
      canvas = surface.hostElement.children.single as DomHTMLCanvasElement;
      expect(canvas.style.position, 'absolute');
      surface.setIsOverlay(false);
      expect(canvas.style.position, isNot('absolute'));

      picture.dispose();
      picture = _solidPicture(const ui.Color(0xFF0000FF));
      await surface.rasterizeToCanvas(picture).timeout(const Duration(seconds: 10));
      await _expectOnscreenPixels(surface, <int>[
        0x00,
        0x00,
        0xFF,
        0xFF,
        0x00,
        0x00,
        0xFF,
        0xFF,
        0x00,
        0x00,
        0xFF,
        0xFF,
        0x00,
        0x00,
        0xFF,
        0xFF,
      ]);
    } finally {
      picture?.dispose();
      surface.dispose();
      surface.hostElement.remove();
      canvasProvider.dispose();
    }
  }, timeout: const Timeout(Duration(minutes: 1)));
}

ui.Picture _solidPicture(ui.Color color) {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder, const ui.Rect.fromLTWH(0, 0, 2, 2));
  canvas.drawColor(color, ui.BlendMode.src);
  return recorder.endRecording();
}

Future<void> _expectOnscreenPixels(SkwasmOnscreenSurface surface, List<int> expected) async {
  // Native completion does not imply that a transferred placeholder has been
  // updated. Assert the actual pixels within a bounded publication window.
  final deadline = Stopwatch()..start();
  late List<int> actual;
  do {
    await _settleOnscreenFrame();
    actual = _readOnscreenPixels(surface);
    if (listEquals(actual, expected)) {
      break;
    }
  } while (deadline.elapsedMilliseconds < 500);
  expect(actual, expected);
}

List<int> _readOnscreenPixels(SkwasmOnscreenSurface surface) {
  final DomHTMLCanvasElement canvas = createDomCanvasElement(width: 2, height: 2);
  final DomCanvasRenderingContext2D context = canvas.context2D;
  context.drawImage(surface.canvasImageSource, 0, 0);
  final Uint8ClampedList data = context.getImageData(0, 0, 2, 2).data;
  canvas.width = 0;
  canvas.height = 0;
  return data.toList();
}

Future<void> _settleOnscreenFrame() async {
  // A placeholder update can occur after rAF callbacks, so inspect it from a
  // subsequent task rather than a microtask within the rendering opportunity.
  final completer = Completer<void>();
  final DomMessageChannel channel = createDomMessageChannel();
  final DomEventListener listener = createDomEventListener((_) => completer.complete());
  channel.port1.addEventListener('message', listener);
  channel.port1.start();
  final double id = domWindow.requestAnimationFrame((_) => channel.port2.postMessage(null));
  try {
    await completer.future.timeout(const Duration(seconds: 5));
  } finally {
    domWindow.cancelAnimationFrame(id);
    channel.port1.removeEventListener('message', listener);
    channel.port1.close();
    channel.port2.close();
  }
}

class _FailingCanvasProvider extends OnscreenCanvasProvider {
  bool fail = false;

  @override
  DomHTMLCanvasElement acquireCanvas(BitmapSize size, {required ui.VoidCallback onContextLost}) {
    if (fail) {
      throw StateError('Canvas allocation failed during recovery.');
    }
    return super.acquireCanvas(size, onContextLost: onContextLost);
  }
}

class _FailingRecoverySurface extends SkwasmOnscreenSurface {
  _FailingRecoverySurface(super.canvasProvider);
  bool fail = false;

  @override
  Future<void> recreateContextForCanvas(covariant DomHTMLCanvasElement canvas) async {
    if (fail) {
      await Future<void>.delayed(Duration.zero);
      throw StateError('Asynchronous context recreation failed.');
    }
    await super.recreateContextForCanvas(canvas);
  }
}
