// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:html' as html;
import 'dart:math';
import 'dart:ui';

import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

import 'image_resizer_utils.dart';

/// Helper class that resizes images.
class ImageResizer {
  /// Resizes the image if needed.
  /// (Does not support gif images)
  Future<XFile> resizeImageIfNeeded(XFile file, double? maxWidth,
      double? maxHeight, int? imageQuality) async {
    if (!imageResizeNeeded(maxWidth, maxHeight, imageQuality) ||
        file.mimeType == 'image/gif') {
      // Implement maxWidth and maxHeight for image/gif
      return file;
    }
    try {
      final html.ImageElement imageElement = await loadImage(file.path);
      final html.CanvasElement canvas =
          resizeImageElement(imageElement, maxWidth, maxHeight);
      final XFile resizedImage =
          await writeCanvasToFile(file, canvas, imageQuality);
      html.Url.revokeObjectUrl(file.path);
      return resizedImage;
    } catch (e) {
      return file;
    }
  }

  /// function that loads the blobUrl into an imageElement
  Future<html.ImageElement> loadImage(String blobUrl) {
    final Completer<html.ImageElement> imageLoadCompleter =
        Completer<html.ImageElement>();
    final html.ImageElement imageElement = html.ImageElement();
    // ignore: unsafe_html
    imageElement.src = blobUrl;

    imageElement.onLoad.listen((html.Event event) {
      imageLoadCompleter.complete(imageElement);
    });
    imageElement.onError.listen((html.Event event) {
      const String exception = 'Error while loading image.';
      imageElement.remove();
      imageLoadCompleter.completeError(exception);
    });
    return imageLoadCompleter.future;
  }

  /// Draws image to a canvas while resizing the image to fit the [maxWidth],[maxHeight] constraints
  html.CanvasElement resizeImageElement(
      html.ImageElement source, double? maxWidth, double? maxHeight) {
    final Size newImageSize = calculateSizeOfDownScaledImage(
        Size(source.width!.toDouble(), source.height!.toDouble()),
        maxWidth,
        maxHeight);
    final html.CanvasElement canvas = html.CanvasElement();
    canvas.width = newImageSize.width.toInt();
    canvas.height = newImageSize.height.toInt();
    final html.CanvasRenderingContext2D context = canvas.context2D;
    if (maxHeight == null && maxWidth == null) {
      context.drawImage(source, 0, 0);
    } else {
      context.drawImageScaled(source, 0, 0, canvas.width!, canvas.height!);
    }
    return canvas;
  }

  /// function that converts a canvas element to Xfile
  /// [imageQuality] is only supported for jpeg and webp images.
  Future<XFile> writeCanvasToFile(
      XFile originalFile, html.CanvasElement canvas, int? imageQuality) async {
    final double calculatedImageQuality =
        (min(imageQuality ?? 100, 100)) / 100.0;
    final html.Blob blob =
        await canvas.toBlob(originalFile.mimeType, calculatedImageQuality);
    return XFile(html.Url.createObjectUrlFromBlob(blob),
        mimeType: originalFile.mimeType,
        name: 'scaled_${originalFile.name}',
        lastModified: DateTime.now(),
        length: blob.size);
  }
}
