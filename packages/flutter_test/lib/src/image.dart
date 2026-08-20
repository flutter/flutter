// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:fake_async/fake_async.dart';
/// @docImport 'package:flutter/widgets.dart';
///
/// @docImport 'binding.dart';
/// @docImport 'test_compat.dart';
/// @docImport 'widget_tester.dart';
library;

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'binding.dart';
import 'test_async_utils.dart';

final Map<int, ui.Image> _cache = <int, ui.Image>{};

/// Creates an arbitrarily sized image for testing.
///
/// If the [cache] parameter is set to true, the image will be cached for the
/// rest of this suite. This is normally desirable, assuming a test suite uses
/// images with the same dimensions in most tests, as it will save on memory
/// usage and CPU time over the course of the suite. However, it should be
/// avoided for images that are used only once in a test suite, especially if
/// the image is large, as it will require holding on to the memory for that
/// image for the duration of the suite.
///
/// This method requires real async work, and will not work properly in the
/// [FakeAsync] zones set up by [testWidgets]. Typically, it should be invoked
/// as a setup step before [testWidgets] are run, such as [setUp] or [setUpAll].
/// If needed, it can be invoked using [WidgetTester.runAsync].
Future<ui.Image> createTestImage({int width = 1, int height = 1, bool cache = true}) =>
    TestAsyncUtils.guard(() async {
      assert(width > 0);
      assert(height > 0);

      final int cacheKey = Object.hash(width, height);
      if (cache && _cache.containsKey(cacheKey)) {
        return _cache[cacheKey]!.clone();
      }

      final ui.Image image = await _createImage(width, height);
      if (cache) {
        _cache[cacheKey] = image.clone();
      }
      return image;
    });

Future<ui.Image> _createImage(int width, int height) async {
  final completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    Uint8List.fromList(List<int>.filled(width * height * 4, 0)),
    width,
    height,
    ui.PixelFormat.rgba8888,
    (ui.Image image) {
      completer.complete(image);
    },
  );
  return completer.future;
}

/// Precaches an [ImageProvider] during testing.
///
/// In a widget test, image decoding operations (such as [MemoryImage],
/// [NetworkImage], and [ExactAssetImage]) run asynchronously outside the test's
/// [FakeAsync] zone.
///
/// Calling [precacheTestImage] resolves the image stream in a real async zone
/// (via [TestWidgetsFlutterBinding.runAsync]), loading the decoded image into
/// [imageCache] before the widget tree is pumped.
///
/// Can be called before [WidgetTester.pumpWidget] inside a [testWidgets] body,
/// or inside [setUp] / [setUpAll].
///
/// If [onError] is provided, it will be invoked if an error occurs while
/// precaching. Otherwise, any error will complete the returned future with that error.
Future<void> precacheTestImage(
  ImageProvider provider, {
  ImageConfiguration configuration = ImageConfiguration.empty,
  ImageErrorListener? onError,
}) {
  final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();
  Object? caughtError;
  StackTrace? caughtStackTrace;

  Future<void> resolveImage() async {
    final completer = Completer<void>.sync();
    final ImageStream stream = provider.resolve(configuration);
    final listener = ImageStreamListener(
      (ImageInfo info, bool syncCall) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      onError: (Object error, StackTrace? stackTrace) {
        if (!completer.isCompleted) {
          if (onError != null) {
            onError(error, stackTrace);
          } else {
            caughtError = error;
            caughtStackTrace = stackTrace;
          }
          completer.complete();
        }
      },
    );
    stream.addListener(listener);
    await completer.future;
  }

  Future<void> doPrecache() async {
    await binding.runAsync<void>(resolveImage);
    if (caughtError != null) {
      Error.throwWithStackTrace(caughtError!, caughtStackTrace ?? StackTrace.current);
    }
  }

  return TestAsyncUtils.guard(doPrecache);
}
