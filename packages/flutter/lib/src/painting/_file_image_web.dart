// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import 'image_provider.dart' as image_provider;
import 'image_stream.dart';

/// Decodes the given [File] object as an image, associating it with the given
/// scale.
///
/// This class is not supported when build Flutter for web applications.
///
/// See also:
///
///  * [Image.file] for a shorthand of an [Image] widget backed by [FileImage].
class FileImage extends image_provider.ImageProvider<FileImage> {
  /// Creates an object that decodes a [File] as an image.
  ///
  /// The arguments must not be null.
  const FileImage(this.file, { this.scale = 1.0 })
    : assert(file != null),
      assert(scale != null);

  /// The file to decode into an image.
  final Object file;

  /// The scale to place in the [ImageInfo] object of the image.
  final double scale;

  @override
  Future<FileImage> obtainKey(image_provider.ImageConfiguration configuration) {
    return SynchronousFuture<FileImage>(this);
  }

  @override
  ImageStreamCompleter load(FileImage key) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key),
      scale: key.scale,
      informationCollector: ()  {
        return <ErrorDescription>[ErrorDescription('Path: $file')];
      },
    );
  }

  Future<ui.Codec> _loadAsync(FileImage key) async {
    assert(key == this);
    throw UnsupportedError('FileImage is not supported on the web.');
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType)
      return false;
    final FileImage typedOther = other;
    return file == typedOther.file
       && scale == typedOther.scale;
  }

  @override
  int get hashCode => ui.hashValues(file, scale);

  @override
  String toString() => '$runtimeType("$file", scale: $scale)';
}
