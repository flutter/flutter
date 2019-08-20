// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import 'image_provider.dart' as image_provider;
import 'image_stream.dart';

/// The dart:html implementation of [image_provider.FileImage].
class FileImage extends image_provider.ImageProvider<image_provider.FileImage> implements image_provider.FileImage {
  /// Creates an object that decodes a [File] as an image.
  ///
  /// The arguments must not be null.
  const FileImage(this.file, { this.scale = 1.0 })
    : assert(file != null),
      assert(scale != null);

  @override
  final Object file;

  @override
  final double scale;

  @override
  Future<FileImage> obtainKey(image_provider.ImageConfiguration configuration) {
    return SynchronousFuture<FileImage>(this);
  }

  @override
  ImageStreamCompleter load(image_provider.FileImage key) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key),
      scale: key.scale,
      informationCollector: () {
        return <ErrorDescription>[
          ErrorDescription('Path: $file'),
        ];
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
