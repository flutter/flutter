// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import '../common/test_initialization.dart';
import 'utils.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUnitTests();

  group('PictureRecorder', () {
    test('records an EnginePicture through an EnginePictureRecorder', () {
      final recorder = ui.PictureRecorder();
      expect(recorder, isA<EnginePictureRecorder>());
      expect(recorder.isRecording, isFalse);
      expect(recorder.toString(), 'PictureRecorder(recording: false)');

      final canvas = ui.Canvas(recorder);
      expect(canvas, isA<EngineCanvas>());
      expect(recorder.isRecording, isTrue);
      expect(recorder.toString(), 'PictureRecorder(recording: true)');

      final ui.Picture picture = recorder.endRecording();
      expect(picture, isA<EnginePicture>());
      expect(picture.toString(), 'Picture');
      expect(recorder.isRecording, isFalse);
      expect(recorder.toString(), 'PictureRecorder(recording: false)');
      picture.dispose();
    });

    test('recorder and picture dispose underlying objects properly', () {
      final recorder = ui.PictureRecorder() as EnginePictureRecorder;
      final canvas = ui.Canvas(recorder);
      const rect = ui.Rect.fromLTWH(0.0, 0.0, 100.0, 100.0);
      canvas.clipRect(rect);

      expect(recorder.isRecording, true);
      expect(recorder.debugDisposed, false);
      final ui.Picture picture = recorder.endRecording();

      expect(picture.debugDisposed, false);
      expect(recorder.isRecording, false);
      expect(recorder.debugDisposed, true);

      picture.dispose();
      expect(picture.debugDisposed, true);
    });

    final unstartedRecorders = <String, ui.PictureRecorder Function()>{
      'that never started recording': () => ui.PictureRecorder(),
      'that already ended its recording': () {
        final recorder = ui.PictureRecorder();
        ui.Canvas(recorder);
        recorder.endRecording().dispose();
        return recorder;
      },
    };
    for (final MapEntry<String, ui.PictureRecorder Function()>(key: description, value: create)
        in unstartedRecorders.entries) {
      test('endRecording throws on a recorder $description', () {
        final ui.PictureRecorder recorder = create();
        expect(
          recorder.endRecording,
          throwsA(
            isA<StateError>().having(
              (StateError e) => e.message,
              'message',
              'PictureRecorder did not start recording.',
            ),
          ),
        );
        expect(recorder.isRecording, isFalse);
      });
    }

    final nonGenuineRecorders = <String, ui.PictureRecorder Function()>{
      'a recorder that already ended its recording': () {
        final recorder = ui.PictureRecorder();
        ui.Canvas(recorder);
        recorder.endRecording().dispose();
        return recorder;
      },
      'a PictureRecorder implemented outside the engine': () => _FakePictureRecorder(),
    };
    for (final MapEntry<String, ui.PictureRecorder Function()>(key: description, value: create)
        in nonGenuineRecorders.entries) {
      test('Canvas rejects $description', () {
        final ui.PictureRecorder recorder = create();
        expect(
          () => ui.Canvas(recorder),
          throwsA(
            isA<ArgumentError>().having(
              (ArgumentError e) => e.message,
              'message',
              'Canvas constructor called with non-genuine PictureRecorder.',
            ),
          ),
        );
        expect(recorder.isRecording, isFalse);
      });
    }

    test('Canvas calls after endRecording are no-ops that retain no images', () async {
      const green = ui.Color(0xFF00FF00);
      const red = ui.Color(0xFFFF0000);
      const bounds = ui.Rect.fromLTRB(0, 0, 8, 8);
      final EngineImage image = await createImageBitmapImage(color: red);
      final ImageSource source = image.imageSource!;

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder, bounds);
      canvas.drawRect(bounds, ui.Paint()..color = green);
      final ui.Picture picture = recorder.endRecording();

      final redPaint = ui.Paint()..color = red;
      canvas.save();
      canvas.translate(2, 3);
      canvas.scale(2, 3);
      canvas.rotate(0.5);
      canvas.skew(0.1, 0.2);
      canvas.transform(_identity);
      canvas.clipRect(const ui.Rect.fromLTRB(1, 1, 4, 4));
      canvas.clipRRect(ui.RRect.fromLTRBR(1, 1, 4, 4, const ui.Radius.circular(1)));
      canvas.clipPath(ui.Path()..addRect(const ui.Rect.fromLTRB(1, 1, 4, 4)));
      canvas.saveLayer(bounds, redPaint);
      canvas.drawPaint(redPaint);
      canvas.drawRect(bounds, redPaint);
      canvas.drawCircle(const ui.Offset(4, 4), 4, redPaint);
      canvas.drawImage(image, ui.Offset.zero, ui.Paint());
      canvas.drawImageRect(image, const ui.Rect.fromLTRB(0, 0, 4, 4), bounds, ui.Paint());
      canvas.restore();
      canvas.restore();
      canvas.restoreToCount(1);

      expect(canvas.getSaveCount(), 0);
      expect(canvas.getTransform(), List<double>.filled(16, 0.0));
      expect(canvas.getDestinationClipBounds(), ui.Rect.zero);
      expect(canvas.getLocalClipBounds(), ui.Rect.zero);

      // The image drawn after endRecording was not recorded, so nothing else
      // keeps its source open.
      image.dispose();
      expect(source.debugIsClosed, isTrue);

      // The picture only contains what was drawn before endRecording.
      final ui.Image rendered = await picture.toImage(8, 8);
      final ByteData bytes = (await rendered.toByteData())!;
      expect(_distinctPixels(bytes), <List<int>>[_greenPixel]);
      rendered.dispose();
      picture.dispose();
    });

    test('an idle recorder registers no finalizer and an abandoned recording is '
        'collected with its native recorder and retained image sources', () async {
      final EngineImage image = await createImageBitmapImage();
      final ImageSource source = image.imageSource!;
      final RecordingFinalizer finalizer = _useRecordingFinalizer();

      final recorder = ui.PictureRecorder();
      expect(finalizer.registeredPairs, isEmpty);
      expect(_pictureRecorderCounters(), isEmpty);

      final canvas = ui.Canvas(recorder);
      canvas.drawImage(image, ui.Offset.zero, ui.Paint());
      image.dispose();
      expect(source.debugIsClosed, isFalse);

      final List<({Object target, Object value, Object? detach})> pairs = finalizer.pairsFor(
        recorder,
      );
      expect(pairs, hasLength(1));
      expect(pairs.single.value, isA<UniqueRef<dynamic>>());
      expect(_pictureRecorderCounters(), <String, int>{'PictureRecorder Created': 1});

      finalizer.collect(recorder);

      expect(_pictureRecorderCounters(), <String, int>{
        'PictureRecorder Created': 1,
        'PictureRecorder Leaked': 1,
        'PictureRecorder Deleted': 1,
      });
      expect(source.debugIsClosed, isTrue);
      expect(finalizer.pairsFor(recorder), isEmpty);
    });

    test('collecting a finished recorder leaves its picture and the recorded image '
        'sources alive', () async {
      final EngineImage image = await createImageBitmapImage();
      final ImageSource source = image.imageSource!;
      final RecordingFinalizer finalizer = _useRecordingFinalizer();

      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder).drawImage(image, ui.Offset.zero, ui.Paint());
      final ui.Picture picture = recorder.endRecording();
      image.dispose();

      expect(finalizer.pairsFor(recorder), isEmpty);
      finalizer.collect(recorder);
      expect(_pictureRecorderCounters(), <String, int>{
        'PictureRecorder Created': 1,
        'PictureRecorder Deleted': 1,
      });
      expect(source.debugIsClosed, isFalse);
      expect(await _renderedPixels(picture), <List<int>>[_greenPixel]);

      picture.dispose();
      expect(source.debugIsClosed, isTrue);
    });
  });

  group('Picture', () {
    test('Disposing picture does not dispose picture in PictureLayer', () {
      final recorder = ui.PictureRecorder() as EnginePictureRecorder;
      final canvas = ui.Canvas(recorder);
      const rect = ui.Rect.fromLTWH(0.0, 0.0, 100.0, 100.0);
      canvas.clipRect(rect);

      expect(recorder.isRecording, true);
      expect(recorder.debugDisposed, false);
      final ui.Picture picture = recorder.endRecording();

      expect(picture.debugDisposed, false);
      expect(recorder.isRecording, false);
      expect(recorder.debugDisposed, true);

      final builder = ui.SceneBuilder() as LayerSceneBuilder;
      builder.addPicture(ui.Offset.zero, picture);
      final LayerScene scene = builder.build();
      final pictureLayer = scene.layerTree.rootLayer.children.first as PictureLayer;

      expect(pictureLayer.picture.debugDisposed, false);

      picture.dispose();
      expect(picture.debugDisposed, true);
      expect(pictureLayer.picture.debugDisposed, false);

      pictureLayer.dispose();
      expect(pictureLayer.picture.debugDisposed, true);
    });

    test('Picture construction invokes onCreate once', () async {
      var onCreateInvokedCount = 0;
      ui.Picture? createdPicture;
      ui.Picture.onCreate = (ui.Picture picture) {
        onCreateInvokedCount++;
        createdPicture = picture;
      };

      final ui.Picture picture1 = _createPicture();

      expect(onCreateInvokedCount, 1);
      expect(createdPicture, picture1);

      final ui.Picture picture2 = _createPicture();

      expect(onCreateInvokedCount, 2);
      expect(createdPicture, picture2);
      ui.Picture.onCreate = null;
    });

    test('approximateBytesUsed is available for onCreate', () async {
      var pictureSize = -1;

      ui.Picture.onCreate = (ui.Picture picture) => pictureSize = picture.approximateBytesUsed;

      _createPicture();

      expect(pictureSize >= 0, true);
      ui.Picture.onCreate = null;
    });

    test('dispose() invokes onDispose once', () async {
      var onDisposeInvokedCount = 0;
      ui.Picture? disposedPicture;
      ui.Picture.onDispose = (ui.Picture picture) {
        onDisposeInvokedCount++;
        disposedPicture = picture;
      };

      final ui.Picture picture1 = _createPicture()..dispose();

      expect(onDisposeInvokedCount, 1);
      expect(disposedPicture, picture1);

      final ui.Picture picture2 = _createPicture()..dispose();

      expect(onDisposeInvokedCount, 2);
      expect(disposedPicture, picture2);

      ui.Picture.onDispose = null;
    });

    test('onCreate and onDispose may query the picture and record other pictures', () {
      final created = <ui.Picture>[];
      final disposed = <ui.Picture>[];
      ui.Picture.onCreate = (ui.Picture picture) {
        expect(picture.approximateBytesUsed, greaterThanOrEqualTo(0));
        created.add(picture);
        if (created.length == 1) {
          _createPicture().dispose();
        }
      };
      ui.Picture.onDispose = (ui.Picture picture) {
        expect(picture.approximateBytesUsed, greaterThanOrEqualTo(0));
        disposed.add(picture);
      };
      addTearDown(() {
        ui.Picture.onCreate = null;
        ui.Picture.onDispose = null;
      });

      final ui.Picture picture = _createPicture();
      expect(created, hasLength(2));
      expect(created.first, same(picture));
      expect(disposed, hasLength(1));
      expect(disposed.single, same(created.last));
      expect(picture.debugDisposed, isFalse);

      picture.dispose();
      expect(disposed, hasLength(2));
      expect(disposed.last, same(picture));
    });

    test('can be disposed of manually', () {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawPaint(ui.Paint());
      final picture = recorder.endRecording() as EnginePicture;
      expect(picture.debugDisposed, isFalse);
      expect(picture.isDisposed, isFalse);
      expect(picture.backendPicture, isA<BackendPicture>());

      picture.dispose();
      expect(picture.debugDisposed, isTrue);
      expect(picture.isDisposed, isTrue);
      expect(() => picture.backendPicture, throwsA(isA<AssertionError>()));
    });

    test('a disposed picture asserts on every use', () {
      final ui.Picture picture = _createPicture()..dispose();

      // Block bodies discard any returned Future, so `toImage` must throw
      // synchronously to satisfy the matcher.
      final uses = <String, Object? Function()>{
        'dispose': () {
          picture.dispose();
          return null;
        },
        'toImage': () {
          picture.toImage(10, 10);
          return null;
        },
        'toImageSync': () => picture.toImageSync(10, 10),
        'cullRect': () => (picture as EnginePicture).cullRect,
        'approximateBytesUsed': () => picture.approximateBytesUsed,
        'clone': () => (picture as EnginePicture).clone(),
      };
      for (final MapEntry<String, Object? Function()>(key: name, value: use) in uses.entries) {
        expect(use, throwsA(isA<AssertionError>()), reason: name);
      }
    });

    test('toImage and toImageSync reject non-positive dimensions synchronously', () {
      final ui.Picture picture = _createPicture();
      final TypeMatcher<Exception> invalidImageDimensions = isA<Exception>().having(
        (Exception e) => e.toString(),
        'toString()',
        'Exception: Invalid image dimensions.',
      );

      const dimensions = <(int, int)>[(0, 10), (10, 0), (-1, 10), (10, -1), (0, 0)];
      for (final (int width, int height) in dimensions) {
        expect(
          () {
            picture.toImage(width, height);
          },
          throwsA(invalidImageDimensions),
          reason: 'toImage($width, $height)',
        );
        expect(
          () {
            picture.toImageSync(width, height);
          },
          throwsA(invalidImageDimensions),
          reason: 'toImageSync($width, $height)',
        );
      }
      picture.dispose();
    });

    test('toImage reports backend rasterization failures through the returned future', () async {
      final picture = EnginePicture(ThrowingBackendPicture());
      addTearDown(picture.dispose);

      late Future<ui.Image> result;
      expect(() {
        result = picture.toImage(4, 4);
      }, returnsNormally);
      await expectLater(
        result,
        throwsA(
          isA<StateError>().having((StateError e) => e.message, 'message', 'toImageSync failed'),
        ),
      );
    });

    test('toImageSync', () async {
      const color = ui.Color(0xFFAAAAAA);
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawPaint(ui.Paint()..color = color);
      final ui.Picture picture = recorder.endRecording();
      final ui.Image image = picture.toImageSync(10, 15);

      expect(image.width, 10);
      expect(image.height, 15);

      final ByteData? data = await image.toByteData();
      expect(data, isNotNull);
      expect(data!.lengthInBytes, 10 * 15 * 4);
      expect(data.buffer.asUint32List().first, color.toARGB32());
      image.dispose();
      picture.dispose();
    });

    test('cullRect bounds are tight', () async {
      const red = ui.Color.fromRGBO(255, 0, 0, 1);
      const green = ui.Color.fromRGBO(0, 255, 0, 1);
      const blue = ui.Color.fromRGBO(0, 0, 255, 1);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawRRect(
        ui.RRect.fromRectXY(const ui.Rect.fromLTRB(20, 20, 150, 300), 15, 15),
        ui.Paint()..color = red,
      );
      canvas.drawCircle(const ui.Offset(200, 200), 100, ui.Paint()..color = green);
      canvas.drawOval(const ui.Rect.fromLTRB(210, 40, 268, 199), ui.Paint()..color = blue);

      final picture = recorder.endRecording() as EnginePicture;
      final ui.Rect bounds = picture.cullRect;
      // Top left bounded by the red rrect, right bounded by right edge
      // of red rrect, bottom bounded by bottom of green circle.
      expect(bounds, equals(const ui.Rect.fromLTRB(20, 20, 300, 300)));
      picture.dispose();
    });

    test('cullRect bounds with infinite size draw', () async {
      const red = ui.Color.fromRGBO(255, 0, 0, 1);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawColor(red, ui.BlendMode.src);

      final picture = recorder.endRecording() as EnginePicture;
      final ui.Rect bounds = picture.cullRect;
      // Since the drawColor command fills the entire canvas, the computed
      // bounds default to the cullRect that is passed in when the
      // PictureRecorder is created, ie ui.Rect.largest.
      expect(bounds, equals(ui.Rect.largest));
      picture.dispose();
    });

    test('cullRect of an unbounded draw is the cull rect passed to the Canvas', () {
      const cullRect = ui.Rect.fromLTRB(2, 3, 7, 9);
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder, cullRect).drawColor(const ui.Color(0xFFFF0000), ui.BlendMode.src);

      final picture = recorder.endRecording() as EnginePicture;
      expect(picture.cullRect, cullRect);
      picture.dispose();
    });

    test('approximateBytesUsed', () async {
      const red = ui.Color.fromRGBO(255, 0, 0, 1);
      const green = ui.Color.fromRGBO(0, 255, 0, 1);
      const blue = ui.Color.fromRGBO(0, 0, 255, 1);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawRRect(
        ui.RRect.fromRectXY(const ui.Rect.fromLTRB(20, 20, 150, 300), 15, 15),
        ui.Paint()..color = red,
      );
      canvas.drawCircle(const ui.Offset(200, 200), 100, ui.Paint()..color = green);
      canvas.drawOval(const ui.Rect.fromLTRB(210, 40, 268, 199), ui.Paint()..color = blue);

      final picture = recorder.endRecording() as EnginePicture;
      final int bytesUsed = picture.approximateBytesUsed;
      // Sanity check: the picture should use more than 20 bytes of memory.
      expect(bytesUsed, greaterThan(20));
      picture.dispose();
    });

    test('toImageSync keeps recorded image sources open until every handle to the '
        'derived image is disposed', () async {
      final EngineImage image = await createImageBitmapImage();
      final ImageSource source = image.imageSource!;
      final ui.Picture picture = drawPicture((ui.Canvas canvas) {
        canvas.drawImage(image, ui.Offset.zero, ui.Paint());
      });
      final bool deferred = (picture as EnginePicture).backendPicture.toImageSyncIsDeferred;

      final ui.Image derived = picture.toImageSync(4, 4);
      final ui.Image derivedClone = derived.clone();
      image.dispose();
      picture.dispose();
      if (deferred) {
        expect(source.debugIsClosed, isFalse);
      }

      derived.dispose();
      if (deferred) {
        expect(source.debugIsClosed, isFalse);
      }

      final ByteData bytes = (await derivedClone.toByteData())!;
      expect(_distinctPixels(bytes), <List<int>>[_greenPixel]);

      derivedClone.dispose();
      expect(source.debugIsClosed, isTrue);
    });

    test('a clone keeps rendering and retaining recorded image sources after the '
        'original is disposed', () async {
      var onDisposeCount = 0;
      ui.Picture.onDispose = (ui.Picture _) => onDisposeCount++;
      addTearDown(() => ui.Picture.onDispose = null);
      final EngineImage image = await createImageBitmapImage();
      final ImageSource source = image.imageSource!;
      final original = drawPicture((ui.Canvas canvas) {
        canvas.drawImage(image, ui.Offset.zero, ui.Paint());
      }) as EnginePicture;
      final bool deferred = original.backendPicture.toImageSyncIsDeferred;
      final EnginePicture clone = original.clone();

      image.dispose();
      original.dispose();
      expect(onDisposeCount, 1);
      expect(source.debugIsClosed, isFalse);
      expect(await _renderedPixels(clone), <List<int>>[_greenPixel]);

      final ui.Image derived = clone.toImageSync(4, 4);
      clone.dispose();
      expect(onDisposeCount, 1);
      // Only a deferred image still needs the source to render.
      expect(source.debugIsClosed, !deferred);

      final ByteData bytes = (await derived.toByteData())!;
      expect(_distinctPixels(bytes), <List<int>>[_greenPixel]);
      derived.dispose();
      expect(source.debugIsClosed, isTrue);
    });

    final derivedImageDraws = <String, void Function() Function(ui.Canvas, ui.Image)>{
      'directly': (ui.Canvas canvas, ui.Image derived) {
        canvas.drawImage(derived, ui.Offset.zero, ui.Paint());
        return () {};
      },
      'through a clone': (ui.Canvas canvas, ui.Image derived) {
        final ui.Image clone = derived.clone();
        canvas.drawImage(clone, ui.Offset.zero, ui.Paint());
        return clone.dispose;
      },
      'through an ImageShader': (ui.Canvas canvas, ui.Image derived) {
        final shader = ui.ImageShader(derived, ui.TileMode.clamp, ui.TileMode.clamp, _identity);
        canvas.drawRect(const ui.Rect.fromLTRB(0, 0, 4, 4), ui.Paint()..shader = shader);
        return shader.dispose;
      },
    };
    for (final MapEntry<String, void Function() Function(ui.Canvas, ui.Image)>(
          key: description,
          value: drawDerived,
        )
        in derivedImageDraws.entries) {
      test('a toImageSync image drawn $description into another picture keeps its '
          'image sources open until that picture is disposed', () async {
        final EngineImage image = await createImageBitmapImage();
        final ImageSource source = image.imageSource!;
        final ui.Picture firstPicture = drawPicture((ui.Canvas canvas) {
          canvas.drawImage(image, ui.Offset.zero, ui.Paint());
        });
        final bool deferred = (firstPicture as EnginePicture).backendPicture.toImageSyncIsDeferred;
        final ui.Image derived = firstPicture.toImageSync(4, 4);

        late final void Function() disposeDrawResources;
        final ui.Picture secondPicture = drawPicture((ui.Canvas canvas) {
          disposeDrawResources = drawDerived(canvas, derived);
        });

        image.dispose();
        firstPicture.dispose();
        derived.dispose();
        disposeDrawResources();
        if (deferred) {
          expect(source.debugIsClosed, isFalse);
        }

        final ui.Image rendered = await secondPicture.toImage(4, 4);
        final ByteData bytes = (await rendered.toByteData())!;
        expect(_distinctPixels(bytes), <List<int>>[_greenPixel]);
        rendered.dispose();
        if (deferred) {
          expect(source.debugIsClosed, isFalse);
        }

        secondPicture.dispose();
        expect(source.debugIsClosed, isTrue);
      });
    }
  });
}

ui.Picture _createPicture() {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  const rect = ui.Rect.fromLTWH(0.0, 0.0, 100.0, 100.0);
  canvas.clipRect(rect);
  return recorder.endRecording();
}

final Float64List _identity = Float64List.fromList(<double>[
  1, 0, 0, 0, //
  0, 1, 0, 0, //
  0, 0, 1, 0, //
  0, 0, 0, 1, //
]);

/// The distinct RGBA pixels in [bytes], in order of first appearance.
List<List<int>> _distinctPixels(ByteData bytes) {
  final Uint8List rgba = bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
  final distinct = <int, List<int>>{};
  for (var i = 0; i < rgba.length; i += 4) {
    final int key = rgba[i] << 24 | rgba[i + 1] << 16 | rgba[i + 2] << 8 | rgba[i + 3];
    distinct.putIfAbsent(key, () => rgba.sublist(i, i + 4));
  }
  return distinct.values.toList();
}

/// The opaque green drawn by [createImageBitmapImage] by default.
const List<int> _greenPixel = <int>[0x00, 0xFF, 0x00, 0xFF];

/// The distinct RGBA pixels of [picture] rendered at 4x4.
Future<List<List<int>>> _renderedPixels(ui.Picture picture) async {
  final ui.Image image = await picture.toImage(4, 4);
  final ByteData bytes = (await image.toByteData())!;
  image.dispose();
  return _distinctPixels(bytes);
}

/// Replaces [UniqueRef.finalizer] with a [RecordingFinalizer] and counts
/// native object lifecycles from zero for the rest of the test.
RecordingFinalizer _useRecordingFinalizer() {
  final Finalizer originalFinalizer = UniqueRef.finalizer;
  final bool originalInstrumentationEnabled = Instrumentation.enabled;
  addTearDown(() {
    UniqueRef.finalizer = originalFinalizer;
    Instrumentation.enabled = originalInstrumentationEnabled;
  });
  final finalizer = RecordingFinalizer();
  UniqueRef.finalizer = finalizer;
  Instrumentation.enabled = true;
  Instrumentation.instance.debugCounters.clear();
  return finalizer;
}

/// Counters recorded by the `'PictureRecorder'` [UniqueRef].
Map<String, int> _pictureRecorderCounters() => <String, int>{
  for (final MapEntry<String, int>(:key, :value) in Instrumentation.instance.debugCounters.entries)
    if (key.startsWith('PictureRecorder ')) key: value,
};

class _FakePictureRecorder implements ui.PictureRecorder {
  @override
  bool get isRecording => false;

  @override
  ui.Picture endRecording() => throw UnimplementedError();
}
