// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' show File;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'image_provider.dart';
import 'image_resolution.dart';

class ImageMouseCursorSession extends MouseCursorSession {
  /// TODO
  ImageMouseCursorSession(ImageMouseCursor cursor, int device)
      : super(cursor, device);

  @override
  ImageMouseCursor get cursor => super.cursor as ImageMouseCursor;

  @override
  Future<void> activate() async {
    const ImageConfiguration configuration = ImageConfiguration.empty;
    final MouseCursorManager manager = RendererBinding.instance!.mouseTracker.cursorManager;
    final int cursorId = await manager.createImageCursor(
      cursor.image.obtainKey(configuration),
      () => _resolveImage(cursor.image, configuration),
      cursor.offset,
    );

    if (manager.verifyCurrentCursor(device, cursor)) {
      await SystemChannels.mouseCursor.invokeMethod<int>(
        'activateImageCursor',
        <String, dynamic>{
          'device': device,
          'cursorId': cursorId,
        },
      );
    }
  }

  static Future<ParsedImage> _resolveImage(ImageProvider provider, ImageConfiguration configuration) {
    final Completer<ParsedImage> completer = Completer<ParsedImage>();
    final ImageStream stream = provider.resolve(configuration);
    // Split the declaration and assignment of `streamListener` so that it can
    // reference itself.
    late final ImageStreamListener streamListener;
    streamListener = ImageStreamListener(
      (ImageInfo info, bool synchronousCall) async {
        // Only use the first frame of the image.
        stream.removeListener(streamListener);
        late final ParsedImage image;
        try {
          final Uint8List byteArray = Uint8List.sublistView((await info.image.toByteData())!);
          image = ParsedImage(
            byteArray,
            info.image.width,
            info.image.height,
          );
        } finally {
          info.dispose();
        }
        completer.complete(image);
      },
      onError: (Object exception, StackTrace? stackTrace) {
        completer.completeError(exception, stackTrace);
      },
    );
    stream.addListener(streamListener);
    return completer.future;
  }

  @override
  void dispose() { /* Nothing */ }
}

class ImageMouseCursor extends MouseCursor {
  const ImageMouseCursor._(
    this.image,
    this.offset,
    this._keyHashCode,
  );

  ImageMouseCursor.network(
    String src, {
    ui.Offset offset = ui.Offset.zero,
    double scale = 1.0,
    Map<String, String>? headers,
    int? cacheWidth,
    int? cacheHeight,
  }) : this._(
    ResizeImage.resizeIfNeeded(cacheWidth, cacheHeight, NetworkImage(src, scale: scale, headers: headers)),
    offset,
    null,
  );

  ImageMouseCursor.file(
    File file, {
    ui.Offset offset = ui.Offset.zero,
    double scale = 1.0,
    int? cacheWidth,
    int? cacheHeight,
  }) : this._(
    ResizeImage.resizeIfNeeded(cacheWidth, cacheHeight, FileImage(file, scale: scale)),
    offset,
    null,
  );

  ImageMouseCursor.asset(
    String name, {
    ui.Offset offset = ui.Offset.zero,
    double? scale,
    AssetBundle? bundle,
    String? package,
    int? cacheWidth,
    int? cacheHeight,
  }) : this._(
    ResizeImage.resizeIfNeeded(
      cacheWidth,
      cacheHeight,
      scale != null
        ? ExactAssetImage(name, bundle: bundle, scale: scale, package: package)
        : AssetImage(name, bundle: bundle, package: package),
    ),
    offset,
    null,
  );

  ImageMouseCursor.memory(
    Uint8List bytes, {
    ui.Offset offset = ui.Offset.zero,
    double scale = 1.0,
    int? cacheWidth,
    int? cacheHeight,
  }) : this._(
    ResizeImage.resizeIfNeeded(
      cacheWidth,
      cacheHeight,
      ResizeImage.resizeIfNeeded(cacheWidth, cacheHeight, MemoryImage(bytes, scale: scale)),
    ),
    offset,
    null,
  );

  final ImageProvider image;
  final ui.Offset offset;

  @override
  String get debugDescription => '${objectRuntimeType(this, 'ImageMouseCursor')}($image)';

  @override
  @protected
  MouseCursorSession createSession(int device) => ImageMouseCursorSession(this, device);

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType)
      return false;
    return other is ImageMouseCursor
        && other.hashCode == hashCode;
  }

  @override
  int get hashCode {
    // Either the image's key can be obtained synchronously, or the image
    // constructor must assign a hash code.
    if (_keyHashCode != null) {
      return _keyHashCode!;
    }
    Object? key;
    image.obtainKey(ImageConfiguration.empty)
      .then((Object value) { key = value; });
    assert(key != null);
    return key!.hashCode;
  }
  final int? _keyHashCode;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ImageProvider>('image', image, level: DiagnosticLevel.debug));
  }
}
