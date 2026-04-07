// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:ui/ui.dart' as ui;

/// A callback type used to draw a portion of an image onto a canvas.
///
/// This is used to abstract the drawing operation so it can be implemented
/// differently for CanvasKit and Skwasm.
typedef RawDrawImageRect =
    void Function(ui.Canvas canvas, ui.Image image, ui.Rect src, ui.Rect dst);

/// Determines whether an image draw operation should use iterative downscaling.
///
/// Iterative downscaling is used when both dimensions are being scaled down
/// to less than half of their source size, and the filter quality is at least
/// [ui.FilterQuality.medium].
bool shouldIterativelyDownscale(ui.Rect src, ui.Rect dst, ui.Paint paint) {
  return (dst.width < src.width / 2 && dst.height < src.height / 2) &&
      dst.width >= 1 &&
      dst.height >= 1 &&
      paint.filterQuality.index >= ui.FilterQuality.medium.index;
}

/// A cache for downscaled images.
///
/// This cache is used to avoid repeatedly downscaling the same image to the
/// same target size.
class DownscaledImageCache {
  DownscaledImageCache._();

  /// The singleton instance of the cache.
  static final DownscaledImageCache instance = DownscaledImageCache._();

  // The key is the ref-counting box of the image (CkCountedRef or CountedRef).
  // We use the box as the key so that cloned images (which share the same box)
  // can use the same cached downscaled image.
  final Map<Object, Map<(ui.Rect, int, int), ui.Image>> _cache = {};

  /// Gets a cached downscaled image for the given [box], source rect, and target size.
  ui.Image? get(Object box, ui.Rect src, int width, int height) {
    return _cache[box]?[(src, width, height)];
  }

  /// Puts a downscaled image into the cache for the given [box], source rect, and target size.
  void put(Object box, ui.Rect src, int width, int height, ui.Image image) {
    final Map<(ui.Rect, int, int), ui.Image> sizes = _cache.putIfAbsent(box, () => {});
    final ui.Image? oldImage = sizes[(src, width, height)];
    if (oldImage != null && oldImage != image) {
      oldImage.dispose();
    }
    sizes[(src, width, height)] = image;
  }

  /// Disposes all cached downscaled images for the given [box].
  void disposeForBox(Object box) {
    final Map<(ui.Rect, int, int), ui.Image>? sizes = _cache.remove(box);
    if (sizes != null) {
      for (final ui.Image image in sizes.values) {
        image.dispose();
      }
    }
  }
}

/// Retrieves a downscaled image from the cache or creates it if it doesn't exist.
///
/// The [box] is the ref-counting box of the original image (e.g., `CkCountedRef`
/// or `CountedRef`). We use the box as the key so that cloned images (which
/// share the same box) can use the same cached downscaled image.
ui.Image getOrCreateDownscaledImage({
  required Object box,
  required ui.Image originalImage,
  required ui.Rect src,
  required int targetWidth,
  required int targetHeight,
  required RawDrawImageRect rawDraw,
}) {
  final DownscaledImageCache cache = DownscaledImageCache.instance;
  final ui.Image? cached = cache.get(box, src, targetWidth, targetHeight);
  if (cached != null) {
    return cached;
  }

  final ui.Image downscaled = createSteppedDownscaledImage(
    originalImage: originalImage,
    src: src,
    targetWidth: targetWidth,
    targetHeight: targetHeight,
    rawDraw: rawDraw,
  );

  cache.put(box, src, targetWidth, targetHeight, downscaled);
  return downscaled;
}

/// Creates a high-quality downscaled image by repeatedly drawing the image at
/// half scale.
///
/// This avoids aliasing artifacts that occur when downscaling an image by a
/// large factor in a single step due to Skia not using mipmaps on the web.
@visibleForTesting
ui.Image createSteppedDownscaledImage({
  required ui.Image originalImage,
  required ui.Rect src,
  required int targetWidth,
  required int targetHeight,
  required RawDrawImageRect rawDraw,
}) {
  assert(targetWidth < src.width / 2 && targetHeight < src.height / 2);
  var currentImage = originalImage;
  var currentSrc = src;

  final List<ui.Image> intermediateImages = [];

  while (currentSrc.width > targetWidth * 2) {
    final int nextWidth = currentSrc.width ~/ 2;
    final int nextHeight = currentSrc.height ~/ 2;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    rawDraw(
      canvas,
      currentImage,
      currentSrc,
      ui.Rect.fromLTWH(0, 0, nextWidth.toDouble(), nextHeight.toDouble()),
    );

    final ui.Picture picture = recorder.endRecording();
    final ui.Image nextImage = picture.toImageSync(nextWidth, nextHeight);
    picture.dispose();

    intermediateImages.add(nextImage);

    currentImage = nextImage;
    currentSrc = ui.Rect.fromLTWH(0, 0, nextWidth.toDouble(), nextHeight.toDouble());
  }

  // Optimization: If we reached the target size exactly in the loop, we can
  // return the last intermediate image directly.
  if (currentSrc.width.toInt() == targetWidth && currentSrc.height.toInt() == targetHeight) {
    final ui.Image result = intermediateImages.removeLast();
    for (final img in intermediateImages) {
      img.dispose();
    }
    return result;
  }

  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

  rawDraw(
    canvas,
    currentImage,
    currentSrc,
    ui.Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
  );

  final ui.Picture picture = recorder.endRecording();
  final ui.Image finalImage = picture.toImageSync(targetWidth, targetHeight);
  picture.dispose();

  for (final img in intermediateImages) {
    img.dispose();
  }

  return finalImage;
}
