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

typedef _ImageListener = void Function(ImageInfo? image);

// Loads the first frame of the given image and dispatch to the added listeners.
//
// All later frames of a multi-frame image are discarded, because few platforms
// support animating mouse cursors.
class _SingleImagePromise {
  // Creates a _SingleImagePromise and starts loading an image.
  _SingleImagePromise(ImageProvider provider)
      : _provider = provider,
        _stream = provider.resolve(ImageConfiguration.empty),
        _listeners = <_ImageListener>[],
        _error = false {
    _streamListener = ImageStreamListener(
      _handleImage,
      onError: _handleError,
    );
    _stream.addListener(_streamListener);
  }

  // Add a listener that will be called once with the result.
  //
  // If the result is ready, the listener will be called immediately.
  // Otherwise, it will be called when it's ready.
  //
  // A listener will be and only be called once. If an error occured during
  // loading, the result will be null. Otherwise, the result is never null.
  void addListener(_ImageListener listener) {
    if (_error) {
      listener(null);
    } else if (_info != null) {
      listener(_info);
    } else {
      _listeners.add(listener);
    }
  }

  void dispose() {
    _stream.removeListener(_streamListener);
    _info?.dispose();
  }

  void _handleImage(ImageInfo image, bool synchronousCall) {
    _stream.removeListener(_streamListener);
    assert(!_error);
    _info = image;
    _listeners
      ..forEach((_ImageListener listener) { listener(_info); })
      ..clear();
  }

  void _handleError(Object exception, StackTrace? stack) {
    _stream.removeListener(_streamListener);
    assert(_info == null);
    _error = true;
    InformationCollector? collector;
    assert(() {
      collector = () sync* {
        yield DiagnosticsProperty<ImageProvider>('image', _provider);
      };
      return true;
    }());
    FlutterError.reportError(FlutterErrorDetails(
      exception: exception,
      stack: stack,
      context: ErrorDescription('while loading an image mouse cursor'),
      informationCollector: collector,
    ));
    _listeners
      ..forEach((_ImageListener listener) { listener(null); })
      ..clear();
  }

  final ImageProvider _provider;
  final ImageStream _stream;
  late final ImageStreamListener _streamListener;
  ImageInfo? _info;
  bool _error;
  final List<_ImageListener> _listeners;
}

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
        'setImageCursor',
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
