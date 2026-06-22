// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

/// Instantiates a [ui.Codec] backed by an `SkAnimatedImage` from Skia.
Future<ui.Codec> skiaInstantiateImageCodec(
  Uint8List list, [
  int? targetWidth,
  int? targetHeight,
  bool allowUpscaling = true,
]) async {
  ui.Codec codec;
  // ImageDecoder does not detect image type automatically. It requires us to
  // tell it what the image type is.
  final ImageType imageType = tryDetectImageType(list, 'encoded image bytes');

  if (browserSupportsImageDecoder) {
    codec = await CkBrowserImageDecoder.create(
      data: list,
      contentType: imageType.mimeType,
      debugSource: 'encoded image bytes',
    );
  } else {
    if (imageType.isAnimated) {
      codec = CkAnimatedImage.decodeFromBytes(
        list,
        'encoded image bytes',
        targetWidth: targetWidth,
        targetHeight: targetHeight,
      );
    } else {
      final DomBlob blob = createDomBlob(<ByteBuffer>[list.buffer]);
      codec = await decodeBlobToCkImage(blob);
    }
  }
  return CkResizingCodec(
    codec,
    targetWidth: targetWidth,
    targetHeight: targetHeight,
    allowUpscaling: allowUpscaling,
  );
}

/// A resizing codec which uses an HTML <canvas> element to scale the image if
/// it is backed by an HTML Image element.
class CkResizingCodec extends ResizingCodec {
  CkResizingCodec(super.delegate, {super.targetWidth, super.targetHeight, super.allowUpscaling});

  @override
  ui.Image scaleImage(
    ui.Image image, {
    int? targetWidth,
    int? targetHeight,
    bool allowUpscaling = true,
  }) {
    final ckImage = image as EngineImage;
    if (ckImage.imageSource == null) {
      return scaleImageIfNeeded(
        image,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
        allowUpscaling: allowUpscaling,
      );
    } else {
      return _scaleImageUsingDomCanvas(
        ckImage,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
        allowUpscaling: allowUpscaling,
      );
    }
  }

  EngineImage _scaleImageUsingDomCanvas(
    EngineImage image, {
    int? targetWidth,
    int? targetHeight,
    bool allowUpscaling = true,
  }) {
    assert(image.imageSource != null);
    final int width = image.width;
    final int height = image.height;
    // Calculate the target scaled dimensions while maintaining the aspect ratio if needed.
    final BitmapSize? scaledSize = scaledImageSize(width, height, targetWidth, targetHeight);
    if (scaledSize == null) {
      return image;
    }
    // If upscaling is disabled and the target dimensions exceed the original size,
    // do not perform scaling and return the original image.
    if (!allowUpscaling && (scaledSize.width > width || scaledSize.height > height)) {
      return image;
    }

    final int scaledWidth = scaledSize.width;
    final int scaledHeight = scaledSize.height;

    final DomOffscreenCanvas offscreenCanvas = createDomOffscreenCanvas(scaledWidth, scaledHeight);
    final ctx = offscreenCanvas.getContext('2d')! as DomCanvasRenderingContext2D;
    ctx.drawImage(
      image.imageSource!.canvasImageSource,
      0,
      0,
      width,
      height,
      0,
      0,
      scaledWidth,
      scaledHeight,
    );
    final DomImageBitmap bitmap = offscreenCanvas.transferToImageBitmap();
    SkImage? skImage;
    if (CanvasKitRenderer.instance.isSoftware) {
      skImage = canvasKit.MakeImageFromCanvasImageSource(bitmap);
    } else {
      skImage = canvasKit.MakeLazyImageFromImageBitmap(bitmap, true);
    }

    // Resize the canvas to 0x0 to cause the browser to eagerly reclaim its
    // memory.
    offscreenCanvas.width = 0;
    offscreenCanvas.height = 0;

    if (skImage == null) {
      domWindow.console.warn('Failed to scale image.');
      return image;
    }

    image.dispose();
    return EngineImage(
      CkImageDelegate(skImage),
      skImage.width().toInt(),
      skImage.height().toInt(),
      imageSource: ImageBitmapImageSource(bitmap),
    );
  }
}

ui.Image createCkImageFromImageElement(
  DomHTMLImageElement image,
  int naturalWidth,
  int naturalHeight,
) {
  SkImage? skImage;
  // If software rendering is active, make the SkImage directly from the canvas source.
  if (CanvasKitRenderer.instance.isSoftware) {
    skImage = canvasKit.MakeImageFromCanvasImageSource(image);
  } else {
    // If GPU-accelerated CanvasKit is active, create a lazy image from the HTML Image Element,
    // which uploads the texture dynamically when painted. Specify pre-multiplied alpha and sRGB.
    skImage = canvasKit.MakeLazyImageFromTextureSourceWithInfo(
      image,
      SkPartialImageInfo(
        alphaType: canvasKit.AlphaType.Premul,
        colorType: canvasKit.ColorType.RGBA_8888,
        colorSpace: SkColorSpaceSRGB,
        width: naturalWidth.toDouble(),
        height: naturalHeight.toDouble(),
      ),
    );
  }
  if (skImage == null) {
    throw ImageCodecException('Failed to create image from Image.decode');
  }

  return EngineImage(
    CkImageDelegate(skImage),
    skImage.width().toInt(),
    skImage.height().toInt(),
    imageSource: ImageElementImageSource(image),
  );
}

class CkImageElementCodec extends HtmlImageElementCodec {
  CkImageElementCodec(super.src, {super.chunkCallback});

  @override
  ui.Image createImageFromHTMLImageElement(
    DomHTMLImageElement image,
    int naturalWidth,
    int naturalHeight,
  ) => createCkImageFromImageElement(image, naturalWidth, naturalHeight);
}

class CkImageBlobCodec extends HtmlBlobCodec {
  CkImageBlobCodec(super.blob, {super.chunkCallback});

  @override
  ui.Image createImageFromHTMLImageElement(
    DomHTMLImageElement image,
    int naturalWidth,
    int naturalHeight,
  ) => createCkImageFromImageElement(image, naturalWidth, naturalHeight);
}

/// Creates and decodes an image using HtmlImageElement.
Future<CkImageBlobCodec> decodeBlobToCkImage(DomBlob blob) async {
  final codec = CkImageBlobCodec(blob);
  await codec.decode();
  return codec;
}

Future<CkImageElementCodec> decodeUrlToCkImage(String src) async {
  final codec = CkImageElementCodec(src);
  await codec.decode();
  return codec;
}

void skiaDecodeImageFromPixels(
  Uint8List pixels,
  int width,
  int height,
  ui.PixelFormat format,
  ui.ImageDecoderCallback callback, {
  int? rowBytes,
  int? targetWidth,
  int? targetHeight,
  bool allowUpscaling = true,
}) {
  if (targetWidth != null) {
    assert(allowUpscaling || targetWidth <= width);
  }
  if (targetHeight != null) {
    assert(allowUpscaling || targetHeight <= height);
  }

  // Run in a timer to avoid janking the current frame by moving the decoding
  // work outside the frame event.
  Timer.run(() {
    final SkImage? skImage = canvasKit.MakeImage(
      SkImageInfo(
        width: width.toDouble(),
        height: height.toDouble(),
        colorType: format == ui.PixelFormat.rgba8888
            ? canvasKit.ColorType.RGBA_8888
            : canvasKit.ColorType.BGRA_8888,
        alphaType: canvasKit.AlphaType.Premul,
        colorSpace: SkColorSpaceSRGB,
      ),
      pixels,
      rowBytes ?? 4 * width,
    );

    if (skImage == null) {
      domWindow.console.warn('Failed to create image from pixels.');
      return;
    }

    if (targetWidth != null || targetHeight != null) {
      if (validUpscale(allowUpscaling, targetWidth, targetHeight, width, height)) {
        return callback(scaleImage(skImage, targetWidth, targetHeight));
      }
    }
    return callback(
      EngineImage(CkImageDelegate(skImage), skImage.width().toInt(), skImage.height().toInt()),
    );
  });
}

// An invalid upscale happens when allowUpscaling is false AND either the given
// targetWidth is larger than the originalWidth OR the targetHeight is larger than originalHeight.
bool validUpscale(
  bool allowUpscaling,
  int? targetWidth,
  int? targetHeight,
  int originalWidth,
  int originalHeight,
) {
  if (allowUpscaling) {
    return true;
  }
  final bool targetWidthFits;
  final bool targetHeightFits;
  if (targetWidth != null) {
    targetWidthFits = targetWidth <= originalWidth;
  } else {
    targetWidthFits = true;
  }

  if (targetHeight != null) {
    targetHeightFits = targetHeight <= originalHeight;
  } else {
    targetHeightFits = true;
  }
  return targetWidthFits && targetHeightFits;
}

/// Creates a scaled [CkImage] from an [SkImage] by drawing the [SkImage] to a canvas.
///
/// This function will only be called if either a targetWidth or targetHeight is not null
///
/// If only one of targetWidth or  targetHeight are specified, the other
/// dimension will be scaled according to the aspect ratio of the supplied
/// dimension.
///
/// If either targetWidth or targetHeight is less than or equal to zero, it
/// will be treated as if it is null.
EngineImage scaleImage(SkImage image, int? targetWidth, int? targetHeight) {
  final temporaryImage = EngineImage(
    CkImageDelegate(image),
    image.width().toInt(),
    image.height().toInt(),
  );
  try {
    assert(targetWidth != null || targetHeight != null);
    final int width = temporaryImage.width;
    final int height = temporaryImage.height;

    var adjustedWidth = targetWidth;
    var adjustedHeight = targetHeight;
    if (adjustedWidth != null && adjustedWidth <= 0) {
      adjustedWidth = null;
    }
    if (adjustedHeight != null && adjustedHeight <= 0) {
      adjustedHeight = null;
    }

    final int finalTargetWidth = adjustedWidth ?? (adjustedHeight! * width / height).round();
    final int finalTargetHeight = adjustedHeight ?? (adjustedWidth! * height / width).round();

    final recorder = CkPictureRecorder();
    final CkCanvas canvas = recorder.beginRecording(ui.Rect.largest);

    final paint = CkPaint();
    canvas.drawImageRect(
      temporaryImage,
      ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      ui.Rect.fromLTWH(0, 0, finalTargetWidth.toDouble(), finalTargetHeight.toDouble()),
      paint,
    );

    final CkPicture picture = recorder.endRecording();
    final ui.Image finalImage = picture.toImageSync(finalTargetWidth, finalTargetHeight);

    return finalImage as EngineImage;
  } finally {
    temporaryImage.dispose();
  }
}

const String _kNetworkImageMessage = 'Failed to load network image.';

/// Instantiates a [ui.Codec] backed by an `SkAnimatedImage` from Skia after
/// requesting from URI.
Future<ui.Codec> skiaInstantiateWebImageCodec(
  String url,
  ui_web.ImageCodecChunkCallback? chunkCallback,
) async {
  final imageElementCodec = CkImageElementCodec(url, chunkCallback: chunkCallback);
  try {
    await imageElementCodec.decode();
    return imageElementCodec;
  } on ImageCodecException {
    imageElementCodec.dispose();
    final Uint8List list = await fetchImage(url, chunkCallback);
    final ImageType imageType = tryDetectImageType(list, url);
    if (browserSupportsImageDecoder) {
      return CkBrowserImageDecoder.create(
        data: list,
        contentType: imageType.mimeType,
        debugSource: url,
      );
    } else {
      return CkAnimatedImage.decodeFromBytes(list, url);
    }
  }
}

/// Sends a request to fetch image data.
Future<Uint8List> fetchImage(String url, ui_web.ImageCodecChunkCallback? chunkCallback) async {
  try {
    final HttpFetchResponse response = await httpFetch(url);
    final int? contentLength = response.contentLength;

    if (!response.hasPayload) {
      throw ImageCodecException(
        '$_kNetworkImageMessage\n'
        'Image URL: $url\n'
        'Server response code: ${response.status}',
      );
    }

    if (chunkCallback != null && contentLength != null) {
      return await readChunked(response.payload, contentLength, chunkCallback);
    } else {
      return await response.asUint8List();
    }
  } on HttpFetchError catch (_) {
    throw ImageCodecException(
      '$_kNetworkImageMessage\n'
      'Image URL: $url\n'
      'Trying to load an image from another domain? Find answers at:\n'
      'https://docs.flutter.dev/development/platform-integration/web-images',
    );
  }
}

/// Reads the [payload] in chunks using the browser's Streams API
///
/// See: https://developer.mozilla.org/en-US/docs/Web/API/Streams_API
Future<Uint8List> readChunked(
  HttpFetchPayload payload,
  int contentLength,
  ui_web.ImageCodecChunkCallback chunkCallback,
) async {
  final result = JSUint8Array.withLength(contentLength);
  var position = 0;
  var cumulativeBytesLoaded = 0;
  await payload.read((JSUint8Array chunk) {
    cumulativeBytesLoaded += chunk.length;
    chunkCallback(cumulativeBytesLoaded, contentLength);
    result.set(chunk, position);
    position += chunk.length;
  });
  return result.toDart;
}

/// A [BackendImage] backed by an `SkImage` from Skia.
class CkImageDelegate implements BackendImage {
  CkImageDelegate(this.skImage);

  /// The underlying CanvasKit Skia image object.
  final SkImage skImage;

  /// Returns the width of the image in pixels.
  int get width => skImage.width().toInt();

  /// Returns the height of the image in pixels.
  int get height => skImage.height().toInt();

  /// Releases the native memory allocated for the Skia image.
  @override
  void dispose() {
    skImage.delete();
  }

  /// Checks if this image delegate wraps a Skia image that is an alias (clone) of another.
  @override
  bool isCloneOf(BackendImage other) {
    return other is CkImageDelegate && other.skImage.isAliasOf(skImage);
  }
}

/// Detect the image type or throw an error if image type can't be detected.
ImageType tryDetectImageType(Uint8List data, String debugSource) {
  // ImageDecoder does not detect image type automatically. It requires us to
  // tell it what the image type is.
  final ImageType? imageType = detectImageType(data);

  if (imageType == null) {
    final String fileHeader;
    if (data.isNotEmpty) {
      fileHeader = '[${bytesToHexString(data.sublist(0, math.min(10, data.length)))}]';
    } else {
      fileHeader = 'empty';
    }
    throw ImageCodecException(
      'Failed to detect image file format using the file header.\n'
      'File header was $fileHeader.\n'
      'Image source: $debugSource',
    );
  }
  return imageType;
}
