// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

import '../../common/test_initialization.dart';
import '../../ui/utils.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUnitTests();
  setUp(() {
    ImageDecodingManager.instance.debugReset();
  });
  group('$HtmlImageElementCodec', () {
    test('supports raw images - RGBA8888', () async {
      final completer = Completer<ui.Image>();
      const width = 200;
      const height = 300;
      final list = Uint32List(width * height);
      for (var index = 0; index < list.length; index += 1) {
        list[index] = 0xFF0000FF;
      }
      ui.decodeImageFromPixels(
        list.buffer.asUint8List(),
        width,
        height,
        ui.PixelFormat.rgba8888,
        (ui.Image image) => completer.complete(image),
      );
      final ui.Image image = await completer.future;
      expect(image.width, width);
      expect(image.height, height);
    });
    test('supports raw images - BGRA8888', () async {
      final completer = Completer<ui.Image>();
      const width = 200;
      const height = 300;
      final list = Uint32List(width * height);
      for (var index = 0; index < list.length; index += 1) {
        list[index] = 0xFF0000FF;
      }
      ui.decodeImageFromPixels(
        list.buffer.asUint8List(),
        width,
        height,
        ui.PixelFormat.bgra8888,
        (ui.Image image) => completer.complete(image),
      );
      final ui.Image image = await completer.future;
      expect(image.width, width);
      expect(image.height, height);
    });
    test('loads sample image', () async {
      final HtmlImageElementCodec codec = CkImageElementCodec('sample_image1.png');
      final ui.FrameInfo frameInfo = await codec.getNextFrame();

      expect(codec.imgElement, isNotNull);
      expect(codec.imgElement!.src, contains('sample_image1.png'));
      expect(codec.imgElement!.crossOrigin, 'anonymous');
      expect(codec.imgElement!.decoding, 'async');

      expect(frameInfo.image, isNotNull);
      expect(frameInfo.image.width, 100);
      expect(frameInfo.image.toString(), '[100×100]');
    });
    test('dispose image image', () async {
      final HtmlImageElementCodec codec = CkImageElementCodec('sample_image1.png');
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      expect(frameInfo.image, isNotNull);
      expect(frameInfo.image.debugDisposed, isFalse);
      frameInfo.image.dispose();
      expect(frameInfo.image.debugDisposed, isTrue);
    });
    test('provides image loading progress', () async {
      final buffer = StringBuffer();
      final HtmlImageElementCodec codec = CkImageElementCodec(
        'sample_image1.png',
        chunkCallback: (int loaded, int total) {
          buffer.write('$loaded/$total,');
        },
      );
      await codec.getNextFrame();
      expect(buffer.toString(), '0/100,100/100,');
    });

    test('uses ImageDecodingManager', () async {
      final ImageDecodingManager manager = ImageDecodingManager.instance;
      // Occupy all slots
      final requests = <ImageDecodingRequest>[];
      for (var i = 0; i < 8; i++) {
        requests.add(manager.requestDecodingSlot(100, 100));
      }

      final HtmlImageElementCodec codec = CkImageElementCodec('sample_image1.png');
      var decoded = false;
      final Future<void> decodeFuture = codec.decode().then((_) => decoded = true);

      // Give it some time to load (Phase 1)
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(decoded, false); // Should be blocked in Phase 2

      // Release one slot
      manager.releaseDecodingSlot(requests[0]);

      // Wait for it to decode (Phase 3)
      await decodeFuture;
      expect(decoded, true);

      // Clean up remaining slots
      for (var i = 1; i < 8; i++) {
        manager.releaseDecodingSlot(requests[i]);
      }
    });

    test('dispose unblocks ImageDecodingManager queue', () async {
      final ImageDecodingManager manager = ImageDecodingManager.instance;
      // Occupy all slots
      final requests = <ImageDecodingRequest>[];
      for (var i = 0; i < 8; i++) {
        requests.add(manager.requestDecodingSlot(100, 100));
      }

      final HtmlImageElementCodec codec = CkImageElementCodec('sample_image1.png');
      var decodeFinished = false;
      unawaited(codec.decode().whenComplete(() => decodeFinished = true));

      // Give it some time to load (Phase 1)
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(decodeFinished, false); // Should be blocked in Phase 2

      // Dispose the codec while it's in the queue
      codec.dispose();

      // The decode future should complete (as requested in the plan)
      await Future<void>.delayed(Duration.zero);
      expect(decodeFinished, true);

      // A new request should be able to get a slot if we release one.
      manager.releaseDecodingSlot(requests[0]);
      final ImageDecodingRequest request2 = manager.requestDecodingSlot(100, 100);
      var granted2 = false;
      unawaited(request2.future.then((_) => granted2 = true));
      await Future<void>.delayed(Duration.zero);
      expect(granted2, true);

      // Clean up
      for (var i = 1; i < 8; i++) {
        manager.releaseDecodingSlot(requests[i]);
      }
      manager.releaseDecodingSlot(request2);
    });

    test('getNextFrame() throws StateError if disposed', () async {
      final HtmlImageElementCodec codec = CkImageElementCodec('sample_image1.png');
      codec.dispose();
      expect(() => codec.getNextFrame(), throwsStateError);
    });

    test('clears src on loading failure', () async {
      final HtmlImageElementCodec codec = CkImageElementCodec('non_existent_image.png');
      try {
        await codec.getNextFrame();
        fail('Should have thrown an exception');
      } catch (e) {
        expect(e, isA<ImageCodecException>());
      }
      expect(codec.imgElement?.src, isNot(contains('non_existent_image.png')));
    });

    test('dispose does not clear src if image handed out', () async {
      final HtmlImageElementCodec codec = CkImageElementCodec('sample_image1.png');
      final ui.FrameInfo frame = await codec.getNextFrame();
      final String? src = codec.imgElement?.src;
      expect(src, contains('sample_image1.png'));

      codec.dispose();
      expect(codec.imgElement?.src, src); // Should NOT be cleared

      frame.image.dispose();
    });

    /// Regression test for Firefox
    /// https://github.com/flutter/flutter/issues/66412
    test('Returns nonzero natural width/height', () async {
      final HtmlImageElementCodec codec = CkImageElementCodec(
        'data:image/svg+xml;base64,PHN2ZyByb2xlPSJpbWciIHZpZXdCb3g9I'
        'jAgMCAyNCAyNCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48dG'
        'l0bGU+QWJzdHJhY3QgaWNvbjwvdGl0bGU+PHBhdGggZD0iTTEyIDBjOS42MDEgMCAx'
        'MiAyLjM5OSAxMiAxMiAwIDkuNjAxLTIuMzk5IDEyLTEyIDEyLTkuNjAxIDAtMTItMi'
        '4zOTktMTItMTJDMCAyLjM5OSAyLjM5OSAwIDEyIDB6bS0xLjk2OSAxOC41NjRjMi41'
        'MjQuMDAzIDQuNjA0LTIuMDcgNC42MDktNC41OTUgMC0yLjUyMS0yLjA3NC00LjU5NS'
        '00LjU5NS00LjU5NVM1LjQ1IDExLjQ0OSA1LjQ1IDEzLjk2OWMwIDIuNTE2IDIuMDY1'
        'IDQuNTg4IDQuNTgxIDQuNTk1em04LjM0NC0uMTg5VjUuNjI1SDUuNjI1djIuMjQ3aD'
        'EwLjQ5OHYxMC41MDNoMi4yNTJ6bS04LjM0NC02Ljc0OGEyLjM0MyAyLjM0MyAwIDEx'
        'LS4wMDIgNC42ODYgMi4zNDMgMi4zNDMgMCAwMS4wMDItNC42ODZ6Ii8+PC9zdmc+',
      );
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      expect(frameInfo.image.width, isNot(0));
    });
  }, skip: isSkwasm);

  group('ImageCodecUrl', () {
    test('loads sample image from web', () async {
      final Uri uri = Uri.base.resolve('sample_image1.png');
      final codec = await ui_web.createImageCodecFromUrl(uri) as HtmlImageElementCodec;
      final ui.FrameInfo frameInfo = await codec.getNextFrame();

      expect(codec.imgElement, isNotNull);
      expect(codec.imgElement!.src, contains('sample_image1.png'));
      expect(codec.imgElement!.crossOrigin, 'anonymous');
      expect(codec.imgElement!.decoding, 'async');

      expect(frameInfo.image, isNotNull);
      expect(frameInfo.image.width, 100);
    });
    test('provides image loading progress from web', () async {
      final Uri uri = Uri.base.resolve('sample_image1.png');
      final buffer = StringBuffer();
      final codec =
          await ui_web.createImageCodecFromUrl(
                uri,
                chunkCallback: (int loaded, int total) {
                  buffer.write('$loaded/$total,');
                },
              )
              as HtmlImageElementCodec;
      await codec.getNextFrame();
      expect(buffer.toString(), '0/100,100/100,');
    });
  }, skip: isSkwasm);
}
