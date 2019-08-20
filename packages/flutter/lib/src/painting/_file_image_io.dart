// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import 'binding.dart';
import 'image_provider.dart' as image_provider;
import 'image_stream.dart';

/// The dart:io implementation of [image_provider.FileImage].
class FileImage extends image_provider.ImageProvider<image_provider.FileImage> implements image_provider.FileImage {
  /// Creates an object that decodes a [File] as an image.
  ///
  /// [file] must be an instance of the `dart:io` [File] type.
  ///
  /// The arguments must not be null.
  const FileImage(this.file, { this.scale = 1.0 })
    : assert(file != null),
      assert(file is File),
      assert(scale != null);

  @override
  final Object file;
  File get _file => file;

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
      informationCollector: ()  {
        return <ErrorDescription>[ErrorDescription('Path: ${_file?.path}')];
      },
    );
  }

  Future<ui.Codec> _loadAsync(FileImage key) async {
    assert(key == this);

    final Uint8List bytes = await _file.readAsBytes();
    if (bytes.lengthInBytes == 0)
      return null;

    return await PaintingBinding.instance.instantiateImageCodec(bytes);
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType)
      return false;
    final FileImage typedOther = other;
    return _file?.path == typedOther._file?.path
        && scale == typedOther.scale;
  }

  @override
  int get hashCode => ui.hashValues(_file?.path, scale);

  @override
  String toString() => '$runtimeType("${_file?.path}", scale: $scale)';
}
