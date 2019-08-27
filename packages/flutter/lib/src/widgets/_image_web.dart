// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

import 'basic.dart';
import 'framework.dart';
import 'image.dart';

export 'package:flutter/painting.dart' show
  AssetImage,
  ExactAssetImage,
  FileImage,
  FilterQuality,
  ImageConfiguration,
  ImageInfo,
  ImageStream,
  ImageProvider,
  MemoryImage,
  NetworkImage;

  /// No doc.
class Image extends ImageBase {
  /// No doc.
  const Image({
    Key key,
    @required this.image,
    this.frameBuilder,
    this.loadingBuilder,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    this.width,
    this.height,
    this.color,
    this.colorBlendMode,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.centerSlice,
    this.matchTextDirection = false,
    this.gaplessPlayback = false,
    this.filterQuality = FilterQuality.low,
  }) : assert(image != null),
       assert(alignment != null),
       assert(repeat != null),
       assert(filterQuality != null),
       assert(matchTextDirection != null),
       super(key: key);

  /// No doc.
  Image.network(
    String src, {
    Key key,
    double scale = 1.0,
    this.frameBuilder,
    this.loadingBuilder,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    this.width,
    this.height,
    this.color,
    this.colorBlendMode,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.centerSlice,
    this.matchTextDirection = false,
    this.gaplessPlayback = false,
    this.filterQuality = FilterQuality.low,
    Map<String, String> headers,
  }) : image = NetworkImage(src, scale: scale, headers: headers),
       assert(alignment != null),
       assert(repeat != null),
       assert(matchTextDirection != null),
       super(key: key);

  /// No doc.
  Image.file(
    Object file, { // ignore: avoid_unused_constructor_parameters
    Key key, // ignore: avoid_unused_constructor_parameters
    double scale = 1.0, // ignore: avoid_unused_constructor_parameters
    this.frameBuilder,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    this.width,
    this.height,
    this.color,
    this.colorBlendMode,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.centerSlice,
    this.matchTextDirection = false,
    this.gaplessPlayback = false,
    this.filterQuality = FilterQuality.low,
  }) : loadingBuilder = null,
       image = null {
    throw UnsupportedError('Image.file is not supported on the web. Try using Use Image.memory instead.');
  }

  /// No doc.
  Image.asset(
    String name, {
    Key key,
    AssetBundle bundle,
    this.frameBuilder,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    double scale,
    this.width,
    this.height,
    this.color,
    this.colorBlendMode,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.centerSlice,
    this.matchTextDirection = false,
    this.gaplessPlayback = false,
    String package,
    this.filterQuality = FilterQuality.low,
  }) : image = scale != null
         ? ExactAssetImage(name, bundle: bundle, scale: scale, package: package)
         : AssetImage(name, bundle: bundle, package: package),
       loadingBuilder = null,
       assert(alignment != null),
       assert(repeat != null),
       assert(matchTextDirection != null),
       super(key: key);

  /// No doc.
  Image.memory(
    Uint8List bytes, {
    Key key,
    double scale = 1.0,
    this.frameBuilder,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    this.width,
    this.height,
    this.color,
    this.colorBlendMode,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.centerSlice,
    this.matchTextDirection = false,
    this.gaplessPlayback = false,
    this.filterQuality = FilterQuality.low,
  }) : image = MemoryImage(bytes, scale: scale),
       loadingBuilder = null,
       assert(alignment != null),
       assert(repeat != null),
       assert(matchTextDirection != null),
       super(key: key);

    @override
    final ImageProvider image;

    @override
    final ImageFrameBuilder frameBuilder;

    @override
    final String semanticLabel;

    @override
    final bool excludeFromSemantics;

    @override
    final double width;

    @override
    final double height;

    @override
    final Color color;

    @override
    final BlendMode colorBlendMode;

    @override
    final BoxFit fit;

    @override
    final AlignmentGeometry alignment;

    @override
    final ImageRepeat repeat;

    @override
    final Rect centerSlice;

    @override
    final bool matchTextDirection;

    @override
    final bool gaplessPlayback;

    @override
    final FilterQuality filterQuality;

    @override
    final ImageLoadingBuilder loadingBuilder;
}
