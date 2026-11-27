// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart';
import 'package:ui/ui.dart' as ui;

import '../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

/// The number of native images currently alive.
///
/// The index matches `imageCount` in `SkwasmRenderer.dumpDebugInfo`.
int _liveImageCount() => withStackScope((StackScope scope) {
  final Pointer<Uint32> counts = scope.allocUint32Array(28);
  skwasmGetLiveObjectCounts(counts);
  return counts[17];
});

/// The number of native pictures currently alive.
///
/// The index matches `pictureCount` in `SkwasmRenderer.dumpDebugInfo`.
int _livePictureCount() => withStackScope((StackScope scope) {
  final Pointer<Uint32> counts = scope.allocUint32Array(28);
  skwasmGetLiveObjectCounts(counts);
  return counts[20];
});

void testMain() {
  setUpUnitTests(setUpTestViewDimensions: false);

  group('Skwasm native memory', () {
    test('SkwasmImage.clone share same handle and box', () {
      final pixels = Uint8List(4);
      final SkwasmImage backendImage = createSkwasmImageFromPixels(
        pixels,
        1,
        1,
        ui.PixelFormat.rgba8888,
      );
      final image = EngineImage(backendImage, 1, 1);

      final EngineImage clone = image.clone();
      expect(
        (clone.backendImage as SkwasmImage).handle,
        (image.backendImage as SkwasmImage).handle,
      );
      expect(clone.box, image.box);
      expect(image.box.refCount, 2);

      image.dispose();
      expect(clone.debugDisposed, isFalse);
      expect(clone.box.refCount, 1);

      clone.dispose();
      expect(clone.debugDisposed, isTrue);
      expect(clone.box.refCount, 0);
    });

    test('SkwasmPicture.clone share same handle and box', () {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawRect(const ui.Rect.fromLTRB(0, 0, 10, 10), ui.Paint());
      final picture = recorder.endRecording() as SkwasmPicture;

      final clone = picture.clone() as SkwasmPicture;
      expect(clone.handle, picture.handle);
      expect(clone.box, picture.box);
      expect(picture.box.refCount, 2);

      picture.dispose();
      expect(clone.isDisposed, isFalse);
      expect(clone.box.refCount, 1);

      clone.dispose();
      expect(clone.isDisposed, isTrue);
      expect(clone.box.refCount, 0);
    });

    test('SkwasmImage.dispose is idempotent and does not underflow live image count', () {
      final int baseline = _liveImageCount();
      final SkwasmImage backendImage = createSkwasmImageFromPixels(
        Uint8List(4),
        1,
        1,
        ui.PixelFormat.rgba8888,
      );
      expect(_liveImageCount(), baseline + 1);

      backendImage.dispose();
      expect(_liveImageCount(), baseline);

      backendImage.dispose();
      expect(_liveImageCount(), baseline);
    });

    test(
      'Undisposed SkwasmPicture collected by finalizer frees native picture and ImageSource',
      () async {
        final Finalizer originalFinalizer = UniqueRef.finalizer;
        final mockFinalizer = _MockFinalizer();
        UniqueRef.finalizer = mockFinalizer;
        try {
          final int baseline = _livePictureCount();

          // Plain picture with null imageTracker.
          final plainRecorder = ui.PictureRecorder();
          final plainCanvas = ui.Canvas(plainRecorder);
          plainCanvas.drawRect(const ui.Rect.fromLTRB(0, 0, 10, 10), ui.Paint());
          final plainPicture = plainRecorder.endRecording() as SkwasmPicture;
          expect(_livePictureCount(), baseline + 1);

          mockFinalizer.trigger(plainPicture.box);
          expect(_livePictureCount(), baseline);

          // Picture retaining an ImageSource via PictureImageTracker.
          final DomImageBitmap bitmap = await createImageBitmap(createBlankDomImageData(4, 4));
          final image = renderer.createImageFromImageBitmap(bitmap) as EngineImage;
          final ImageSource source = image.imageSource!;

          final imageRecorder = ui.PictureRecorder();
          final imageCanvas = ui.Canvas(imageRecorder);
          imageCanvas.drawImage(image, ui.Offset.zero, ui.Paint());
          final trackedPicture = imageRecorder.endRecording() as SkwasmPicture;
          expect(_livePictureCount(), baseline + 1);

          image.dispose();
          expect(source.debugIsClosed, isFalse);

          mockFinalizer.trigger(trackedPicture.box);
          expect(_livePictureCount(), baseline);
          expect(source.debugIsClosed, isTrue);
        } finally {
          UniqueRef.finalizer = originalFinalizer;
        }
      },
    );

    test('Abandoned SkwasmPictureRecorder releases retained ImageSource via finalizer', () async {
      final NativeMemoryFinalizer originalFinalizer = SkwasmPictureRecorder.finalizer;
      final mockFinalizer = _MockFinalizer();
      SkwasmPictureRecorder.finalizer = mockFinalizer;
      try {
        final DomImageBitmap bitmap = await createImageBitmap(createBlankDomImageData(4, 4));
        final image = renderer.createImageFromImageBitmap(bitmap) as EngineImage;
        final ImageSource source = image.imageSource!;

        final recorder = SkwasmPictureRecorder();
        final EngineCanvas canvas = recorder.beginRecording(ui.Rect.largest);
        canvas.drawImage(image, ui.Offset.zero, ui.Paint());

        image.dispose();
        expect(source.debugIsClosed, isFalse);

        expect(mockFinalizer.registeredPairs, hasLength(1));
        expect(mockFinalizer.registeredPairs.single.target, same(recorder));
        expect(mockFinalizer.registeredPairs.single.value, same(recorder.tracker));

        mockFinalizer.trigger(recorder);
        expect(source.debugIsClosed, isTrue);
        recorder.dispose();
      } finally {
        SkwasmPictureRecorder.finalizer = originalFinalizer;
      }
    });

    test(
      'SkwasmPicture.toImageSync retains ImageSource after picture and source image disposal',
      () async {
        final DomImageData greenData = createBlankDomImageData(4, 4);
        for (var i = 0; i < greenData.data.length; i += 4) {
          greenData.data[i] = 0;
          greenData.data[i + 1] = 255;
          greenData.data[i + 2] = 0;
          greenData.data[i + 3] = 255;
        }
        final DomImageBitmap bitmap = await createImageBitmap(greenData);
        final image = renderer.createImageFromImageBitmap(bitmap) as EngineImage;
        final ImageSource source = image.imageSource!;

        final recorder = ui.PictureRecorder();
        ui.Canvas(recorder).drawImage(image, ui.Offset.zero, ui.Paint());
        final ui.Picture picture = recorder.endRecording();

        // Dispose source image before converting picture to a deferred image.
        image.dispose();
        expect(source.debugIsClosed, isFalse);

        final snapshot = picture.toImageSync(4, 4) as EngineImage;
        // Disposing the intermediate picture (as Scene.toImageSync does) must not
        // close the ImageSource while the deferred snapshot still needs it.
        picture.dispose();
        expect(source.debugIsClosed, isFalse);

        // Drawing snapshot into a second picture propagates the retained ImageSource.
        final secondRecorder = ui.PictureRecorder();
        ui.Canvas(secondRecorder).drawImage(snapshot, ui.Offset.zero, ui.Paint());
        final ui.Picture secondPicture = secondRecorder.endRecording();

        final ByteData? pixels = await snapshot.toByteData();
        expect(pixels, isNotNull);
        expect(pixels!.getUint8(0), 0);
        expect(pixels.getUint8(1), 255);
        expect(pixels.getUint8(2), 0);
        expect(pixels.getUint8(3), 255);

        snapshot.dispose();
        expect(source.debugIsClosed, isFalse);

        secondPicture.dispose();
        expect(source.debugIsClosed, isTrue);
      },
    );

    test('Undisposed SkwasmPicture.toImageSync releases retained ImageSource on GC', () async {
      final Finalizer originalFinalizer = UniqueRef.finalizer;
      final mockFinalizer = _MockFinalizer();
      UniqueRef.finalizer = mockFinalizer;
      try {
        final DomImageBitmap bitmap = await createImageBitmap(createBlankDomImageData(4, 4));
        final image = renderer.createImageFromImageBitmap(bitmap) as EngineImage;
        final ImageSource source = image.imageSource!;

        final recorder = ui.PictureRecorder();
        ui.Canvas(recorder).drawImage(image, ui.Offset.zero, ui.Paint());
        final picture = recorder.endRecording() as SkwasmPicture;
        final snapshot = picture.toImageSync(4, 4) as EngineImage;

        // Collect undisposed source image and dispose intermediate picture.
        mockFinalizer.trigger(image.box);
        picture.dispose();
        expect(source.debugIsClosed, isFalse);

        // Collecting the undisposed deferred snapshot releases the ImageSource.
        mockFinalizer.trigger(snapshot.box);
        expect(source.debugIsClosed, isTrue);
      } finally {
        UniqueRef.finalizer = originalFinalizer;
      }
    });
  });
}

class _MockFinalizer extends NativeMemoryFinalizer {
  _MockFinalizer() : super((_) {});
  final List<({Object target, Object value, Object? detach})> registeredPairs =
      <({Object target, Object value, Object? detach})>[];

  @override
  void attach(Object target, Object value, {Object? detach}) {
    registeredPairs.add((target: target, value: value, detach: detach));
  }

  @override
  void detach(Object detach) {
    registeredPairs.removeWhere((pair) => identical(pair.detach, detach));
  }

  void trigger(Object target) {
    final List<({Object target, Object value, Object? detach})> matches = registeredPairs
        .where((pair) => identical(pair.target, target))
        .toList();
    for (final match in matches) {
      if (match.value is PictureImageTracker) {
        (match.value as PictureImageTracker).releaseAll();
      } else if (match.value is UniqueRef<dynamic>) {
        (match.value as UniqueRef<dynamic>).collect();
      }
    }
  }
}
