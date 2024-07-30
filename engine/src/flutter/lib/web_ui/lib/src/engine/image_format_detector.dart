// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

/// Detects the image file format and returns the corresponding "Content-Type"
/// value (a.k.a. MIME type).
///
/// The returned value can be passed to `ImageDecoder` when decoding an image.
///
/// Returns null if [data] cannot be mapped to a known content type.
ImageType? detectImageType(Uint8List data) {
  if (debugImageTypeDetector != null) {
    return debugImageTypeDetector!.call(data);
  }

  formatLoop:
  for (final ImageFileSignature format in ImageFileSignature.values) {
    if (data.length < format.header.length) {
      continue;
    }

    for (int i = 0; i < format.header.length; i++) {
      final int? magicByte = format.header[i];
      if (magicByte == null) {
        // Wildcard, accepts everything.
        continue;
      }

      final int headerByte = data[i];
      if (headerByte != magicByte) {
        continue formatLoop;
      }
    }

    return format.imageType;
  }

  if (isAvif(data)) {
    return ImageType.avif;
  }

  return null;
}

/// The supported image file formats in Flutter Web.
enum ImageFileType {
  png,
  gif,
  jpeg,
  webp,
  bmp,
  avif,
}

/// The file format of the image, and whether or not it is animated.
enum ImageType {
  // TODO(harryterkelsen): If the image is animated, we use Skia to decode.
  // This is currently too conservative, assuming all GIF and WEBP images are
  // animated. We should detect if they are actually animated by reading the
  // image headers, https://github.com/flutter/flutter/issues/151911.
  png(ImageFileType.png, isAnimated: false),
  gif(ImageFileType.gif, isAnimated: true),
  jpeg(ImageFileType.jpeg, isAnimated: false),
  webp(ImageFileType.webp, isAnimated: true),
  bmp(ImageFileType.bmp, isAnimated: false),
  avif(ImageFileType.avif, isAnimated: false);

  const ImageType(this.fileType, {required this.isAnimated});

  final ImageFileType fileType;
  final bool isAnimated;

  /// The MIME type for this image (e.g 'image/jpeg').
  String get mimeType => 'image/${fileType.name}';
}

/// The signature bytes in an image file that identify the format.
enum ImageFileSignature {
  png(
    <int?>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
    ImageType.png,
  ),
  gif87a(
    <int?>[0x47, 0x49, 0x46, 0x38, 0x37, 0x61],
    ImageType.gif,
  ),
  gif89a(
    <int?>[0x47, 0x49, 0x46, 0x38, 0x39, 0x61],
    ImageType.gif,
  ),
  jpeg(
    <int?>[0xFF, 0xD8, 0xFF],
    ImageType.jpeg,
  ),
  webp(
    <int?>[
      0x52,
      0x49,
      0x46,
      0x46,
      null,
      null,
      null,
      null,
      0x57,
      0x45,
      0x42,
      0x50
    ],
    ImageType.webp,
  ),
  bmp(
    <int?>[0x42, 0x4D],
    ImageType.bmp,
  );

  const ImageFileSignature(this.header, this.imageType);

  /// First few bytes in the file that uniquely identify the image file format.
  ///
  /// Null elements are treated as wildcard values and are not checked. This is
  /// used to detect formats whose header is split up into multiple disjoint
  /// parts, such that the first part is not unique enough to identify the
  /// format. For example, without this, WebP may be confused with .ani
  /// (animated cursor), .cda, and other formats that start with "RIFF".
  final List<int?> header;

  /// The type of image that has the signature bytes in [header] in its header.
  final ImageType imageType;
}

/// Function signature of [debugImageTypeDetector], which is the same as the
/// signature of [detectImageType].
typedef DebugImageTypeDetector = ImageType? Function(Uint8List);

/// If not null, replaces the functionality of [detectImageType] with its own.
///
/// This is useful in tests, for example, to test unsupported content types.
DebugImageTypeDetector? debugImageTypeDetector;

/// A string of bytes that every AVIF image contains somewhere in its first 16
/// bytes.
///
/// This signature is necessary but not sufficient, which may lead to false
/// positives. For example, the file may be HEIC or a video. This is OK,
/// because in the worst case, the image decoder fails to decode the file.
/// This is something we must anticipate regardless of this detection logic.
/// The codec must already protect itself from downloaded files lying about
/// their contents.
///
/// The alternative would be to implement a more precise detection, which would
/// add complexity and code size. This is how Chromium does it:
///
/// https://source.chromium.org/chromium/chromium/src/+/main:third_party/blink/renderer/platform/image-decoders/avif/avif_image_decoder.cc;l=504;drc=fd8802b593110ea18a97ef044f8a40dd24a622ec
final List<int> _avifSignature = 'ftyp'.codeUnits;

/// Optimistically detects whether [data] is an AVIF image file.
bool isAvif(Uint8List data) {
  firstByteLoop:
  for (int i = 0; i < 16; i += 1) {
    for (int j = 0; j < _avifSignature.length; j += 1) {
      if (i + j >= data.length) {
        // Reached EOF without finding the signature.
        return false;
      }
      if (data[i + j] != _avifSignature[j]) {
        continue firstByteLoop;
      }
    }
    return true;
  }
  return false;
}
